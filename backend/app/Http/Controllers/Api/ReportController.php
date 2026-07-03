<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Compra;
use App\Models\GastoProyecto;
use Illuminate\Http\Request;
use Barryvdh\DomPDF\Facade\Pdf;

class ReportController extends Controller
{
    public function comprasPdf(Request $request)
    {
        $query = Compra::with(['proyecto', 'proveedor']);

        if ($request->filled('proyecto_id')) {
            $query->where('proyecto_id', $request->proyecto_id);
        }
        if ($request->filled('proveedor_id')) {
            $query->where('proveedor_id', $request->proveedor_id);
        }
        if ($request->filled('estado')) {
            $query->where('estado', $request->estado);
        }
        if ($request->filled('fecha_inicio')) {
            $query->whereDate('fecha', '>=', $request->fecha_inicio);
        }
        if ($request->filled('fecha_fin')) {
            $query->whereDate('fecha', '<=', $request->fecha_fin);
        }

        $compras = $query->latest()->get();
        $total = $compras->sum('total');

        $pdf = Pdf::loadView('reports.compras', [
            'compras' => $compras,
            'total' => $total,
            'filtros' => $request->all()
        ])->setPaper('a4', 'landscape');

        return $pdf->stream('reporte_compras.pdf');
    }

    public function gastosPdf(Request $request)
    {
        $query = GastoProyecto::with(['proyecto', 'proveedor', 'subpartida']);

        if ($request->filled('proyecto_id')) {
            $query->where('proyecto_id', $request->proyecto_id);
        }
        if ($request->filled('proveedor_id')) {
            $query->where('proveedor_id', $request->proveedor_id);
        }
        if ($request->filled('tipo_gasto')) {
            $query->where('tipo_gasto', $request->tipo_gasto);
        }
        if ($request->filled('fecha_inicio')) {
            $query->whereDate('fecha', '>=', $request->fecha_inicio);
        }
        if ($request->filled('fecha_fin')) {
            $query->whereDate('fecha', '<=', $request->fecha_fin);
        }

        $gastos = $query->latest()->get();
        $total = $gastos->sum('monto');

        $pdf = Pdf::loadView('reports.gastos', [
            'gastos' => $gastos,
            'total' => $total,
            'filtros' => $request->all()
        ])->setPaper('a4', 'landscape');

        return $pdf->stream('reporte_gastos.pdf');
    }

    public function pagosClientePdf(Request $request)
    {
        $query = \App\Models\PagoCliente::with(['proyecto.client', 'cuentaContable']);

        if ($request->filled('proyecto_id')) {
            $query->where('proyecto_id', $request->proyecto_id);
        }
        if ($request->filled('fecha_inicio')) {
            $query->whereDate('fecha', '>=', $request->fecha_inicio);
        }
        if ($request->filled('fecha_fin')) {
            $query->whereDate('fecha', '<=', $request->fecha_fin);
        }

        $pagos = $query->latest()->get();
        $total = $pagos->sum('monto');

        $pdf = Pdf::loadView('reports.pagos_cliente', [
            'pagos' => $pagos,
            'total' => $total,
            'filtros' => $request->all()
        ])->setPaper('a4', 'landscape');

        return $pdf->stream('reporte_pagos.pdf');
    }

    public function estadoResultadosPdf(Request $request)
    {
        $proyectoId = $request->query('proyecto_id');
        $proyecto = null;
        
        if ($proyectoId) {
            $proyecto = \App\Models\Proyecto::with(['partidas.subpartidas', 'client'])->find($proyectoId);
            $gastosReales = \App\Models\GastoProyecto::where('proyecto_id', $proyectoId)->get();
            $consumosReales = \App\Models\Consumo::where('proyecto_id', $proyectoId)->get();
        } else {
            $gastosReales = collect();
            $consumosReales = collect();
        }

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

        $pdf = Pdf::loadView('reports.estado_resultados', [
            'proyecto' => $proyecto,
            'ingresos' => $ingresos,
            'costos' => $costos,
            'utilidad_bruta' => $ingresos - $costos,
            'gastos' => $gastos,
            'utilidad_neta' => $ingresos - $costos - $gastos,
            'gastosReales' => $gastosReales,
            'consumosReales' => $consumosReales,
            'filtros' => $request->all()
        ])->setPaper('a4', 'portrait');

        return $pdf->stream('estado_resultados.pdf');
    }

    public function partidaPdf($id)
    {
        $partida = \App\Models\Partida::with(['proyecto', 'subpartidas'])->findOrFail($id);
        $subpartidaIds = $partida->subpartidas->pluck('id');

        $gastos = GastoProyecto::with(['proveedor', 'subpartida'])
            ->whereIn('subpartida_id', $subpartidaIds)
            ->get();

        $consumos = \App\Models\Consumo::with(['material', 'subpartida'])
            ->whereIn('subpartida_id', $subpartidaIds)
            ->get();

        $totalGastos = $gastos->sum('monto');
        $totalConsumos = $consumos->sum('total');

        $pdf = Pdf::loadView('reports.partida_detail', [
            'partida' => $partida,
            'gastos' => $gastos,
            'consumos' => $consumos,
            'totalGastos' => $totalGastos,
            'totalConsumos' => $totalConsumos,
            'totalReal' => $totalGastos + $totalConsumos
        ]);

        return $pdf->stream('reporte_partida_'.$id.'.pdf');
    }

    public function proyectoPdf($id)
    {
        $proyecto = \App\Models\Proyecto::with(['partidas.subpartidas'])->findOrFail($id);
        
        $gastos = GastoProyecto::with(['proveedor', 'subpartida'])
            ->where('proyecto_id', $id)
            ->get();

        $consumos = \App\Models\Consumo::with(['material', 'subpartida'])
            ->where('proyecto_id', $id)
            ->get();

        $totalGastos = $gastos->sum('monto');
        $totalConsumos = $consumos->sum('total');
        $totalReal = $totalGastos + $totalConsumos;

        // Calcular totales cobrados para el reporte
        $totalCobrado = \App\Models\PagoCliente::where('proyecto_id', $id)->sum('monto');

        $pdf = Pdf::loadView('reports.proyecto_detail', [
            'proyecto' => $proyecto,
            'gastos' => $gastos,
            'consumos' => $consumos,
            'totalGastos' => $totalGastos,
            'totalConsumos' => $totalConsumos,
            'totalReal' => $totalReal,
            'totalCobrado' => $totalCobrado
        ]);

        return $pdf->stream('reporte_proyecto_'.$id.'.pdf');
    }
}
