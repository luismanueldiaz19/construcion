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
        $query = LedhouseEstadoResultado::join('cuenta_catalogo_ledhouse', 'ledhouse_estado_resultado.codigo_cuenta', '=', 'cuenta_catalogo_ledhouse.codigo')
            ->select('ledhouse_estado_resultado.*', 'cuenta_catalogo_ledhouse.origen as modulo', 'cuenta_catalogo_ledhouse.descripcion as descripcion_de_cuenta');

        // Filtro por fecha (rango)
        if ($request->has('start_date') && $request->has('end_date')) {
            $query->whereBetween('ledhouse_estado_resultado.fecha', [$request->start_date, $request->end_date]);
        } elseif ($request->has('start_date')) {
            $query->where('ledhouse_estado_resultado.fecha', '>=', $request->start_date);
        } elseif ($request->has('end_date')) {
            $query->where('ledhouse_estado_resultado.fecha', '<=', $request->end_date);
        }

        // Filtro por modulo
        if ($request->has('modulo')) {
            $query->where('cuenta_catalogo_ledhouse.origen', $request->modulo);
        }

        // Filtro por codigo de cuenta (LIKE)
        if ($request->has('codigo_cuenta')) {
            $query->where('ledhouse_estado_resultado.codigo_cuenta', 'like', '%' . $request->codigo_cuenta . '%');
        }

        $query->orderBy('ledhouse_estado_resultado.fecha', 'desc');

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
        $query = LedhouseEstadoResultado::join('cuenta_catalogo_ledhouse', 'ledhouse_estado_resultado.codigo_cuenta', '=', 'cuenta_catalogo_ledhouse.codigo');

        // Aplicar los mismos filtros base si existen
        if ($request->has('start_date') && $request->has('end_date')) {
            $query->whereBetween('ledhouse_estado_resultado.fecha', [$request->start_date, $request->end_date]);
        } elseif ($request->has('start_date')) {
            $query->where('ledhouse_estado_resultado.fecha', '>=', $request->start_date);
        } elseif ($request->has('end_date')) {
            $query->where('ledhouse_estado_resultado.fecha', '<=', $request->end_date);
        }

        // Para el gráfico de pastel: Agrupar por modulo y sumar monto
        $pieChartQuery = clone $query;
        $pieChartData = $pieChartQuery->select('cuenta_catalogo_ledhouse.origen as modulo', DB::raw('SUM(ledhouse_estado_resultado.monto) as total'))
            ->groupBy('cuenta_catalogo_ledhouse.origen')
            ->get();

        // Para el gráfico de barras/líneas: Agrupar por mes/año y módulo para sumar monto por pilar
        $barChartQuery = clone $query;
        $barChartData = $barChartQuery->select(
            DB::raw("TO_CHAR(ledhouse_estado_resultado.fecha, 'YYYY-MM') as mes"),
            'cuenta_catalogo_ledhouse.origen as modulo',
            DB::raw('SUM(ledhouse_estado_resultado.monto) as total')
        )
        ->groupBy('mes', 'cuenta_catalogo_ledhouse.origen')
        ->orderBy('mes', 'asc')
        ->get();

        return response()->json([
            'pie_chart' => $pieChartData,
            'bar_chart' => $barChartData,
            'total' => $query->sum('ledhouse_estado_resultado.monto')
        ]);
    }

    /**
     * Generate PDF for the Matrix view.
     */
    public function generateMatrizPdf(Request $request)
    {
        $year = $request->query('year', date('Y'));

        $query = LedhouseEstadoResultado::join('cuenta_catalogo_ledhouse', 'ledhouse_estado_resultado.codigo_cuenta', '=', 'cuenta_catalogo_ledhouse.codigo')
            ->select('ledhouse_estado_resultado.*', 'cuenta_catalogo_ledhouse.origen as modulo', 'cuenta_catalogo_ledhouse.descripcion as descripcion_de_cuenta')
            ->whereYear('ledhouse_estado_resultado.fecha', $year);

        if ($request->has('modulo') && $request->modulo != 'TODOS') {
            $query->where('cuenta_catalogo_ledhouse.origen', $request->modulo);
        }

        $mesesFiltrados = [];
        if ($request->has('meses') && !empty($request->meses)) {
            $mesesArr = explode(',', $request->meses);
            $mesesArr = array_filter($mesesArr, 'is_numeric');
            if (count($mesesArr) > 0) {
                $mesesFiltrados = $mesesArr;
                sort($mesesFiltrados);
            }
        }

        $registros = $query->get();
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
            'mesesVisibles' => $mesesVisibles,
            'mesesFiltrados' => $mesesFiltrados
        ])->setPaper('a4', 'landscape');

        return $pdf->stream('Matriz_Cuentas_LEDHOUSE_'.$year.'.pdf');
    }

    /**
     * Generate PDF report.
     */
    public function generatePdf(Request $request)
    {
        $query = LedhouseEstadoResultado::join('cuenta_catalogo_ledhouse', 'ledhouse_estado_resultado.codigo_cuenta', '=', 'cuenta_catalogo_ledhouse.codigo')
            ->select('ledhouse_estado_resultado.*', 'cuenta_catalogo_ledhouse.origen as modulo', 'cuenta_catalogo_ledhouse.descripcion as descripcion_de_cuenta');

        // Filtro por fecha (rango)
        if ($request->has('start_date') && $request->has('end_date')) {
            $query->whereBetween('ledhouse_estado_resultado.fecha', [$request->start_date, $request->end_date]);
        } elseif ($request->has('start_date')) {
            $query->where('ledhouse_estado_resultado.fecha', '>=', $request->start_date);
        } elseif ($request->has('end_date')) {
            $query->where('ledhouse_estado_resultado.fecha', '<=', $request->end_date);
        }

        // Filtro por modulo
        if ($request->has('modulo') && $request->modulo !== 'TODOS') {
            $query->where('cuenta_catalogo_ledhouse.origen', $request->modulo);
        }

        // Filtro por codigo de cuenta (LIKE)
        if ($request->has('codigo_cuenta')) {
            $query->where('ledhouse_estado_resultado.codigo_cuenta', 'like', '%' . $request->codigo_cuenta . '%');
        }

        // Filtro exacto de IDs (enviado desde la tabla filtrada de Flutter)
        if ($request->has('ids')) {
            $ids = explode(',', $request->ids);
            // Filtramos solo los IDs válidos
            $ids = array_filter($ids, 'is_numeric');
            if (count($ids) > 0) {
                $query->whereIn('ledhouse_estado_resultado.id', $ids);
            }
        }

        $query->orderByRaw("CASE WHEN UPPER(cuenta_catalogo_ledhouse.origen) = 'VENTAS' THEN 1 WHEN UPPER(cuenta_catalogo_ledhouse.origen) = 'COSTOS' THEN 2 WHEN UPPER(cuenta_catalogo_ledhouse.origen) = 'GASTOS' THEN 3 ELSE 4 END")
              ->orderBy('ledhouse_estado_resultado.fecha', 'desc');

        $registros = $query->get();
        
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
        $registros = LedhouseEstadoResultado::join('cuenta_catalogo_ledhouse', 'ledhouse_estado_resultado.codigo_cuenta', '=', 'cuenta_catalogo_ledhouse.codigo')
            ->select('ledhouse_estado_resultado.*', 'cuenta_catalogo_ledhouse.origen as modulo', 'cuenta_catalogo_ledhouse.descripcion as descripcion_de_cuenta')
            ->whereYear('ledhouse_estado_resultado.fecha', $year)
            ->get();

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
            'monto' => 'required|numeric',
            'fecha' => 'required|date',
            'registed_by' => 'nullable|string',
        ]);

        $item = LedhouseEstadoResultado::create($validated);

        $itemWithJoin = LedhouseEstadoResultado::join('cuenta_catalogo_ledhouse', 'ledhouse_estado_resultado.codigo_cuenta', '=', 'cuenta_catalogo_ledhouse.codigo')
            ->select('ledhouse_estado_resultado.*', 'cuenta_catalogo_ledhouse.origen as modulo', 'cuenta_catalogo_ledhouse.descripcion as descripcion_de_cuenta')
            ->where('ledhouse_estado_resultado.id', $item->id)
            ->first();

        return response()->json($itemWithJoin, 201);
    }

    /**
     * Import records from an Excel file.
     */
    public function import(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:xlsx,xls,csv|max:10240', // max 10MB
            'fecha' => 'required|date',
        ]);

        $file = $request->file('file');
        $fecha = $request->fecha;
        
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

            // Asumimos estructura: [0] Código, [1] Monto
            foreach ($rows as $index => $row) {
                if ($index === 0) continue; // Saltar encabezado

                if (empty(array_filter($row))) continue;

                $codigo = trim((string)($row[0] ?? ''));
                $montoRaw = trim((string)($row[1] ?? '0'));
                
                $montoStr = str_replace([',', ' '], '', $montoRaw);
                if (preg_match('/^\((.+)\)$/', $montoStr, $matches)) {
                    $montoStr = '-' . $matches[1];
                }
                $monto = $montoStr;

                if (!$codigo || !is_numeric($monto)) {
                    $errors[] = "Fila " . ($index + 1) . ": Datos incompletos o inválidos.";
                    continue;
                }

                // Relacionar con el catálogo
                $cuentaCatalogo = \App\Models\CuentaCatalogoLedhouse::where('codigo', $codigo)->first();
                if (!$cuentaCatalogo) {
                    $errors[] = "Fila " . ($index + 1) . ": El código $codigo no existe en el catálogo.";
                    continue; // Skip or save with default? User wants relation, so it must exist.
                }

                LedhouseEstadoResultado::create([
                    'codigo_cuenta' => $codigo,
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
            'monto' => 'required|numeric',
            'fecha' => 'required|date',
        ]);

        $registro = LedhouseEstadoResultado::findOrFail($id);
        $registro->update([
            'codigo_cuenta' => $request->codigo_cuenta,
            'monto' => $request->monto,
            'fecha' => $request->fecha,
        ]);

        $itemWithJoin = LedhouseEstadoResultado::join('cuenta_catalogo_ledhouse', 'ledhouse_estado_resultado.codigo_cuenta', '=', 'cuenta_catalogo_ledhouse.codigo')
            ->select('ledhouse_estado_resultado.*', 'cuenta_catalogo_ledhouse.origen as modulo', 'cuenta_catalogo_ledhouse.descripcion as descripcion_de_cuenta')
            ->where('ledhouse_estado_resultado.id', $registro->id)
            ->first();

        return response()->json($itemWithJoin);
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
