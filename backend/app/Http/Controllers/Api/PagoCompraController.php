<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CuentaPorPagar;
use App\Models\PagoCompra;
use App\Models\CatalogoCuenta;
use App\Services\AsientoService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PagoCompraController extends Controller
{
    protected $asientoService;

    public function __construct(AsientoService $asientoService)
    {
        $this->asientoService = $asientoService;
    }

    public function index()
    {
        return CuentaPorPagar::with('proveedor', 'compra', 'pagos')
            ->where('saldo', '>', 0)
            ->latest()
            ->get();
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'cuenta_por_pagar_id' => 'required|exists:cuentas_por_pagar,id',
            'monto' => 'required|numeric|min:0.01',
            'fecha' => 'required|date',
            'metodo_pago' => 'required|string',
            'referencia' => 'nullable|string',
            'notas' => 'nullable|string',
        ]);

        return DB::transaction(function () use ($validated) {
            $cxp = CuentaPorPagar::with('proveedor')->findOrFail($validated['cuenta_por_pagar_id']);

            if ($validated['monto'] > $cxp->saldo) {
                return response()->json(['error' => 'El monto excede el saldo pendiente'], 422);
            }

            // 1. Crear el Pago
            $pago = PagoCompra::create($validated);

            // 2. Actualizar CXP
            $cxp->monto_pagado += $validated['monto'];
            $cxp->saldo -= $validated['monto'];
            $cxp->estado = ($cxp->saldo == 0) ? 'Pagado' : 'Parcial';
            $cxp->save();

            // 3. Asiento Contable
            $cuentaCXP = CatalogoCuenta::where('codigo', '2.1.01')->first();
            $cuentaBanco = CatalogoCuenta::where('codigo', '1.1.01.02.01')->first();

            if ($cuentaCXP && $cuentaBanco) {
                $detallesAsiento = [
                    [
                        'cuenta_id' => $cuentaCXP->id,
                        'debe' => $validated['monto'],
                        'haber' => 0,
                    ],
                    [
                        'cuenta_id' => $cuentaBanco->id,
                        'debe' => 0,
                        'haber' => $validated['monto'],
                    ]
                ];

                $this->asientoService->registrarAsiento(
                    $validated['fecha'],
                    "Pago/Abono a Proveedor - Compra #{$cxp->compra_id} - Proveedor: {$cxp->proveedor->nombre}",
                    $detallesAsiento,
                    'PagoCompra',
                    $pago->id
                );
            }

            return response()->json($pago->load('cuentaPorPagar'));
        });
    }

    public function imprimirRecibo($id)
    {
        $pago = PagoCompra::with('cuentaPorPagar.proveedor', 'cuentaPorPagar.compra')->findOrFail($id);
        $pdf = \Barryvdh\DomPDF\Facade\Pdf::loadView('pdf.recibo_pago', compact('pago'))
            ->setPaper([0, 0, 226.77, 620])
            ->setOptions(['isHtml5ParserEnabled' => true, 'isRemoteEnabled' => false, 'dpi' => 96]);
        return $pdf->stream("recibo_pago_{$pago->id}.pdf");
    }
}
