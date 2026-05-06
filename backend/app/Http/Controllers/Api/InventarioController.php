<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Proyecto;
use App\Models\Inventario;
use Illuminate\Http\Request;
use Barryvdh\DomPDF\Facade\Pdf;

class InventarioController extends Controller
{
    public function index()
    {
        return Proyecto::whereHas('inventarios', function($q) {
            $q->where('stock', '>', 0);
        })->get(['id', 'nombre']);
    }

    public function show($id)
    {
        try {
            $proyecto = Proyecto::findOrFail($id);
            
            // Balance de Inventario (Stock Actual con Totales de Entradas y Salidas)
            $balance = Inventario::with('material')
                ->where('proyecto_id', $id)
                ->get()
                ->map(function($inv) use ($id) {
                    $totalEntradas = \App\Models\RecepcionDetalle::whereHas('recepcion', function($q) use ($id) {
                            $q->whereHas('compra', function($c) use ($id) {
                                $c->where('proyecto_id', $id);
                            });
                        })
                        ->whereHas('compraDetalle', function($cd) use ($inv) {
                            $cd->where('material_id', $inv->material_id);
                        })
                        ->sum('cantidad_entregada');

                    $totalSalidas = \App\Models\Consumo::where('proyecto_id', $id)
                        ->where('material_id', $inv->material_id)
                        ->sum('cantidad');

                    return [
                        'material_id' => $inv->material_id,
                        'material' => optional($inv->material)->nombre ?? 'Material Desconocido',
                        'unidad' => optional($inv->material)->unidad ?? 'N/A',
                        'entradas' => $totalEntradas,
                        'salidas' => $totalSalidas,
                        'stock' => $inv->stock,
                        'ultimo_costo' => \App\Models\CompraDetalle::where('material_id', $inv->material_id)
                            ->latest()
                            ->value('precio_unitario') ?? 0
                    ];
                });

            // Entradas (Historial de recepciones reales)
            $entradas = \App\Models\RecepcionDetalle::with(['recepcion.compra.proveedor', 'compraDetalle.material'])
                ->whereHas('recepcion.compra', function($q) use ($id) {
                    $q->where('proyecto_id', $id);
                })
                ->get()
                ->map(function($det) {
                    return [
                        'tipo' => 'Entrada',
                        'fecha' => optional($det->recepcion)->fecha ?? now()->toDateString(),
                        'referencia' => "Recibido por: " . (optional($det->recepcion)->recibido_por ?? 'N/A') . " (Factura #" . (optional($det->recepcion)->compra_id ?? 'N/A') . ")",
                        'material' => optional($det->compraDetalle->material)->nombre ?? 'Material Desconocido',
                        'cantidad' => $det->cantidad_entregada,
                        'costo' => optional($det->compraDetalle)->precio_unitario ?? 0,
                        'total' => $det->cantidad_entregada * (optional($det->compraDetalle)->precio_unitario ?? 0)
                    ];
                });

            // Salidas (Consumos registrados)
            $salidas = \App\Models\Consumo::with(['material', 'subpartida'])
                ->where('proyecto_id', $id)
                ->get()
                ->map(function($cons) {
                    return [
                        'tipo' => 'Salida',
                        'fecha' => $cons->fecha,
                        'referencia' => "Consumo: " . (optional($cons->subpartida)->descripcion ?? 'N/A'),
                        'material' => optional($cons->material)->nombre ?? 'N/A',
                        'cantidad' => $cons->cantidad,
                        'costo' => $cons->costo_unitario,
                        'total' => $cons->total
                    ];
                });

            $movimientos = $entradas->concat($salidas)->sortByDesc('fecha')->values();

            return response()->json([
                'proyecto' => $proyecto->nombre,
                'balance' => $balance,
                'movimientos' => $movimientos
            ]);
        } catch (\Exception $e) {
            \Log::error("Error en InventarioController@show: " . $e->getMessage());
            return response()->json(['message' => 'Error al cargar el inventario: ' . $e->getMessage()], 500);
        }
    }

    public function downloadPdf($id, Request $request)
    {
        $tipo = $request->query('tipo', 'completo');
        $proyecto = Proyecto::findOrFail($id);
        
        // Reutilizamos la lógica de datos
        $data = $this->show($id)->getData(true);

        $pdf = Pdf::loadView('reports.inventory', [
            'proyecto' => $proyecto,
            'balance' => $data['balance'],
            'movimientos' => $data['movimientos'],
            'tipo' => $tipo
        ]);

        return $pdf->stream("Reporte_Inventario_{$proyecto->nombre}.pdf");
    }
}
