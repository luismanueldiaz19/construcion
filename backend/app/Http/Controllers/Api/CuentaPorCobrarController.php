<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Proyecto;
use Illuminate\Http\Request;

class CuentaPorCobrarController extends Controller
{
    public function index()
    {
        return Proyecto::withSum('pagos', 'monto')
            ->with(['pagos.cuentaContable'])
            ->where('estado', 'Activo')
            ->get()
            ->map(function($proyecto) {
                $total = $proyecto->presupuesto_estimado 
                       + ($proyecto->itbis ?? 0)
                       + ($proyecto->transporte ?? 0)
                       + ($proyecto->supervision_tecnica ?? 0)
                       + ($proyecto->otros_costos ?? 0);
                $pagado = $proyecto->pagos_sum_monto ?? 0;
                $saldo = $total - $pagado;
                
                return [
                    'id' => $proyecto->id,
                    'proyecto' => $proyecto->nombre,
                    'cliente' => $proyecto->cliente,
                    'monto_total' => $total,
                    'monto_pagado' => $pagado,
                    'saldo' => $saldo,
                    'estado' => ($saldo <= 0) ? 'Saldado' : 'Pendiente',
                    'fecha_inicio' => $proyecto->fecha_inicio,
                    'pagos' => $proyecto->pagos->map(function($pago) {
                        return [
                            'id' => $pago->id,
                            'fecha' => $pago->fecha,
                            'monto' => $pago->monto,
                            'metodo_pago' => $pago->metodo_pago,
                            'banco' => $pago->cuentaContable ? $pago->cuentaContable->nombre : 'N/A',
                        ];
                    })->toArray(),
                ];
            });
    }
}
