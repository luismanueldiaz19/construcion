<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Proyecto;
use App\Models\AsientoDetalle;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function index()
    {
        $proyectosActivos = Proyecto::where('estado', 'Activo')->count();
        
        // Sumar ingresos (Cuentas que empiezan con 4) y costos (Cuentas que empiezan con 5)
        $ingresos = DB::table('asiento_detalles')
            ->join('catalogo_cuentas', 'asiento_detalles.cuenta_id', '=', 'catalogo_cuentas.id')
            ->where('catalogo_cuentas.tipo', 'Ingreso')
            ->sum('haber');
            
        $costos = DB::table('asiento_detalles')
            ->join('catalogo_cuentas', 'asiento_detalles.cuenta_id', '=', 'catalogo_cuentas.id')
            ->whereIn('catalogo_cuentas.tipo', ['Costo', 'Gasto'])
            ->sum('debe');

        $rentabilidad = $ingresos - $costos;
        $roi = $costos > 0 ? ($rentabilidad / $costos) * 100 : 0;

        // Cálculo de ITBIS para la DGII (1.1.03 vs 2.1.03)
        $itbisPagado = DB::table('asiento_detalles')
            ->join('catalogo_cuentas', 'asiento_detalles.cuenta_id', '=', 'catalogo_cuentas.id')
            ->where('catalogo_cuentas.codigo', 'like', '1.1.03%')
            ->selectRaw('SUM(debe) - SUM(haber) as total')
            ->first()->total ?? 0;

        $itbisPorPagar = DB::table('asiento_detalles')
            ->join('catalogo_cuentas', 'asiento_detalles.cuenta_id', '=', 'catalogo_cuentas.id')
            ->where('catalogo_cuentas.codigo', 'like', '2.1.03%')
            ->selectRaw('SUM(haber) - SUM(debe) as total')
            ->first()->total ?? 0;

        return response()->json([
            'kpis' => [
                'proyectos_activos' => $proyectosActivos,
                'ingresos_totales' => (double)$ingresos,
                'costos_totales' => (double)$costos,
                'rentabilidad' => (double)$rentabilidad,
                'roi' => round($roi, 2) . '%',
                'itbis_pagado' => (double)$itbisPagado,
                'itbis_por_pagar' => (double)$itbisPorPagar,
                'itbis_neto' => (double)($itbisPorPagar - $itbisPagado),
            ],
            'proyectos_recientes' => Proyecto::latest()->take(5)->get()
        ]);
    }
}
