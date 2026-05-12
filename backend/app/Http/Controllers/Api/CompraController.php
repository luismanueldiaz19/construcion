<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Compra;
use App\Models\CompraDetalle;
use App\Models\CatalogoCuenta;
use App\Models\CuentaPorPagar;
use App\Models\PagoCompra;
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

    public function pendientes()
    {
        return Compra::with('proveedor', 'proyecto', 'detalles.material')
            ->where('estado', '!=', 'Recibido')
            ->latest()
            ->get();
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
            'fecha_vencimiento' => 'nullable|date',
            'tipo_compra' => 'required|in:Contado,Crédito',
            'orden' => 'nullable|string',
            'codigo' => 'nullable|string',
            'comprobante' => 'nullable|string|unique:compras,comprobante',
            'nota' => 'nullable|string',
            'items' => 'required|array|min:1',
            'items.*.material_id' => 'required|exists:materiales,id',
            'items.*.cantidad' => 'required|numeric|min:0.01',
            'items.*.precio_unitario' => 'required|numeric|min:0',
        ]);

        return DB::transaction(function () use ($validated) {
            $total = 0;
            foreach ($validated['items'] as $item) {
                $total += $item['cantidad'] * $item['precio_unitario'];
            }

            // Calculamos Subtotal e ITBIS (asumiendo que el precio ya tiene el 18%)
            $subtotal = $total / 1.18;
            $itbis = $total - $subtotal;

            // Generar comprobante único si no se envió uno
            $comprobante = $validated['comprobante'];
            if (empty($comprobante)) {
                $comprobante = 'CP-' . date('Ymd') . '-' . strtoupper(bin2hex(random_bytes(2)));
            }

            // 1. Crear Compra
            $compra = Compra::create([
                'proveedor_id' => $validated['proveedor_id'],
                'proyecto_id' => $validated['proyecto_id'],
                'fecha' => $validated['fecha'],
                'tipo_compra' => $validated['tipo_compra'],
                'subtotal' => $subtotal,
                'itbis' => $itbis,
                'total' => $total,
                'fecha_vencimiento' => $validated['fecha_vencimiento'] ?? null,
                'estado' => 'Pendiente',
                'orden' => $validated['orden'] ?? null,
                'codigo' => $validated['codigo'] ?? null,
                'comprobante' => $comprobante,
                'nota' => $validated['nota'] ?? null,
            ]);

            // 2. Crear Detalles
            foreach ($validated['items'] as $item) {
                $itemNeto = $item['precio_unitario'] / 1.18;
                CompraDetalle::create([
                    'compra_id' => $compra->id,
                    'material_id' => $item['material_id'],
                    'cantidad' => $item['cantidad'],
                    'precio_unitario' => $itemNeto,
                    'subtotal' => $itemNeto * $item['cantidad'],
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

            $this->gestionarCXP($compra);

            return $compra->load('detalles.material', 'proveedor');
        });
    }

    /**
     * Gestiona la creación de la Cuenta por Pagar y el pago inicial si es al contado.
     */
    private function gestionarCXP(Compra $compra)  {
        $cxp = CuentaPorPagar::create([
            'compra_id' => $compra->id,
            'proveedor_id' => $compra->proveedor_id,
            'monto_total' => $compra->total,
            'monto_pagado' => 0,
            'saldo' => $compra->total,
            'fecha_vencimiento' => $compra->fecha_vencimiento,
            'estado' => 'Pendiente',
        ]);

        if ($compra->tipo_compra == 'Contado') {
            PagoCompra::create([
                'cuenta_por_pagar_id' => $cxp->id,
                'fecha' => $compra->fecha,
                'monto' => $compra->total,
                'metodo_pago' => 'Efectivo/Banco',
                'notas' => 'Pago automático por compra al contado',
            ]);

            $cxp->update([
                'monto_pagado' => $compra->total,
                'saldo' => 0,
                'estado' => 'Pagado',
            ]);

            $compra->update(['estado' => 'Pagado']);
        }
    }

    public function imprimirTicket($id)
    {
        $compra = Compra::with('proveedor', 'proyecto', 'detalles.material')->findOrFail($id);
        $pdf = \Barryvdh\DomPDF\Facade\Pdf::loadView('pdf.compra_ticket', compact('compra'))
            ->setPaper([0, 0, 226.77, 600]);
        return $pdf->stream("ticket_compra_{$compra->id}.pdf");
    }
}
