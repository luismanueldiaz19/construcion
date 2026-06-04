<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PagoCliente;
use App\Models\CatalogoCuenta;
use App\Services\AsientoService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PagoClienteController extends Controller
{
    protected $asientoService;

    public function __construct(AsientoService $asientoService)
    {
        $this->asientoService = $asientoService;
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'proyecto_id' => 'required|exists:proyectos,id',
            'fecha' => 'required|date',
            'monto' => 'required|numeric|min:0.01',
            'metodo_pago' => 'required|string',
            'banco_id' => 'nullable|exists:catalogo_cuentas,id',
            'comentario' => 'nullable|string',
        ]);

        return DB::transaction(function () use ($validated) {
            $proyecto = \App\Models\Proyecto::withSum('pagos', 'monto')->findOrFail($validated['proyecto_id']);
            
            $totalContrato = $proyecto->presupuesto_estimado 
                           + ($proyecto->itbis ?? 0)
                           + ($proyecto->transporte ?? 0)
                           + ($proyecto->supervision_tecnica ?? 0)
                           + ($proyecto->otros_costos ?? 0);
            $totalPagado = $proyecto->pagos_sum_monto ?? 0;
            $saldoPendiente = $totalContrato - $totalPagado;

            if ($validated['monto'] > ($saldoPendiente + 0.05)) { // Allow tiny margin for rounding
                return response()->json([
                    'error' => 'El monto excede el saldo pendiente del contrato.',
                    'saldo_pendiente' => $saldoPendiente
                ], 422);
            }
            
            // 1. Determinar cuentas
            $cuentaBancoId = $validated['banco_id'] ?? CatalogoCuenta::where('codigo', '1.1.01.02.01')->first()->id;
            $cuentaIngreso = CatalogoCuenta::where('codigo', '4.1.01')->first();
            $cuentaItbis = CatalogoCuenta::where('codigo', '2.1.03')->first();

            // 2. Calcular desglose de ITBIS proporcional
            // Si el proyecto tiene ITBIS, lo extraemos del pago de forma proporcional al total
            $totalProyecto = $totalContrato;
            $itbisTotal = $proyecto->itbis;
            
            $montoItbis = 0;
            if ($totalProyecto > 0 && $itbisTotal > 0) {
                $montoItbis = ($validated['monto'] * $itbisTotal) / $totalProyecto;
            }
            $montoNeto = $validated['monto'] - $montoItbis;

            $pago = PagoCliente::create([
                'proyecto_id' => $validated['proyecto_id'],
                'fecha' => $validated['fecha'],
                'monto' => $validated['monto'],
                'metodo_pago' => $validated['metodo_pago'],
                'cuenta_contable_id' => $cuentaBancoId,
            ]);

            // 3. Registrar Asiento Desglosado
            $detalles = [
                [
                    'cuenta_id' => $cuentaBancoId,
                    'debe' => $validated['monto'],
                    'haber' => 0,
                ],
                [
                    'cuenta_id' => $cuentaIngreso->id,
                    'debe' => 0,
                    'haber' => $montoNeto,
                    'centro_costo_id' => $validated['proyecto_id']
                ]
            ];

            if ($montoItbis > 0 && $cuentaItbis) {
                $detalles[] = [
                    'cuenta_id' => $cuentaItbis->id,
                    'debe' => 0,
                    'haber' => $montoItbis,
                ];
            }

            $this->asientoService->registrarAsiento(
                $validated['fecha'],
                "Pago recibido - Proyecto: {$proyecto->nombre} - Desglose ITBIS: " . number_format($montoItbis, 2),
                $detalles,
                'Ingreso',
                $pago->id
            );

            return $pago;
        });
    }
}
