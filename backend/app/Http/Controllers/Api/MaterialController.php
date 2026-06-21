<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Material;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class MaterialController extends Controller
{
    public function index()
    {
        return Material::with('categoria')->orderBy('nombre')->get();
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'codigo' => 'required|string|unique:materiales',
            'nombre' => 'required|string',
            'descripcion' => 'nullable|string',
            'categoria_id' => 'nullable|exists:categorias,id',
            'unidad' => 'required|string',
            'precio_costo' => 'numeric',
        ]);
        return Material::create($validated);
    }

    public function update(Request $request, $id) {
        $material = Material::findOrFail($id);
        $validated = $request->validate([
            'codigo' => 'required|string|unique:materiales,codigo,' . $material->id,
            'nombre' => 'required|string',
            'descripcion' => 'nullable|string',
            'categoria_id' => 'nullable|exists:categorias,id',
            'unidad' => 'required|string',
            'precio_costo' => 'numeric',
        ]);
        
        $material->update($validated);
        return $material;
    }

    public function toggleEstado($id)
    {
        $material = Material::findOrFail($id);
        $material->estado = !$material->estado;
        $material->save();
        return response()->json([
            'message' => 'Estado actualizado',
            'nuevo_estado' => $material->estado
        ]);
    }

    public function inventarioPorProyecto()
    {
        return \App\Models\Proyecto::with(['compraDetalles.material'])
            ->get()
            ->map(function ($proyecto) {
                $materiales = $proyecto->compraDetalles->groupBy('material_id')->map(function ($items) {
                    $first = $items->first();
                    if (!$first || !$first->material) return null;
                    return [
                        'material' => $first->material->nombre,
                        'unidad' => $first->material->unidad,
                        'cantidad_total' => $items->sum('cantidad'),
                        'inversion_total' => $items->sum('subtotal'),
                    ];
                })->filter()->values();

                return [
                    'id' => $proyecto->id,
                    'nombre' => $proyecto->nombre,
                    'materiales' => $materiales
                ];
            });
    }

    public function importTemplate()
    {
        $headers = ['Codigo', 'Nombre', 'Descripcion', 'Categoria', 'Unidad', 'Precio Costo'];
        $samples = [
            ['SKU-001', 'Pintura Acrilica Roja', 'Galon de pintura roja base agua', 'Pinturas', 'GL', '1250.00'],
            ['SKU-002', 'Tubo PVC 1/2', 'Tubo para plomeria de 1/2 pulgada', 'Tuberias', 'UND', '380.00']
        ];
        
        $callback = function() use ($headers, $samples) {
            $file = fopen('php://output', 'w');
            // Agregar UTF-8 BOM
            fprintf($file, chr(0xEF).chr(0xBB).chr(0xBF));
            fputcsv($file, $headers);
            foreach ($samples as $row) {
                fputcsv($file, $row);
            }
            fclose($file);
        };
        
        return response()->stream($callback, 200, [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Content-Disposition' => 'attachment; filename="plantilla_productos.csv"',
        ]);
    }

    public function import(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:xlsx,xls,csv,txt|max:5120',
        ]);

        try {
            $file = $request->file('file');
            
            // Cargar archivo usando PhpSpreadsheet
            $spreadsheet = \PhpOffice\PhpSpreadsheet\IOFactory::load($file->getRealPath());
            $worksheet = $spreadsheet->getActiveSheet();
            $rows = $worksheet->toArray();
            
            if (count($rows) <= 1) {
                return response()->json([
                    'success' => false,
                    'message' => 'El archivo está vacío o solo contiene la cabecera.',
                    'errors' => []
                ], 422);
            }
            
            // Limitar a 1000 productos
            if (count($rows) > 1001) {
                return response()->json([
                    'success' => false,
                    'message' => 'El archivo supera el límite de 1000 productos por importación.',
                    'errors' => []
                ], 422);
            }
            
            // Mapeo de cabeceras
            $headers = array_map(function($header) {
                return trim(mb_strtolower($header, 'UTF-8'));
            }, $rows[0]);
            
            // Buscar índices de columnas
            $colMap = [
                'codigo' => -1,
                'nombre' => -1,
                'descripcion' => -1,
                'categoria' => -1,
                'unidad' => -1,
                'precio_costo' => -1,
            ];
            
            foreach ($headers as $index => $header) {
                if (in_array($header, ['codigo', 'código', 'sku', 'ref', 'referencia'])) {
                    $colMap['codigo'] = $index;
                } elseif (in_array($header, ['nombre', 'producto', 'material', 'articulo', 'artículo'])) {
                    $colMap['nombre'] = $index;
                } elseif (in_array($header, ['descripcion', 'descripción', 'detalle'])) {
                    $colMap['descripcion'] = $index;
                } elseif (in_array($header, ['categoria', 'categoría', 'grupo'])) {
                    $colMap['categoria'] = $index;
                } elseif (in_array($header, ['unidad', 'medida', 'unidad de medida', 'u/m', 'um'])) {
                    $colMap['unidad'] = $index;
                } elseif (in_array($header, ['precio', 'costo', 'precio costo', 'precio_costo', 'valor'])) {
                    $colMap['precio_costo'] = $index;
                }
            }
            
            // Validar que al menos las columnas obligatorias estén presentes o mapeadas
            if ($colMap['nombre'] === -1) {
                return response()->json([
                    'success' => false,
                    'message' => 'No se encontró la columna obligatoria "Nombre" o "Producto". Asegúrese de usar una de estas cabeceras.',
                    'errors' => []
                ], 422);
            }
            if ($colMap['unidad'] === -1) {
                return response()->json([
                    'success' => false,
                    'message' => 'No se encontró la columna obligatoria "Unidad" o "Medida". Asegúrese de usar una de estas cabeceras.',
                    'errors' => []
                ], 422);
            }
            
            $errors = [];
            $validatedData = [];
            
            // Omitir cabecera
            for ($i = 1; $i < count($rows); $i++) {
                $row = $rows[$i];
                $rowNum = $i + 1;
                
                // Si la fila está completamente vacía, la ignoramos
                $nonEmpty = array_filter($row, function($val) {
                    return $val !== null && trim($val) !== '';
                });
                if (empty($nonEmpty)) {
                    continue;
                }
                
                $codigo = $colMap['codigo'] !== -1 ? trim($row[$colMap['codigo']]) : null;
                $nombre = $colMap['nombre'] !== -1 ? trim($row[$colMap['nombre']]) : '';
                $descripcion = $colMap['descripcion'] !== -1 ? trim($row[$colMap['descripcion']]) : null;
                $categoriaName = $colMap['categoria'] !== -1 ? trim($row[$colMap['categoria']]) : null;
                $unidad = $colMap['unidad'] !== -1 ? trim($row[$colMap['unidad']]) : '';
                $precioCosto = $colMap['precio_costo'] !== -1 ? trim($row[$colMap['precio_costo']]) : 0;
                
                // Validaciones de fila
                $rowErrors = [];
                
                if (empty($nombre)) {
                    $rowErrors[] = 'El nombre es obligatorio.';
                }
                
                if (empty($unidad)) {
                    $rowErrors[] = 'La unidad es obligatoria.';
                }
                
                // Validar numérico para precio_costo
                if ($precioCosto !== '' && $precioCosto !== null) {
                    $cleanedPrecio = preg_replace('/[^\d\.]/', '', str_replace(',', '.', $precioCosto));
                    if (!is_numeric($cleanedPrecio)) {
                        $rowErrors[] = 'El precio de costo debe ser un valor numérico válido.';
                    } else {
                        $precioCosto = (double) $cleanedPrecio;
                    }
                } else {
                    $precioCosto = 0.0;
                }
                
                if (!empty($rowErrors)) {
                    $errors["Fila $rowNum"] = $rowErrors;
                } else {
                    $validatedData[] = [
                        'row' => $rowNum,
                        'codigo' => $codigo !== '' ? $codigo : null,
                        'nombre' => $nombre,
                        'descripcion' => $descripcion !== '' ? $descripcion : null,
                        'categoria_name' => $categoriaName !== '' ? $categoriaName : null,
                        'unidad' => strtoupper($unidad),
                        'precio_costo' => $precioCosto,
                    ];
                }
            }
            
            // Si hay errores, retornar reporte
            if (!empty($errors)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Se encontraron errores de validación en el archivo.',
                    'errors' => $errors
                ], 422);
            }
            
            // Procesar importación en transacción
            DB::beginTransaction();
            
            $inserted = 0;
            $updated = 0;
            
            foreach ($validatedData as $data) {
                // Resolver categoría
                $categoriaId = null;
                if ($data['categoria_name']) {
                    $categoria = \App\Models\Categoria::whereRaw('LOWER(nombre) = ?', [strtolower($data['categoria_name'])])->first();
                    if (!$categoria) {
                        $categoria = \App\Models\Categoria::create([
                            'nombre' => $data['categoria_name'],
                            'activo' => true
                        ]);
                    }
                    $categoriaId = $categoria->id;
                }
                
                // Buscar si ya existe por código
                $material = null;
                if ($data['codigo']) {
                    $material = Material::where('codigo', $data['codigo'])->first();
                }
                
                if ($material) {
                    $material->update([
                        'nombre' => $data['nombre'],
                        'descripcion' => $data['descripcion'],
                        'categoria_id' => $categoriaId ?? $material->categoria_id,
                        'unidad' => $data['unidad'],
                        'precio_costo' => $data['precio_costo'],
                    ]);
                    $updated++;
                } else {
                    Material::create([
                        'codigo' => $data['codigo'],
                        'nombre' => $data['nombre'],
                        'descripcion' => $data['descripcion'],
                        'categoria_id' => $categoriaId,
                        'unidad' => $data['unidad'],
                        'precio_costo' => $data['precio_costo'],
                        'estado' => true,
                    ]);
                    $inserted++;
                }
            }
            
            DB::commit();
            
            return response()->json([
                'success' => true,
                'message' => 'Importación completada con éxito.',
                'inserted' => $inserted,
                'updated' => $updated
            ]);
            
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Error en importación de materiales: ' . $e->getMessage(), [
                'exception' => $e
            ]);
            return response()->json([
                'success' => false,
                'message' => 'Ocurrió un error al procesar el archivo: ' . $e->getMessage(),
                'errors' => []
            ], 500);
        }
    }
}
