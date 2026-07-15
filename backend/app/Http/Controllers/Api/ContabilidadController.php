<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CatalogoCuenta;
use App\Models\AsientoContable;
use App\Models\Proyecto;
use App\Models\PagoCliente;
use App\Models\Compra;
use Illuminate\Http\Request;

class ContabilidadController extends Controller
{
    public function catalogo(Request $request)
    {
        $allCuentas = CatalogoCuenta::all();
        
        $saldos = \DB::table('asiento_detalles')
            ->select('cuenta_id', 
                \DB::raw('SUM(debe) as total_debe'), 
                \DB::raw('SUM(haber) as total_haber'))
            ->groupBy('cuenta_id')
            ->get()
            ->keyBy('cuenta_id');

        // 1. Calcular balances individuales (solo de esa cuenta)
        foreach ($allCuentas as $c) {
            $propio = $saldos->get($c->id);
            $c->balance = $propio ? (double)($propio->total_debe - $propio->total_haber) : 0.0;
        }

        // 2. Sumar hacia arriba (de mayor nivel a menor)
        // Esto asegura que el padre sume lo que sus hijos ya sumaron
        $maxNivel = $allCuentas->max('nivel') ?? 1;
        for ($i = $maxNivel; $i > 1; $i--) {
            foreach ($allCuentas->where('nivel', $i) as $c) {
                if ($c->padre_id) {
                    $padre = $allCuentas->firstWhere('id', $c->padre_id);
                    if ($padre) {
                        $padre->balance += $c->balance;
                    }
                }
            }
        }

        if ($request->query('plano')) {
            return $allCuentas;
        }

        // 3. Construir el árbol en memoria sin hacer más consultas
        $tree = $allCuentas->whereNull('padre_id')->values();
        $this->enlazarHijos($tree, $allCuentas);

        return $tree;
    }

    private function enlazarHijos($parentCuentas, $allCuentas)
    {
        foreach ($parentCuentas as $p) {
            $hijos = $allCuentas->where('padre_id', $p->id)->values();
            $p->setRelation('hijos', $hijos);
            if ($hijos->isNotEmpty()) {
                $this->enlazarHijos($hijos, $allCuentas);
            }
        }
    }

    public function asientos()
    {
        return AsientoContable::with('detalles.cuenta')->latest()->get();
    }

    public function destroyAsiento($id)
    {
        if (auth()->user()->username !== 'ludeveloper') {
            return response()->json(['message' => 'Acción denegada. Solo el súper usuario puede eliminar asientos.'], 403);
        }

        $asiento = AsientoContable::findOrFail($id);
        $asiento->delete();

        return response()->noContent();
    }

    public function bancos()
    {
        return CatalogoCuenta::where('codigo', 'like', '1.1.01%')
            ->where('es_detalle', true)
            ->get();
    }

    public function dashboard()
    {
        $ingresos = PagoCliente::sum('monto');
        $gastos = Compra::sum('total');
        $proyectosActivos = Proyecto::where('estado', 'Activo')->count();
        
        // Cuentas por cobrar: (Suma de presupuestos) - (Suma de cobros)
        $totalPresupuestado = Proyecto::sum('presupuesto_estimado');
        $itbis = Proyecto::sum('itbis');
        $transporte = Proyecto::sum('transporte');
        $supervision = Proyecto::sum('supervision_tecnica');
        $otros = Proyecto::sum('otros_costos');
        
        $totalGeneral = $totalPresupuestado + $itbis + $transporte + $supervision + $otros;
        $cuentasPorCobrar = $totalGeneral - $ingresos;

        // Cálculo de ITBIS para la DGII
        $itbisPagado = \DB::table('asiento_detalles')
            ->join('catalogo_cuentas', 'asiento_detalles.cuenta_id', '=', 'catalogo_cuentas.id')
            ->where('catalogo_cuentas.codigo', 'like', '1.1.03%')
            ->selectRaw('SUM(debe) - SUM(haber) as total')
            ->first()->total ?? 0;

        $itbisPorPagar = \DB::table('asiento_detalles')
            ->join('catalogo_cuentas', 'asiento_detalles.cuenta_id', '=', 'catalogo_cuentas.id')
            ->where('catalogo_cuentas.codigo', 'like', '2.1.03%')
            ->selectRaw('SUM(haber) - SUM(debe) as total')
            ->first()->total ?? 0;

        return [
            'ingresos_totales' => (double)$ingresos,
            'gastos_totales' => (double)$gastos,
            'proyectos_activos' => $proyectosActivos,
            'cuentas_por_cobrar' => (double)$cuentasPorCobrar,
            'utilidad_bruta' => (double)($ingresos - $gastos),
            'itbis_pagado' => (double)$itbisPagado,
            'itbis_por_pagar' => (double)$itbisPorPagar,
            'itbis_neto' => (double)($itbisPorPagar - $itbisPagado),
        ];
    }

    public function estadoResultados(Request $request)
    {
        $proyectoId = $request->query('proyecto_id');

        // Ingresos (Cuentas tipo Ingreso - 4)
        $ingresos = \App\Models\CatalogoCuenta::where('tipo', 'Ingreso')
            ->where('es_detalle', true)
            ->get()
            ->sum(function($c) use ($proyectoId) {
                $query = \App\Models\AsientoDetalle::where('cuenta_id', $c->id);
                if ($proyectoId) {
                    $query->where('centro_costo_id', $proyectoId);
                }
                return -($query->sum('debe') - $query->sum('haber'));
            });

        // Costos (Cuentas tipo Costo - 5)
        $costos = \App\Models\CatalogoCuenta::where('tipo', 'Costo')
            ->where('es_detalle', true)
            ->get()
            ->sum(function($c) use ($proyectoId) {
                $query = \App\Models\AsientoDetalle::where('cuenta_id', $c->id);
                if ($proyectoId) {
                    $query->where('centro_costo_id', $proyectoId);
                }
                return $query->sum('debe') - $query->sum('haber');
            });

        // Gastos (Cuentas tipo Gasto - 6)
        $gastos = \App\Models\CatalogoCuenta::where('tipo', 'Gasto')
            ->where('es_detalle', true)
            ->get()
            ->sum(function($c) use ($proyectoId) {
                $query = \App\Models\AsientoDetalle::where('cuenta_id', $c->id);
                if ($proyectoId) {
                    $query->where('centro_costo_id', $proyectoId);
                }
                return $query->sum('debe') - $query->sum('haber');
            });

        return [
            'ingresos' => $ingresos,
            'costos' => $costos,
            'utilidad_bruta' => $ingresos - $costos,
            'gastos' => $gastos,
            'utilidad_neta' => $ingresos - $costos - $gastos,
            'fecha_reporte' => now()->format('Y-m-d H:i:s'),
            'filtrado_por_proyecto' => $proyectoId ? true : false,
        ];
    }
    
    public function obligaciones(Request $request)
    {
        $cuentasObligaciones = [
            '2.1.03' => 'ITBIS POR PAGAR',
            '2.1.04' => 'TSS POR PAGAR',
            '2.1.05' => 'ISR POR PAGAR',
            '2.1.06' => 'INFOTEP POR PAGAR',
        ];
        
        $resultados = [];
        
        foreach ($cuentasObligaciones as $codigo => $nombre) {
            $cuenta = \App\Models\CatalogoCuenta::where('codigo', $codigo)->first();
            if ($cuenta) {
                $saldo = \DB::table('asiento_detalles')
                    ->where('cuenta_id', $cuenta->id)
                    ->selectRaw('SUM(haber) - SUM(debe) as total')
                    ->first()->total ?? 0;
                    
                $detalle = null;
                // Calculo automático del neto para ITBIS
                if ($codigo === '2.1.03') {
                    $cuentaItbisPagado = \App\Models\CatalogoCuenta::where('codigo', '1.1.03')->first();
                    $saldoItbisPagado = 0;
                    if ($cuentaItbisPagado) {
                        $saldoItbisPagado = \DB::table('asiento_detalles')
                            ->where('cuenta_id', $cuentaItbisPagado->id)
                            ->selectRaw('SUM(debe) - SUM(haber) as total')
                            ->first()->total ?? 0;
                    }
                    
                    $saldoNeto = $saldo - $saldoItbisPagado;
                    
                    $detalle = [
                        'itbis_cobrado' => (double)$saldo,
                        'itbis_pagado' => (double)$saldoItbisPagado,
                        'total_neto' => (double)$saldoNeto
                    ];
                    
                    $saldo = $saldoNeto; // Actualizamos el saldo principal para que se muestre el neto
                }
                    
                $resultados[] = [
                    'cuenta_id' => $cuenta->id,
                    'codigo' => $codigo,
                    'nombre' => $nombre,
                    'saldo' => (double)$saldo,
                    'detalle' => $detalle
                ];
            }
        }
        
        return response()->json($resultados);
    }
    
    public function pagarObligacion(Request $request)
    {
        $validated = $request->validate([
            'cuenta_id' => 'required|exists:catalogo_cuentas,id', // Cuenta de la obligacion (ITBIS, TSS, etc)
            'banco_id' => 'required|exists:catalogo_cuentas,id', // Cuenta de banco desde donde se paga
            'monto_principal' => 'required|numeric|min:0.01',
            'monto_recargos' => 'nullable|numeric|min:0',
            'fecha' => 'required|date',
            'referencia' => 'nullable|string',
        ]);
        
        $montoRecargos = $validated['monto_recargos'] ?? 0;
        $montoTotal = $validated['monto_principal'] + $montoRecargos;
        
        return \DB::transaction(function () use ($validated, $montoRecargos, $montoTotal) {
            $asientoService = app(\App\Services\AsientoService::class);
            $cuentaObligacion = \App\Models\CatalogoCuenta::find($validated['cuenta_id']);
            
            $detallesAsiento = [
                [
                    'cuenta_id' => $validated['cuenta_id'], // Disminuimos el pasivo
                    'debe' => $validated['monto_principal'],
                    'haber' => 0,
                ],
                [
                    'cuenta_id' => $validated['banco_id'], // Disminuimos el activo
                    'debe' => 0,
                    'haber' => $montoTotal,
                ]
            ];
            
            // Compensación automática de ITBIS si es la cuenta 2.1.03 (ITBIS POR PAGAR)
            if ($cuentaObligacion && $cuentaObligacion->codigo === '2.1.03') {
                $cuentaItbisPagado = \App\Models\CatalogoCuenta::where('codigo', '1.1.03')->first();
                if ($cuentaItbisPagado) {
                    $saldoItbisPagado = \DB::table('asiento_detalles')
                        ->where('cuenta_id', $cuentaItbisPagado->id)
                        ->selectRaw('SUM(debe) - SUM(haber) as total')
                        ->first()->total ?? 0;
                        
                    if ($saldoItbisPagado > 0) {
                        // Crédito a ITBIS Pagado para liquidarlo a cero
                        $detallesAsiento[] = [
                            'cuenta_id' => $cuentaItbisPagado->id,
                            'debe' => 0,
                            'haber' => $saldoItbisPagado,
                        ];
                        // Débito adicional a ITBIS por Pagar por el monto compensado
                        $detallesAsiento[] = [
                            'cuenta_id' => $validated['cuenta_id'],
                            'debe' => $saldoItbisPagado,
                            'haber' => 0,
                        ];
                    }
                }
            }
            
            // Si hay recargos, añadir el gasto
            if ($montoRecargos > 0) {
                $cuentaRecargos = \App\Models\CatalogoCuenta::where('codigo', '6.1.01')->first(); // Recargos y Moras
                if ($cuentaRecargos) {
                    $detallesAsiento[] = [
                        'cuenta_id' => $cuentaRecargos->id,
                        'debe' => $montoRecargos,
                        'haber' => 0,
                    ];
                }
            }
            
            $asientoService->registrarAsiento(
                $validated['fecha'],
                "Pago de Obligación: {$cuentaObligacion->nombre} " . ($validated['referencia'] ? "- Ref: {$validated['referencia']}" : ""),
                $detallesAsiento,
                'PagoObligacion',
                null
            );
            
            return response()->json(['message' => 'Obligación pagada correctamente']);
        });
    }
}
