<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Transferencia;
use App\Models\Inventario;
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
            'proyecto_origen_id' => 'required|exists:proyectos,id',
            'proyecto_destino_id' => 'required|exists:proyectos,id|different:proyecto_origen_id',
            'cantidad' => 'required|numeric|min:0.01',
            'fecha' => 'required|date',
            'observaciones' => 'nullable|string',
        ]);

        return DB::transaction(function () use ($validated) {
            $materialId = $validated['material_id'];
            $proyectoOrigenId = $validated['proyecto_origen_id'];
            $proyectoDestinoId = $validated['proyecto_destino_id'];
            $cantidad = $validated['cantidad'];

            // 1. Verificar stock en origen
            $invOrigen = Inventario::where('proyecto_id', $proyectoOrigenId)
                ->where('material_id', $materialId)
                ->first();

            if (!$invOrigen || $invOrigen->stock < $cantidad) {
                return response()->json(['message' => 'Stock insuficiente en el origen'], 422);
            }

            // 2. Determinar costo unitario (Promedio de compras en el origen, fallback a precio_costo global)
            $costoUnitario = CompraDetalle::whereHas('compra', function($q) use ($proyectoOrigenId) {
                    $q->where('proyecto_id', $proyectoOrigenId);
                })
                ->where('material_id', $materialId)
                ->avg('precio_unitario') ?? 0;

            if ($costoUnitario <= 0) {
                $costoUnitario = Material::where('id', $materialId)->value('precio_costo') ?? 0;
            }

            $totalCosto = $cantidad * $costoUnitario;

            // 3. Registrar Transferencia
            $transferencia = Transferencia::create([
                'material_id' => $materialId,
                'proyecto_origen_id' => $proyectoOrigenId,
                'proyecto_destino_id' => $proyectoDestinoId,
                'cantidad' => $cantidad,
                'fecha' => $validated['fecha'],
                'observaciones' => $validated['observaciones'] ?? null,
            ]);

            // 4. Actualizar Stocks
            $invOrigen->decrement('stock', $cantidad);

            $invDestino = Inventario::firstOrCreate(
                ['proyecto_id' => $proyectoDestinoId, 'material_id' => $materialId],
                ['stock' => 0]
            );
            $invDestino->increment('stock', $cantidad);

            // 5. Asiento Contable (Mover de un Inventario a otro en el catálogo)
            $material = Material::findOrFail($materialId);
            $proyectoOrigen = Proyecto::findOrFail($proyectoOrigenId);
            $proyectoDestino = Proyecto::findOrFail($proyectoDestinoId);
            $cuentaInventario = CatalogoCuenta::where('codigo', '1.1.02')->first();

            if ($cuentaInventario) {
                $detallesAsiento = [
                    [
                        'cuenta_id' => $cuentaInventario->id,
                        'debe' => $totalCosto,
                        'haber' => 0,
                        'centro_costo_id' => $proyectoDestinoId,
                    ],
                    [
                        'cuenta_id' => $cuentaInventario->id,
                        'debe' => 0,
                        'haber' => $totalCosto,
                        'centro_costo_id' => $proyectoOrigenId,
                    ]
                ];

                $glosa = "Transf: {$cantidad} {$material->unidad} de {$material->nombre} desde {$proyectoOrigen->nombre} a {$proyectoDestino->nombre}";

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
