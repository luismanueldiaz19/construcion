<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\InventarioLocal;
use App\Models\InventarioLocalStock;
use App\Models\Transferencia;
use App\Models\CompraDetalle;
use Illuminate\Http\Request;

class InventarioLocalController extends Controller
{
    public function index()
    {
        return response()->json(InventarioLocal::all());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name_inventario' => 'required|string|max:255',
            'location' => 'required|string|max:255',
        ]);

        $local = InventarioLocal::create($validated);

        return response()->json($local, 201);
    }

    public function show($id)
    {
        try {
            $local = InventarioLocal::findOrFail($id);

            // Balance de stock por material
            $balance = InventarioLocalStock::with('material')
                ->where('inventario_local_id', $id)
                ->get()
                ->map(function ($stockItem) use ($id) {
                    $materialId = $stockItem->material_id;

                    // Entradas: Transferencias con destino a este almacén
                    $totalEntradas = Transferencia::where('inventario_local_destino_id', $id)
                        ->where('material_id', $materialId)
                        ->sum('cantidad');

                    // Salidas: Transferencias con origen en este almacén
                    $totalSalidas = Transferencia::where('inventario_local_origen_id', $id)
                        ->where('material_id', $materialId)
                        ->sum('cantidad');

                    // Último costo del material
                    $ultimoCosto = CompraDetalle::where('material_id', $materialId)
                        ->latest()
                        ->value('precio_unitario') ?? optional($stockItem->material)->precio_costo ?? 0;

                    return [
                        'material_id' => $materialId,
                        'material' => optional($stockItem->material)->nombre ?? 'Material Desconocido',
                        'unidad' => optional($stockItem->material)->unidad ?? 'N/A',
                        'entradas' => (float)$totalEntradas,
                        'salidas' => (float)$totalSalidas,
                        'stock' => (float)$stockItem->stock,
                        'ultimo_costo' => (float)$ultimoCosto,
                    ];
                });

            // Entradas de transferencias (Historial)
            $entradas = Transferencia::with(['material', 'proyectoOrigen', 'inventarioLocalOrigen'])
                ->where('inventario_local_destino_id', $id)
                ->get()
                ->map(function ($trans) {
                    $costo = CompraDetalle::where('material_id', $trans->material_id)
                        ->latest()
                        ->value('precio_unitario') ?? optional($trans->material)->precio_costo ?? 0;

                    $origen = 'N/A';
                    if ($trans->proyecto_origen_id) {
                        $origen = "Proyecto: " . optional($trans->proyectoOrigen)->nombre;
                    } elseif ($trans->inventario_local_origen_id) {
                        $origen = "Almacén: " . optional($trans->inventarioLocalOrigen)->name_inventario;
                    }

                    return [
                        'tipo' => 'Entrada',
                        'fecha' => $trans->fecha,
                        'referencia' => "Transf. desde {$origen}" . ($trans->observaciones ? " ({$trans->observaciones})" : ""),
                        'material' => optional($trans->material)->nombre ?? 'Material Desconocido',
                        'cantidad' => (float)$trans->cantidad,
                        'costo' => (float)$costo,
                        'total' => (float)($trans->cantidad * $costo),
                    ];
                });

            // Salidas de transferencias (Historial)
            $salidas = Transferencia::with(['material', 'proyectoDestino', 'inventarioLocalDestino'])
                ->where('inventario_local_origen_id', $id)
                ->get()
                ->map(function ($trans) {
                    $costo = CompraDetalle::where('material_id', $trans->material_id)
                        ->latest()
                        ->value('precio_unitario') ?? optional($trans->material)->precio_costo ?? 0;

                    $destino = 'N/A';
                    if ($trans->proyecto_destino_id) {
                        $destino = "Proyecto: " . optional($trans->proyectoDestino)->nombre;
                    } elseif ($trans->inventario_local_destino_id) {
                        $destino = "Almacén: " . optional($trans->inventarioLocalDestino)->name_inventario;
                    }

                    return [
                        'tipo' => 'Salida',
                        'fecha' => $trans->fecha,
                        'referencia' => "Transf. a {$destino}" . ($trans->observaciones ? " ({$trans->observaciones})" : ""),
                        'material' => optional($trans->material)->nombre ?? 'Material Desconocido',
                        'cantidad' => (float)$trans->cantidad,
                        'costo' => (float)$costo,
                        'total' => (float)($trans->cantidad * $costo),
                    ];
                });

            // Unir y ordenar movimientos por fecha descendente
            $movimientos = $entradas
                ->concat($salidas)
                ->sortByDesc('fecha')
                ->values();

            return response()->json([
                'name_inventario' => $local->name_inventario,
                'location' => $local->location,
                'balance' => $balance,
                'movimientos' => $movimientos,
            ]);

        } catch (\Exception $e) {
            \Log::error("Error en InventarioLocalController@show: " . $e->getMessage());
            return response()->json(['message' => 'Error al cargar el inventario local: ' . $e->getMessage()], 500);
        }
    }

    public function update(Request $request, $id)
    {
        $local = InventarioLocal::findOrFail($id);

        $validated = $request->validate([
            'name_inventario' => 'sometimes|required|string|max:255',
            'location' => 'sometimes|required|string|max:255',
        ]);

        $local->update($validated);

        return response()->json($local);
    }

    public function destroy($id)
    {
        $local = InventarioLocal::findOrFail($id);
        $local->delete();

        return response()->json(['message' => 'Inventario local eliminado correctamente']);
    }
}
