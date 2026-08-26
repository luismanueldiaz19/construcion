<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LedhouseEstadoResultado;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use PhpOffice\PhpSpreadsheet\IOFactory;

class LedhouseEstadoResultadoController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $query = LedhouseEstadoResultado::query();

        // Filtro por fecha (rango)
        if ($request->has('start_date') && $request->has('end_date')) {
            $query->whereBetween('fecha', [$request->start_date, $request->end_date]);
        } elseif ($request->has('start_date')) {
            $query->where('fecha', '>=', $request->start_date);
        } elseif ($request->has('end_date')) {
            $query->where('fecha', '<=', $request->end_date);
        }

        // Filtro por modulo
        if ($request->has('modulo')) {
            $query->where('modulo', $request->modulo);
        }

        // Filtro por codigo de cuenta (LIKE)
        if ($request->has('codigo_cuenta')) {
            $query->where('codigo_cuenta', 'like', '%' . $request->codigo_cuenta . '%');
        }

        $query->orderBy('fecha', 'desc');

        // Paginación o todos
        if ($request->has('per_page')) {
            return response()->json($query->paginate($request->per_page));
        }

        return response()->json(['data' => $query->get()]);
    }

    /**
     * Get summary data for charts.
     */
    public function summary(Request $request)
    {
        $query = LedhouseEstadoResultado::query();

        // Aplicar los mismos filtros base si existen
        if ($request->has('start_date') && $request->has('end_date')) {
            $query->whereBetween('fecha', [$request->start_date, $request->end_date]);
        } elseif ($request->has('start_date')) {
            $query->where('fecha', '>=', $request->start_date);
        } elseif ($request->has('end_date')) {
            $query->where('fecha', '<=', $request->end_date);
        }

        // Para el gráfico de pastel: Agrupar por modulo y sumar monto
        $pieChartQuery = clone $query;
        $pieChartData = $pieChartQuery->select('modulo', DB::raw('SUM(monto) as total'))
            ->groupBy('modulo')
            ->get();

        // Para el gráfico de barras/líneas: Agrupar por mes/año y módulo para sumar monto por pilar
        $barChartQuery = clone $query;
        $barChartData = $barChartQuery->select(
            DB::raw("TO_CHAR(fecha, 'YYYY-MM') as mes"),
            'modulo',
            DB::raw('SUM(monto) as total')
        )
        ->groupBy('mes', 'modulo')
        ->orderBy('mes', 'asc')
        ->get();

        return response()->json([
            'pie_chart' => $pieChartData,
            'bar_chart' => $barChartData,
            'total' => $query->sum('monto')
        ]);
    }

    /**
     * Generate PDF for the Matrix view.
     */
    public function generateMatrizPdf(Request $request)
    {
        $year = $request->query('year', date('Y'));

        // Obtener todos los registros del año solicitado
        $registros = LedhouseEstadoResultado::whereYear('fecha', $year)->get();
        $matrizBruta = [];

        foreach ($registros as $reg) {
            $modulo = strtoupper($reg->modulo);
            $codigo = $reg->codigo_cuenta;
            $mes = (int) date('n', strtotime($reg->fecha));

            if (!isset($matrizBruta[$modulo])) {
                $matrizBruta[$modulo] = [
                    'cuentas' => [],
                    'subtotales' => array_fill(1, 12, 0),
                    'total_anual_modulo' => 0
                ];
            }

            if (!isset($matrizBruta[$modulo]['cuentas'][$codigo])) {
                $matrizBruta[$modulo]['cuentas'][$codigo] = [
                    'descripcion' => $reg->descripcion_de_cuenta,
                    'meses' => array_fill(1, 12, 0),
                    'total_anual' => 0
                ];
            }

            $matrizBruta[$modulo]['cuentas'][$codigo]['meses'][$mes] += $reg->monto;
            $matrizBruta[$modulo]['cuentas'][$codigo]['total_anual'] += $reg->monto;
            $matrizBruta[$modulo]['subtotales'][$mes] += $reg->monto;
            $matrizBruta[$modulo]['total_anual_modulo'] += $reg->monto;
        }

        $resultado = [];
        $maximos = []; // Para el heatmap

        foreach (['VENTAS', 'COSTOS', 'GASTOS'] as $modOpcional) {
            if (isset($matrizBruta[$modOpcional])) {
                $cuentasList = [];
                $maxModulo = 0;
                
                foreach ($matrizBruta[$modOpcional]['cuentas'] as $cod => $data) {
                    $cuentasList[] = [
                        'codigo' => $cod,
                        'descripcion' => $data['descripcion'],
                        'meses' => $data['meses'],
                        'total_anual' => $data['total_anual']
                    ];

                    foreach ($data['meses'] as $m => $monto) {
                        if (abs($monto) > $maxModulo) {
                            $maxModulo = abs($monto);
                        }
                    }
                }
                
                usort($cuentasList, function($a, $b) {
                    return strcmp($a['codigo'], $b['codigo']);
                });

                $resultado[$modOpcional] = [
                    'cuentas' => $cuentasList,
                    'subtotales' => $matrizBruta[$modOpcional]['subtotales'],
                    'total_anual_modulo' => $matrizBruta[$modOpcional]['total_anual_modulo']
                ];
                $maximos[$modOpcional] = $maxModulo;
            }
        }

        $mesesVisibles = 12;
        if ((int)$year === (int)date('Y')) {
            $maxMonth = 1;
            foreach ($resultado as $modData) {
                foreach ($modData['cuentas'] as $cuenta) {
                    foreach ($cuenta['meses'] as $m => $monto) {
                        if ($monto != 0 && $m > $maxMonth) {
                            $maxMonth = $m;
                        }
                    }
                }
            }
            $mesesVisibles = $maxMonth;
        }

        $pdf = \Barryvdh\DomPDF\Facade\Pdf::loadView('reports.ledhouse_matriz', [
            'matriz' => $resultado,
            'maximos' => $maximos,
            'year' => $year,
            'mesesVisibles' => $mesesVisibles
        ])->setPaper('a4', 'landscape');

        return $pdf->stream('Matriz_Cuentas_LEDHOUSE_'.$year.'.pdf');
    }

    /**
     * Generate PDF report.
     */
    public function generatePdf(Request $request)
    {
        $query = LedhouseEstadoResultado::query();

        // Filtro por fecha (rango)
        if ($request->has('start_date') && $request->has('end_date')) {
            $query->whereBetween('fecha', [$request->start_date, $request->end_date]);
        } elseif ($request->has('start_date')) {
            $query->where('fecha', '>=', $request->start_date);
        } elseif ($request->has('end_date')) {
            $query->where('fecha', '<=', $request->end_date);
        }

        // Filtro por modulo
        if ($request->has('modulo') && $request->modulo !== 'TODOS') {
            $query->where('modulo', $request->modulo);
        }

        // Filtro por codigo de cuenta (LIKE)
        if ($request->has('codigo_cuenta')) {
            $query->where('codigo_cuenta', 'like', '%' . $request->codigo_cuenta . '%');
        }

        // Filtro exacto de IDs (enviado desde la tabla filtrada de Flutter)
        if ($request->has('ids')) {
            $ids = explode(',', $request->ids);
            // Filtramos solo los IDs válidos
            $ids = array_filter($ids, 'is_numeric');
            if (count($ids) > 0) {
                $query->whereIn('id', $ids);
            }
        }

        $registros = $query->orderBy('fecha', 'desc')->get();
        
        $ventas = $registros->where('modulo', 'VENTAS')->sum('monto');
        $costos = $registros->where('modulo', 'COSTOS')->sum('monto');
        $gastos = $registros->where('modulo', 'GASTOS')->sum('monto');
        $utilidad = $ventas - $costos - $gastos;

        $pdf = \Barryvdh\DomPDF\Facade\Pdf::loadView('reports.ledhouse_estado_resultado', compact(
            'registros', 'ventas', 'costos', 'gastos', 'utilidad', 'request'
        ));

        return $pdf->stream("Estado_Resultado_LEDHOUSE.pdf");
    }

    /**
     * Genera la matriz (pivote) anual para el reporte gerencial.
     */
    public function matriz(Request $request)
    {
        $year = $request->query('year', date('Y'));

        // Obtener todos los registros del año solicitado
        $registros = LedhouseEstadoResultado::whereYear('fecha', $year)->get();

        $matriz = [];

        foreach ($registros as $reg) {
            $modulo = strtoupper($reg->modulo); // ej. VENTAS
            $codigo = $reg->codigo_cuenta;
            $mes = (int) date('n', strtotime($reg->fecha)); // 1 a 12

            if (!isset($matriz[$modulo])) {
                $matriz[$modulo] = [
                    'cuentas' => [],
                    'subtotales' => array_fill(1, 12, 0),
                    'total_anual_modulo' => 0
                ];
            }

            if (!isset($matriz[$modulo]['cuentas'][$codigo])) {
                $matriz[$modulo]['cuentas'][$codigo] = [
                    'descripcion' => $reg->descripcion_de_cuenta,
                    'meses' => array_fill(1, 12, 0),
                    'total_anual' => 0
                ];
            }

            // Sumar montos
            $matriz[$modulo]['cuentas'][$codigo]['meses'][$mes] += $reg->monto;
            $matriz[$modulo]['cuentas'][$codigo]['total_anual'] += $reg->monto;

            // Subtotales del módulo
            $matriz[$modulo]['subtotales'][$mes] += $reg->monto;
            $matriz[$modulo]['total_anual_modulo'] += $reg->monto;
        }

        // Convertir las cuentas asociativas a arreglos secuenciales para que flutter las itere más fácil si quiere
        // o dejarlo como objeto. Mejor dejamos 'cuentas' como un objeto map para que sea más fácil de leer, o un array de objetos.
        $resultado = [];
        foreach (['VENTAS', 'COSTOS', 'GASTOS'] as $modOpcional) {
            if (isset($matriz[$modOpcional])) {
                $cuentasList = [];
                foreach ($matriz[$modOpcional]['cuentas'] as $cod => $data) {
                    $cuentasList[] = [
                        'codigo' => $cod,
                        'descripcion' => $data['descripcion'],
                        'meses' => $data['meses'],
                        'total_anual' => $data['total_anual']
                    ];
                }
                
                // Ordenar cuentas por código
                usort($cuentasList, function($a, $b) {
                    return strcmp($a['codigo'], $b['codigo']);
                });

                $resultado[$modOpcional] = [
                    'cuentas' => $cuentasList,
                    'subtotales' => $matriz[$modOpcional]['subtotales'],
                    'total_anual_modulo' => $matriz[$modOpcional]['total_anual_modulo']
                ];
            }
        }

        return response()->json([
            'year' => $year,
            'matriz' => $resultado
        ]);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'codigo_cuenta' => 'required|string',
            'modulo' => 'required|string',
            'descripcion_de_cuenta' => 'required|string',
            'monto' => 'required|numeric',
            'fecha' => 'required|date',
            'registed_by' => 'nullable|string',
        ]);

        $item = LedhouseEstadoResultado::create($validated);

        return response()->json($item, 201);
    }

    /**
     * Import records from an Excel file.
     */
    public function import(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:xlsx,xls,csv|max:10240', // max 10MB
        ]);

        $file = $request->file('file');
        
        try {
            $spreadsheet = IOFactory::load($file->getPathname());
            $worksheet = $spreadsheet->getActiveSheet();
            $rows = $worksheet->toArray();
            
            if (count($rows) <= 1) {
                return response()->json(['error' => 'El archivo está vacío o solo contiene encabezados.'], 400);
            }

            $importedCount = 0;
            $errors = [];

            DB::beginTransaction();

            // Asumimos estructura: [0] Código, [1] Módulo, [2] Descripción, [3] Monto, [4] Fecha
            foreach ($rows as $index => $row) {
                if ($index === 0) continue; // Saltar encabezado

                // Si la fila está vacía, saltarla
                if (empty(array_filter($row))) continue;

                $codigo = trim((string)($row[0] ?? ''));
                $modulo = trim((string)($row[1] ?? ''));
                $descripcion = trim((string)($row[2] ?? ''));
                $montoRaw = trim((string)($row[3] ?? '0'));
                // Limpiar formato de contabilidad (ej. "( 138,364.40 )" -> "-138364.40") y separadores de miles
                $montoStr = str_replace([',', ' '], '', $montoRaw);
                if (preg_match('/^\((.+)\)$/', $montoStr, $matches)) {
                    $montoStr = '-' . $matches[1];
                }
                $monto = $montoStr;
                
                // Formatear la fecha
                $fechaRaw = $row[4] ?? '';
                $fecha = null;
                
                // Intentar parsear fecha Excel o texto
                if (is_numeric($fechaRaw)) {
                    $fecha = \PhpOffice\PhpSpreadsheet\Shared\Date::excelToDateTimeObject($fechaRaw)->format('Y-m-d');
                } else {
                    $fecha = date('Y-m-d', strtotime(str_replace('/', '-', $fechaRaw)));
                }

                // Validaciones mínimas
                if (!$codigo || !$modulo || !$descripcion || !is_numeric($monto) || !$fecha) {
                    $errors[] = "Fila " . ($index + 1) . ": Datos incompletos o inválidos.";
                    continue;
                }

                LedhouseEstadoResultado::create([
                    'codigo_cuenta' => $codigo,
                    'modulo' => strtoupper($modulo),
                    'descripcion_de_cuenta' => $descripcion,
                    'monto' => floatval($monto),
                    'fecha' => $fecha,
                    'registed_by' => $request->user() ? $request->user()->name : 'Import',
                ]);

                $importedCount++;
            }

            if (count($errors) > 0 && $importedCount === 0) {
                DB::rollBack();
                $errorDetails = implode(' | ', array_slice($errors, 0, 3));
                if (count($errors) > 3) $errorDetails .= '...';
                
                return response()->json([
                    'error' => 'No se pudo importar ningún registro. Detalles: ' . $errorDetails,
                    'details' => $errors
                ], 422);
            }

            DB::commit();

            return response()->json([
                'message' => "Se importaron $importedCount registros exitosamente.",
                'errors' => $errors
            ], 200);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['error' => 'Error al procesar el archivo: ' . $e->getMessage()], 500);
        }
    }

    /**
     * Actualiza un registro existente.
     */
    public function update(Request $request, $id)
    {
        $request->validate([
            'codigo_cuenta' => 'required|string',
            'modulo' => 'required|string',
            'descripcion_de_cuenta' => 'required|string',
            'monto' => 'required|numeric',
            'fecha' => 'required|date',
        ]);

        $registro = LedhouseEstadoResultado::findOrFail($id);
        $registro->update([
            'codigo_cuenta' => $request->codigo_cuenta,
            'modulo' => strtoupper($request->modulo),
            'descripcion_de_cuenta' => $request->descripcion_de_cuenta,
            'monto' => $request->monto,
            'fecha' => $request->fecha,
        ]);

        return response()->json($registro);
    }

    /**
     * Elimina un registro.
     */
    public function destroy($id)
    {
        $registro = LedhouseEstadoResultado::findOrFail($id);
        $registro->delete();

        return response()->json(['message' => 'Registro eliminado exitosamente.']);
    }
}
