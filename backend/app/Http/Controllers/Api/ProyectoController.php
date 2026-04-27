<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Proyecto;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ProyectoController extends Controller
{
    public function index()
    {
        $proyectos = Proyecto::with(['partidas.subpartidas.avances'])->get();
        
        foreach ($proyectos as $proyecto) {
            $this->calculateProgress($proyecto);
        }

        return $proyectos;
    }

    public function show($id)
    {
        $proyecto = Proyecto::with(['partidas.subpartidas.avances'])->findOrFail($id);
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
        
        // Calcular COSTOS REALES desde la contabilidad
        $proyecto->costo_real = \DB::table('asiento_detalles')
            ->join('catalogo_cuentas', 'asiento_detalles.cuenta_id', '=', 'catalogo_cuentas.id')
            ->where('asiento_detalles.centro_costo_id', $proyecto->id)
            ->where(function($q) {
                $q->where('catalogo_cuentas.codigo', 'like', '5%') // Costos
                  ->orWhere('catalogo_cuentas.codigo', 'like', '6%'); // Gastos
            })
            ->sum('asiento_detalles.debe');

        // Calcular total cobrado al cliente
        $proyecto->total_cobrado = \App\Models\PagoCliente::where('proyecto_id', $proyecto->id)->sum('monto');

        // Calcular INGRESO NETO REAL (Cuentas de Ingreso 4.x)
        $proyecto->ingreso_neto_real = \DB::table('asiento_detalles')
            ->join('catalogo_cuentas', 'asiento_detalles.cuenta_id', '=', 'catalogo_cuentas.id')
            ->where('asiento_detalles.centro_costo_id', $proyecto->id)
            ->where('catalogo_cuentas.codigo', 'like', '4%')
            ->sum('asiento_detalles.haber');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'nombre' => 'required|string|max:255',
            'cliente' => 'nullable|string',
            'ubicacion' => 'nullable|string',
            'fecha_inicio' => 'nullable|date',
            'fecha_fin' => 'nullable|date',
            'presupuesto_estimado' => 'nullable|numeric',
            'itbis' => 'nullable|numeric',
            'transporte' => 'nullable|numeric',
            'supervision_tecnica' => 'nullable|numeric',
            'otros_costos' => 'nullable|numeric',
            'partidas' => 'nullable|array',
            'partidas.*.descripcion' => 'required|string',
            'partidas.*.subpartidas' => 'nullable|array',
            'partidas.*.subpartidas.*.descripcion' => 'required|string',
            'partidas.*.subpartidas.*.cantidad' => 'required|numeric',
            'partidas.*.subpartidas.*.costo_unitario' => 'required|numeric',
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

            // Actualizar el presupuesto total del proyecto automáticamente
            $proyecto->update(['presupuesto_estimado' => $totalPresupuesto]);

            return $proyecto->load('partidas.subpartidas');
        });
    }

    public function update(Request $request, Proyecto $proyecto)
    {
        $proyecto->update($request->all());
        return $proyecto;
    }

    public function destroy(Proyecto $proyecto)
    {
        $proyecto->delete();
        return response()->noContent();
    }

    public function partidas($id)
    {
        $proyecto = Proyecto::findOrFail($id);
        // Retornamos todas las subpartidas vinculadas al proyecto a través de sus partidas
        return DB::table('subpartidas')
            ->join('partidas', 'subpartidas.partida_id', '=', 'partidas.id')
            ->where('partidas.proyecto_id', $id)
            ->select('subpartidas.id', 'subpartidas.descripcion as nombre')
            ->get();
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
}
