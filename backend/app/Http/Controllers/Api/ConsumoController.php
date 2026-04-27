<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Consumo;
use App\Models\Inventario;
use App\Models\CompraDetalle;
use App\Models\CatalogoCuenta;
use App\Services\AsientoService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ConsumoController extends Controller
{
    protected $asientoService;

    public function __construct(AsientoService $asientoService)
    {
        $this->asientoService = $asientoService;
    }

    public function index(Request $request)
    {
        $query = Consumo::with(['proyecto', 'material', 'subpartida']);
        if ($request->has('proyecto_id')) {
            $query->where('proyecto_id', $request->proyecto_id);
        }
        return $query->latest()->get();
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'proyecto_id' => 'required|exists:proyectos,id',
            'material_id' => 'required|exists:materiales,id',
            'subpartida_id' => 'required|exists:subpartidas,id',
            'cantidad' => 'required|numeric|min:0.01',
            'fecha' => 'required|date',
        ]);

        return DB::transaction(function () use ($validated) {
            // 1. Verificar stock
            $inv = Inventario::where('proyecto_id', $validated['proyecto_id'])
                ->where('material_id', $validated['material_id'])
                ->first();

            if (!$inv || $inv->stock < $validated['cantidad']) {
                return response()->json(['message' => 'Stock insuficiente en el proyecto'], 422);
            }

            // 2. Determinar costo (Promedio de compras para este proyecto)
            $costoUnitario = CompraDetalle::whereHas('compra', function($q) use ($validated) {
                    $q->where('proyecto_id', $validated['proyecto_id']);
                })
                ->where('material_id', $validated['material_id'])
                ->avg('precio_unitario') ?? 0;

            $totalCosto = $validated['cantidad'] * $costoUnitario;

            // 3. Registrar Consumo
            $consumo = Consumo::create([
                'proyecto_id' => $validated['proyecto_id'],
                'material_id' => $validated['material_id'],
                'subpartida_id' => $validated['subpartida_id'],
                'cantidad' => $validated['cantidad'],
                'costo_unitario' => $costoUnitario,
                'total' => $totalCosto,
                'fecha' => $validated['fecha'],
            ]);

            // 4. Restar Stock
            $inv->decrement('stock', $validated['cantidad']);

            // 5. Asiento Contable (Mover de Inventario a Gasto)
            $consumo->load(['proyecto', 'material', 'subpartida']);
            
            $cuentaInventario = CatalogoCuenta::where('codigo', '1.1.02')->first();
            $cuentaCosto = CatalogoCuenta::where('codigo', '5.1.01')->first();

            $detallesAsiento = [
                [
                    'cuenta_id' => $cuentaCosto->id,
                    'debe' => $totalCosto,
                    'haber' => 0,
                    'centro_costo_id' => $validated['proyecto_id'],
                    'subpartida_id' => $validated['subpartida_id']
                ],
                [
                    'cuenta_id' => $cuentaInventario->id,
                    'debe' => 0,
                    'haber' => $totalCosto,
                    'centro_costo_id' => $validated['proyecto_id'],
                ]
            ];

            $glosa = "Consumo: {$consumo->cantidad} {$consumo->material->unidad} de {$consumo->material->nombre} - Partida: {$consumo->subpartida->nombre} - Proyecto: {$consumo->proyecto->nombre}";

            $this->asientoService->registrarAsiento(
                $validated['fecha'],
                $glosa,
                $detallesAsiento,
                'Consumo',
                $consumo->id
            );

            return $consumo;
        });
    }
}
