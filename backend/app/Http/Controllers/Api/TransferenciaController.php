<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Transferencia;
use App\Models\Inventario;
use App\Models\InventarioLocal;
use App\Models\InventarioLocalStock;
use App\Models\CompraDetalle;
use App\Models\Material;
use App\Models\Proyecto;
use App\Models\CatalogoCuenta;
use App\Services\AsientoService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TransferenciaController extends Controller
{
    protected $asientoService;

    public function __construct(AsientoService $asientoService)
    {
        $this->asientoService = $asientoService;
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'material_id' => 'required|exists:materiales,id',
            'proyecto_origen_id' => 'nullable|exists:proyectos,id',
            'proyecto_destino_id' => 'nullable|exists:proyectos,id',
            'inventario_local_origen_id' => 'nullable|exists:inventarios_locales,id',
            'inventario_local_destino_id' => 'nullable|exists:inventarios_locales,id',
            'cantidad' => 'required|numeric|min:0.01',
            'fecha' => 'required|date',
            'observaciones' => 'nullable|string',
        ]);

        return DB::transaction(function () use ($validated) {
            $materialId = $validated['material_id'];
            $proyectoOrigenId = $validated['proyecto_origen_id'] ?? null;
            $proyectoDestinoId = $validated['proyecto_destino_id'] ?? null;
            $inventarioLocalOrigenId = $validated['inventario_local_origen_id'] ?? null;
            $inventarioLocalDestinoId = $validated['inventario_local_destino_id'] ?? null;
            $cantidad = $validated['cantidad'];

            // Validar origen
            if (!$proyectoOrigenId && !$inventarioLocalOrigenId) {
                return response()->json(['message' => 'Debe especificar un origen (Proyecto o Almacén)'], 422);
            }
            if ($proyectoOrigenId && $inventarioLocalOrigenId) {
                return response()->json(['message' => 'No puede tener origen de Proyecto y Almacén simultáneamente'], 422);
            }

            // Validar destino
            if (!$proyectoDestinoId && !$inventarioLocalDestinoId) {
                return response()->json(['message' => 'Debe especificar un destino (Proyecto o Almacén)'], 422);
            }
            if ($proyectoDestinoId && $inventarioLocalDestinoId) {
                return response()->json(['message' => 'No puede tener destino de Proyecto y Almacén simultáneamente'], 422);
            }

            // Validar que no sea el mismo origen y destino
            if ($proyectoOrigenId && $proyectoDestinoId && $proyectoOrigenId == $proyectoDestinoId) {
                return response()->json(['message' => 'El proyecto origen y destino no pueden ser el mismo'], 422);
            }
            if ($inventarioLocalOrigenId && $inventarioLocalDestinoId && $inventarioLocalOrigenId == $inventarioLocalDestinoId) {
                return response()->json(['message' => 'El almacén origen y destino no pueden ser el mismo'], 422);
            }

            // 1. Verificar stock en origen
            $costoUnitario = 0;
            if ($proyectoOrigenId) {
                $invOrigen = Inventario::where('proyecto_id', $proyectoOrigenId)
                    ->where('material_id', $materialId)
                    ->first();

                if (!$invOrigen || $invOrigen->stock < $cantidad) {
                    return response()->json(['message' => 'Stock insuficiente en el proyecto de origen'], 422);
                }

                // Determinar costo unitario (Promedio de compras en el proyecto, fallback a precio_costo global)
                $costoUnitario = CompraDetalle::whereHas('compra', function($q) use ($proyectoOrigenId) {
                        $q->where('proyecto_id', $proyectoOrigenId);
                    })
                    ->where('material_id', $materialId)
                    ->avg('precio_unitario') ?? 0;
            } else {
                $invOrigen = InventarioLocalStock::where('inventario_local_id', $inventarioLocalOrigenId)
                    ->where('material_id', $materialId)
                    ->first();

                if (!$invOrigen || $invOrigen->stock < $cantidad) {
                    return response()->json(['message' => 'Stock insuficiente en el almacén de origen'], 422);
                }

                // Determinar costo unitario (Promedio general de todas las compras de dicho material, fallback a precio_costo global)
                $costoUnitario = CompraDetalle::where('material_id', $materialId)
                    ->avg('precio_unitario') ?? 0;
            }

            if ($costoUnitario <= 0) {
                $costoUnitario = Material::where('id', $materialId)->value('precio_costo') ?? 0;
            }

            $totalCosto = $cantidad * $costoUnitario;

            // 2. Registrar Transferencia
            $transferencia = Transferencia::create([
                'material_id' => $materialId,
                'proyecto_origen_id' => $proyectoOrigenId,
                'proyecto_destino_id' => $proyectoDestinoId,
                'inventario_local_origen_id' => $inventarioLocalOrigenId,
                'inventario_local_destino_id' => $inventarioLocalDestinoId,
                'cantidad' => $cantidad,
                'fecha' => $validated['fecha'],
                'observaciones' => $validated['observaciones'] ?? null,
            ]);

            // 3. Actualizar Stocks
            $invOrigen->decrement('stock', $cantidad);

            if ($proyectoDestinoId) {
                $invDestino = Inventario::firstOrCreate(
                    ['proyecto_id' => $proyectoDestinoId, 'material_id' => $materialId],
                    ['stock' => 0]
                );
                $invDestino->increment('stock', $cantidad);
            } else {
                $invDestino = InventarioLocalStock::firstOrCreate(
                    ['inventario_local_id' => $inventarioLocalDestinoId, 'material_id' => $materialId],
                    ['stock' => 0]
                );
                $invDestino->increment('stock', $cantidad);
            }

            // 4. Asiento Contable (Mover de un Inventario a otro en el catálogo)
            $material = Material::findOrFail($materialId);
            
            // Obtener nombres de origen y destino para la glosa
            $origenNombre = '';
            $centroCostoOrigen = null;
            if ($proyectoOrigenId) {
                $proyectoOrigen = Proyecto::findOrFail($proyectoOrigenId);
                $origenNombre = "Proyecto: " . $proyectoOrigen->nombre;
                $centroCostoOrigen = $proyectoOrigenId;
            } else {
                $localOrigen = InventarioLocal::findOrFail($inventarioLocalOrigenId);
                $origenNombre = "Almacén: " . $localOrigen->name_inventario;
            }

            $destinoNombre = '';
            $centroCostoDestino = null;
            if ($proyectoDestinoId) {
                $proyectoDestino = Proyecto::findOrFail($proyectoDestinoId);
                $destinoNombre = "Proyecto: " . $proyectoDestino->nombre;
                $centroCostoDestino = $proyectoDestinoId;
            } else {
                $localDestino = InventarioLocal::findOrFail($inventarioLocalDestinoId);
                $destinoNombre = "Almacén: " . $localDestino->name_inventario;
            }

            $cuentaInventario = CatalogoCuenta::where('codigo', '1.1.02')->first();

            if ($cuentaInventario) {
                $detallesAsiento = [
                    [
                        'cuenta_id' => $cuentaInventario->id,
                        'debe' => $totalCosto,
                        'haber' => 0,
                        'centro_costo_id' => $centroCostoDestino,
                    ],
                    [
                        'cuenta_id' => $cuentaInventario->id,
                        'debe' => 0,
                        'haber' => $totalCosto,
                        'centro_costo_id' => $centroCostoOrigen,
                    ]
                ];

                $glosa = "Transf: {$cantidad} {$material->unidad} de {$material->nombre} desde {$origenNombre} a {$destinoNombre}";

                $this->asientoService->registrarAsiento(
                    $validated['fecha'],
                    $glosa,
                    $detallesAsiento,
                    'Transferencia',
                    $transferencia->id
                );
            }

            return response()->json([
                'message' => 'Transferencia registrada y contabilizada con éxito',
                'transferencia' => $transferencia
            ]);
        });
    }
}
