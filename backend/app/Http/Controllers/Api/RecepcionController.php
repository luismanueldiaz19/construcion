<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Recepcion;
use App\Models\RecepcionDetalle;
use App\Models\Compra;
use App\Models\CompraDetalle;
use App\Models\Inventario;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RecepcionController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'compra_id' => 'required|exists:compras,id',
            'fecha' => 'required|date',
            'recibido_por' => 'required|string',
            'observaciones' => 'nullable|string',
            'items' => 'required|array',
            'items.*.compra_detalle_id' => 'required|exists:compra_detalles,id',
            'items.*.cantidad' => 'required|numeric|min:0',
        ]);

        return DB::transaction(function () use ($validated) {
            $compra = Compra::with('detalles')->findOrFail($validated['compra_id']);

            // 1. Crear registro de recepción principal
            $recepcion = Recepcion::create([
                'compra_id' => $validated['compra_id'],
                'fecha' => $validated['fecha'],
                'recibido_por' => $validated['recibido_por'],
                'observaciones' => $validated['observaciones'] ?? null,
            ]);

            foreach ($validated['items'] as $item) {
                if ($item['cantidad'] <= 0) continue;

                $detalle = CompraDetalle::findOrFail($item['compra_detalle_id']);
                
                // 2. Crear detalle de la recepción
                RecepcionDetalle::create([
                    'recepcion_id' => $recepcion->id,
                    'compra_detalle_id' => $detalle->id,
                    'cantidad_entregada' => $item['cantidad'],
                ]);

                // 3. Actualizar cantidad recibida en el detalle de la compra
                $detalle->increment('cantidad_recibida', $item['cantidad']);

                // 4. Dar entrada al inventario del proyecto
                $inv = Inventario::firstOrNew([
                    'proyecto_id' => $compra->proyecto_id,
                    'material_id' => $detalle->material_id,
                ]);
                
                if (!$inv->exists) {
                    $inv->stock = 0;
                }
                
                $inv->stock += $item['cantidad'];
                $inv->save();
            }

            // 5. Actualizar estado de la compra (Pendiente, Parcial o Recibido)
            $this->actualizarEstadoCompra($compra);

            return $recepcion->load('detalles');
        });
    }

    private function actualizarEstadoCompra(Compra $compra)
    {
        $compra->load('detalles');
        $totalComprado = $compra->detalles->sum('cantidad');
        $totalRecibido = $compra->detalles->sum('cantidad_recibida');

        if ($totalRecibido >= $totalComprado) {
            $compra->update(['estado' => 'Recibido']);
        } elseif ($totalRecibido > 0) {
            $compra->update(['estado' => 'Parcial']);
        }
    }
}
