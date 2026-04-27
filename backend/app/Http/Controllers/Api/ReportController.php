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
