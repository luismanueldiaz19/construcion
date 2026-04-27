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
}
