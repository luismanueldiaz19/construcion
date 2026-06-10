<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Proyecto;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ProyectoController extends Controller
{
    public function index(Request $request)
    {
        $query = Proyecto::with(['partidas.subpartidas.avances', 'client']);

        if ($request->has('estado') && !empty($request->estado) && $request->estado !== 'Todos') {
            $estados = explode(',', $request->estado);
            $query->whereIn('estado', $estados);
        }

        if ($request->has('year') && !empty($request->year)) {
            $query->whereYear('created_at', $request->year);
        }

        if ($request->has('search') && !empty($request->search)) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('nombre', 'like', "%{$search}%")
                  ->orWhere('cliente', 'like', "%{$search}%")
                  ->orWhere('ubicacion', 'like', "%{$search}%");
            });
        }

        $proyectos = $query->orderBy('created_at', 'desc')->get();
        
        foreach ($proyectos as $proyecto) {
            $this->calculateProgress($proyecto);
        }

        return $proyectos;
    }

    public function show($id)
    {
        $proyecto = Proyecto::with(['partidas.subpartidas.avances', 'client'])->findOrFail($id);
        $this->calculateProgress($proyecto);
        return $proyecto;
    }

    private function calculateProgress($proyecto)
    {
        $totalEjecutado = 0;
        $avanceFisicoTotal = 0;
        $totalSubpartidas = 0;

        foreach ($proyecto->partidas as $partida) {
            foreach ($partida->subpartidas as $sub) {
                $ultimoAvance = $sub->avances->last();
                $porcentaje = $ultimoAvance ? $ultimoAvance->porcentaje : 0;
                
                $sub->avance_actual = $porcentaje;
                $sub->valor_ejecutado = ($porcentaje / 100) * $sub->total_presupuestado;
                
                $totalEjecutado += $sub->valor_ejecutado;
                $avanceFisicoTotal += $porcentaje;
                $totalSubpartidas++;
            }
        }

        // Calcular Factor de Costos Globales (ITBIS, Transporte, Supervisión, Otros)
        $subtotalEstimado = $proyecto->partidas->sum(function($p) {
            return $p->subpartidas->sum('total_presupuestado');
        });

        $totalConGlobales = $subtotalEstimado 
                            + $proyecto->itbis 
                            + $proyecto->transporte 
                            + $proyecto->supervision_tecnica 
                            + $proyecto->otros_costos;

        $factorGlobal = $subtotalEstimado > 0 ? ($totalConGlobales / $subtotalEstimado) : 1;

        $proyecto->porcentaje_avance_total = $totalSubpartidas > 0 ? round($avanceFisicoTotal / $totalSubpartidas, 2) : 0;
        $proyecto->monto_ejecutado_total = $totalEjecutado * $factorGlobal;
        $proyecto->total_presupuesto_con_globales = $totalConGlobales;
        
        // Calcular COSTOS E INGRESOS REALES desde la contabilidad en una sola consulta
        $stats = \DB::table('asiento_detalles')
            ->join('catalogo_cuentas', 'asiento_detalles.cuenta_id', '=', 'catalogo_cuentas.id')
            ->where('asiento_detalles.centro_costo_id', $proyecto->id)
            ->selectRaw("
                SUM(CASE WHEN catalogo_cuentas.codigo LIKE '5%' OR catalogo_cuentas.codigo LIKE '6%' THEN asiento_detalles.debe ELSE 0 END) as costo_real,
                SUM(CASE WHEN catalogo_cuentas.codigo LIKE '4%' THEN asiento_detalles.haber ELSE 0 END) as ingreso_neto_real
            ")
            ->first();
        
        $proyecto->costo_real = $stats->costo_real ?? 0;
        $proyecto->ingreso_neto_real = $stats->ingreso_neto_real ?? 0;

        // Calcular total cobrado al cliente
        $proyecto->total_cobrado = \DB::table('pagos_clientes')
            ->where('proyecto_id', $proyecto->id)
            ->sum('monto');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'nombre' => 'required|string|max:255',
            'cliente' => 'nullable|string',
            'client_id' => 'nullable|exists:clients,id',
            'ubicacion' => 'nullable|string',
            'fecha_inicio' => 'nullable|date',
            'fecha_fin' => 'nullable|date',
            'presupuesto_estimado' => 'nullable|numeric',
            'itbis' => 'nullable|numeric',
            'transporte' => 'nullable|numeric',
            'supervision_tecnica' => 'nullable|numeric',
            'otros_costos' => 'nullable|numeric',
            'notas' => 'nullable|string',
            'partidas' => 'nullable|array',
            'partidas.*.descripcion' => 'required|string',
            'partidas.*.subpartidas' => 'nullable|array',
            'partidas.*.subpartidas.*.descripcion' => 'required|string',
            'partidas.*.subpartidas.*.cantidad' => 'required|numeric',
            'partidas.*.subpartidas.*.costo_unitario' => 'required|numeric',
            'partidas.*.subpartidas.*.unidad' => 'nullable|string',
        ]);

        return DB::transaction(function () use ($validated) {
            $proyecto = \App\Models\Proyecto::create($validated);

            $totalPresupuesto = 0;
            if (isset($validated['partidas'])) {
                foreach ($validated['partidas'] as $partidaData) {
                    $partida = $proyecto->partidas()->create([
                        'descripcion' => $partidaData['descripcion'],
                    ]);

                    if (isset($partidaData['subpartidas'])) {
                        foreach ($partidaData['subpartidas'] as $sub) {
                            $subtotal = $sub['cantidad'] * $sub['costo_unitario'];
                            $totalPresupuesto += $subtotal;
                            
                            $partida->subpartidas()->create([
                                'descripcion' => $sub['descripcion'],
                                'unidad' => $sub['unidad'] ?? 'GL',
                                'cantidad' => $sub['cantidad'],
                                'costo_unitario' => $sub['costo_unitario'],
                                'total_presupuestado' => $subtotal,
                            ]);
                        }
                    }
                }
            }

            // Actualizar el presupuesto total del proyecto automáticamente (solo el subtotal directo)
            $proyecto->update(['presupuesto_estimado' => $totalPresupuesto]);

            return $proyecto->load('partidas.subpartidas');
        });
    }

    public function update(Request $request, Proyecto $proyecto)
    {
        $proyecto->update($request->all());
        return $proyecto;
    }

    public function uploadLogo(Request $request, $id)
    {
        $request->validate([
            'logo' => 'required|file|mimes:jpeg,png,jpg,gif,webp|max:15360', // 15MB max
        ]);

        $proyecto = Proyecto::findOrFail($id);

        if ($request->hasFile('logo')) {
            // Eliminar logo anterior si existe
            if ($proyecto->logo_path) {
                \Storage::disk('public')->delete($proyecto->logo_path);
            }

            $year = date('Y');
            $folder = "proyectos/{$year}/{$id}";
            $extension = $request->file('logo')->getClientOriginalExtension();
            $filename = 'logo-' . time() . '.' . $extension;
            
            $path = $request->file('logo')->storeAs($folder, $filename, 'public');
            $proyecto->update(['logo_path' => $path]);

            return response()->json([
                'message' => 'Logo subido correctamente',
                'logo_path' => $path,
                'logo_url' => \Storage::url($path)
            ]);
        }

        return response()->json(['message' => 'No se recibió ningún archivo'], 400);
    }

    public function removeLogo($id)
    {
        $proyecto = Proyecto::findOrFail($id);
        if ($proyecto->logo_path) {
            \Storage::disk('public')->delete($proyecto->logo_path);
            $proyecto->update(['logo_path' => null]);
        }
        return response()->json(['message' => 'Logo eliminado']);
    }

    public function destroy($id)
    {
        return DB::transaction(function () use ($id) {
            $proyecto = Proyecto::findOrFail($id);

            // 1. Eliminar Asientos Contables relacionados con el proyecto
            // Buscamos asientos donde el proyecto esté como centro de costo o vinculado al pago
            $pagoIds = \App\Models\PagoCliente::where('proyecto_id', $id)->pluck('id');
            \App\Models\AsientoContable::where('proyecto_id', $id)
                ->orWhere(function($q) use ($pagoIds) {
                    $q->where('origin_type', 'Ingreso')->whereIn('origin_id', $pagoIds);
                })
                ->each(function($asiento) {
                    $asiento->detalles()->delete();
                    $asiento->delete();
                });

            // 2. Eliminar Pagos de clientes
            \App\Models\PagoCliente::where('proyecto_id', $id)->delete();

            // 3. Eliminar Documentos
            \App\Models\Documento::where('proyecto_id', $id)->delete();

            // 4. Eliminar Gastos del Proyecto
            \App\Models\GastoProyecto::where('proyecto_id', $id)->delete();

            // 5. Eliminar Inventario y Consumos
            $inventarioIds = \App\Models\Inventario::where('proyecto_id', $id)->pluck('id');
            \App\Models\Consumo::whereIn('inventario_id', $inventarioIds)->delete();
            \App\Models\Inventario::where('proyecto_id', $id)->delete();

            // 6. Eliminar Partidas, Subpartidas y Avances
            foreach ($proyecto->partidas as $partida) {
                foreach ($partida->subpartidas as $sub) {
                    \App\Models\AvanceProyecto::where('subpartida_id', $sub->id)->delete();
                    $sub->delete();
                }
                $partida->delete();
            }

            // 7. Finalmente eliminar el proyecto
            if ($proyecto->logo_path) {
                \Storage::disk('public')->delete($proyecto->logo_path);
            }
            $proyecto->delete();

            return response()->json(['message' => 'Proyecto y todos sus datos relacionados eliminados correctamente.']);
        });
    }

    public function partidas($id)
    {
        return Proyecto::with('partidas.subpartidas')->findOrFail($id)->partidas;
    }

    public function provisionarTodo($id)
    {
        $proyecto = \App\Models\Proyecto::with('partidas.subpartidas')->findOrFail($id);
        foreach ($proyecto->partidas as $partida) {
            foreach ($partida->subpartidas as $sub) {
                \App\Models\AvanceProyecto::updateOrCreate(
                    ['subpartida_id' => $sub->id],
                    [
                        'partida_id' => $sub->partida_id,
                        'fecha' => now(),
                        'porcentaje' => 100,
                        'valor_ejecutado' => $sub->total_presupuestado
                    ]
                );
            }
        }
        return response()->json(['message' => 'Proyecto provisionado al 100%']);
    }

    public function addPartida(Request $request, $id)
    {
        $proyecto = Proyecto::findOrFail($id);
        
        $validated = $request->validate([
            'descripcion' => 'required|string',
            'subpartidas' => 'nullable|array',
            'subpartidas.*.descripcion' => 'required|string',
            'subpartidas.*.cantidad' => 'required|numeric',
            'subpartidas.*.costo_unitario' => 'required|numeric',
            'subpartidas.*.unidad' => 'nullable|string',
        ]);

        return DB::transaction(function () use ($validated, $proyecto) {
            $partida = $proyecto->partidas()->create([
                'descripcion' => $validated['descripcion']
            ]);

            $sum = 0;
            if(isset($validated['subpartidas'])) {
                foreach($validated['subpartidas'] as $sub) {
                    $subtotal = $sub['cantidad'] * $sub['costo_unitario'];
                    $sum += $subtotal;
                    
                    $partida->subpartidas()->create([
                        'descripcion' => $sub['descripcion'],
                        'unidad' => $sub['unidad'] ?? 'GL',
                        'cantidad' => $sub['cantidad'],
                        'costo_unitario' => $sub['costo_unitario'],
                        'total_presupuestado' => $subtotal,
                    ]);
                }
            }
            
            $proyecto->increment('presupuesto_estimado', $sum);
            
            return response()->json([
                'message' => 'Partida agregada con éxito',
                'partida' => $partida->load('subpartidas')
            ]);
        });
    }

    public function addSubpartida(Request $request, $id)
    {
        $partida = \App\Models\Partida::findOrFail($id);
        $proyecto = $partida->proyecto;
        
        $validated = $request->validate([
            'descripcion' => 'required|string',
            'cantidad' => 'required|numeric',
            'costo_unitario' => 'required|numeric',
            'unidad' => 'nullable|string',
        ]);

        return DB::transaction(function () use ($validated, $partida, $proyecto) {
            $subtotal = $validated['cantidad'] * $validated['costo_unitario'];
            
            $sub = $partida->subpartidas()->create([
                'descripcion' => $validated['descripcion'],
                'unidad' => $validated['unidad'] ?? 'GL',
                'cantidad' => $validated['cantidad'],
                'costo_unitario' => $validated['costo_unitario'],
                'total_presupuestado' => $subtotal,
            ]);
            
            $proyecto->increment('presupuesto_estimado', $subtotal);
            
            return response()->json([
                'message' => 'Sub-partida agregada con éxito',
                'subpartida' => $sub
            ]);
        });
    }
}
