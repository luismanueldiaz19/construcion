<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Compra;
use App\Models\CompraDetalle;
use App\Models\CatalogoCuenta;
use App\Services\AsientoService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CompraController extends Controller
{
    protected $asientoService;

    public function __construct(AsientoService $asientoService)
    {
        $this->asientoService = $asientoService;
    }

    public function index()
    {
        return Compra::with('proveedor', 'proyecto', 'detalles.material')->latest()->get();
    }

    public function show($id){
        return Compra::with('proveedor', 'proyecto', 'detalles.material')->findOrFail($id);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'proveedor_id' => 'required|exists:proveedores,id',
            'proyecto_id' => 'required|exists:proyectos,id',
            'fecha' => 'required|date',
            'tipo_compra' => 'required|in:Contado,Crédito',
            'items' => 'required|array|min:1',
            'items.*.material_id' => 'required|exists:materiales,id',
            'items.*.cantidad' => 'required|numeric|min:0.01',
            'items.*.precio_unitario' => 'required|numeric|min:0',
        ]);

        return DB::transaction(function () use ($validated) {
            $subtotal = 0;
            foreach ($validated['items'] as $item) {
                $subtotal += $item['cantidad'] * $item['precio_unitario'];
            }

            // Calculamos ITBIS (asumimos 18% para materiales)
            $itbis = $subtotal * 0.18;
            $total = $subtotal + $itbis;

            // 1. Crear Compra
            $compra = Compra::create([
                'proveedor_id' => $validated['proveedor_id'],
                'proyecto_id' => $validated['proyecto_id'],
                'fecha' => $validated['fecha'],
                'tipo_compra' => $validated['tipo_compra'],
                'subtotal' => $subtotal,
                'itbis' => $itbis,
                'total' => $total,
                'estado' => 'Pendiente',
            ]);

            // 2. Crear Detalles
            foreach ($validated['items'] as $item) {
                CompraDetalle::create([
                    'compra_id' => $compra->id,
                    'material_id' => $item['material_id'],
                    'cantidad' => $item['cantidad'],
                    'precio_unitario' => $item['precio_unitario'],
                    'subtotal' => $item['cantidad'] * $item['precio_unitario'],
                ]);
            }

            // 3. Lógica Contable (Asiento)
            $cuentaInventario = CatalogoCuenta::where('codigo', '1.1.02')->first();
            $cuentaItbisPagado = CatalogoCuenta::where('codigo', '1.1.03')->first();
            $cuentaContrapartida = ($validated['tipo_compra'] == 'Crédito') 
                ? CatalogoCuenta::where('codigo', '2.1.01')->first() 
                : CatalogoCuenta::where('codigo', '1.1.01.02')->first();

            $detallesAsiento = [
                [
                    'cuenta_id' => $cuentaInventario->id,
                    'debe' => $subtotal,
                    'haber' => 0,
                    'centro_costo_id' => $validated['proyecto_id']
                ],
                [
                    'cuenta_id' => $cuentaItbisPagado->id,
                    'debe' => $itbis,
                    'haber' => 0,
                ],
                [
                    'cuenta_id' => $cuentaContrapartida->id,
                    'debe' => 0,
                    'haber' => $total,
                ]
            ];

            $this->asientoService->registrarAsiento(
                $validated['fecha'],
                "Compra de materiales ({$validated['tipo_compra']}) - Proyecto: {$compra->proyecto->nombre}",
                $detallesAsiento,
                'Compra',
                $compra->id
            );

            return $compra->load('detalles.material', 'proveedor');
        });
    }
}
