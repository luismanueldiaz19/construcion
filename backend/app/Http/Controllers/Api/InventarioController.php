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
            
            // Balance de Inventario (Stock Actual con Totales de Entradas y Salidas, incluyendo Transferencias)
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

                    // Sumar transferencias recibidas
                    $transRecibidas = \App\Models\Transferencia::where('proyecto_destino_id', $id)
                        ->where('material_id', $inv->material_id)
                        ->sum('cantidad');
                    
                    $totalEntradas += $transRecibidas;

                    $totalSalidas = \App\Models\Consumo::where('proyecto_id', $id)
                        ->where('material_id', $inv->material_id)
                        ->sum('cantidad');

                    // Sumar transferencias enviadas
                    $transEnviadas = \App\Models\Transferencia::where('proyecto_origen_id', $id)
                        ->where('material_id', $inv->material_id)
                        ->sum('cantidad');

                    $totalSalidas += $transEnviadas;

                    $ultimoCosto = \App\Models\CompraDetalle::where('material_id', $inv->material_id)
                        ->latest()
                        ->value('precio_unitario');

                    if (!$ultimoCosto || $ultimoCosto <= 0) {
                        $ultimoCosto = optional($inv->material)->precio_costo ?? 0;
                    }

                    return [
                        'material_id' => $inv->material_id,
                        'material' => optional($inv->material)->nombre ?? 'Material Desconocido',
                        'unidad' => optional($inv->material)->unidad ?? 'N/A',
                        'entradas' => $totalEntradas,
                        'salidas' => $totalSalidas,
                        'stock' => $inv->stock,
                        'ultimo_costo' => $ultimoCosto
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

            // Transferencias Recibidas (Entradas)
            $transEntradas = \App\Models\Transferencia::with(['material', 'proyectoOrigen'])
                ->where('proyecto_destino_id', $id)
                ->get()
                ->map(function($trans) {
                    $costo = \App\Models\CompraDetalle::where('material_id', $trans->material_id)
                        ->latest()
                        ->value('precio_unitario') ?? optional($trans->material)->precio_costo ?? 0;
                    return [
                        'tipo' => 'Entrada',
                        'fecha' => $trans->fecha,
                        'referencia' => "Transf. desde: " . optional($trans->proyectoOrigen)->nombre . ($trans->observaciones ? " ({$trans->observaciones})" : ""),
                        'material' => optional($trans->material)->nombre ?? 'Material Desconocido',
                        'cantidad' => $trans->cantidad,
                        'costo' => $costo,
                        'total' => $trans->cantidad * $costo
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

            // Transferencias Enviadas (Salidas)
            $transSalidas = \App\Models\Transferencia::with(['material', 'proyectoDestino'])
                ->where('proyecto_origen_id', $id)
                ->get()
                ->map(function($trans) {
                    $costo = \App\Models\CompraDetalle::where('material_id', $trans->material_id)
                        ->latest()
                        ->value('precio_unitario') ?? optional($trans->material)->precio_costo ?? 0;
                    return [
                        'tipo' => 'Salida',
                        'fecha' => $trans->fecha,
                        'referencia' => "Transf. a: " . optional($trans->proyectoDestino)->nombre . ($trans->observaciones ? " ({$trans->observaciones})" : ""),
                        'material' => optional($trans->material)->nombre ?? 'Material Desconocido',
                        'cantidad' => $trans->cantidad,
                        'costo' => $costo,
                        'total' => $trans->cantidad * $costo
                    ];
                });

            $movimientos = $entradas
                ->concat($transEntradas)
                ->concat($salidas)
                ->concat($transSalidas)
                ->sortByDesc('fecha')
                ->values();

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
