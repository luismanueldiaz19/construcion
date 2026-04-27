<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Recepcion;
use App\Models\Compra;
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
        ]);

        return DB::transaction(function () use ($validated) {
            $compra = Compra::with('detalles')->findOrFail($validated['compra_id']);

            // 1. Crear registro de recepción
            $recepcion = Recepcion::create($validated);

            // 2. Dar entrada al inventario del proyecto
            foreach ($compra->detalles as $detalle) {
                $inv = Inventario::firstOrNew([
                    'proyecto_id' => $compra->proyecto_id,
                    'material_id' => $detalle->material_id,
                ]);
                
                // Si es nuevo, inicializamos stock a 0
                if (!$inv->exists) {
                    $inv->stock = 0;
                }
                
                $inv->stock += $detalle->cantidad;
                $inv->save();
            }

            // 3. Actualizar estado de la compra
            $compra->update(['estado' => 'Recibido']);

            return $recepcion;
        });
    }
}
