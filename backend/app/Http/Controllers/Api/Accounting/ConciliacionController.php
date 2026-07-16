<?php

namespace App\Http\Controllers\Api\Accounting;

use App\Http\Controllers\Controller;
use App\Models\AsientoDetalle;
use App\Models\CatalogoCuenta;
use App\Models\ConciliacionBancaria;
use App\Models\ConciliacionDetalle;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ConciliacionController extends Controller
{
    /**
     * Obtener lista de bancos (Cuentas contables de tipo Efectivo y Equivalentes)
     */
    public function getBancos()
    {
        // Los bancos reales se encuentran bajo la jerarquía de Efectivo y Caja (1.1.01) y son cuentas de detalle.
        $bancos = CatalogoCuenta::where('codigo', 'like', '1.1.01%')
                    ->where('es_detalle', true)
                    ->select('id', 'codigo', 'nombre')
                    ->get();
        return response()->json($bancos);
    }

    /**
     * Obtener movimientos de un banco en un mes y año específico
     */
    public function getMovimientos(Request $request)
    {
        $request->validate([
            'banco_id' => 'required|exists:catalogo_cuentas,id',
            'anio' => 'required|integer',
            'mes' => 'required|integer|min:1|max:12',
        ]);

        $bancoId = $request->banco_id;
        $anio = $request->anio;
        $mes = $request->mes;

        // Buscar si ya existe una conciliación guardada
        $conciliacion = ConciliacionBancaria::with('detalles')
            ->where('banco_id', $bancoId)
            ->where('anio', $anio)
            ->where('mes', $mes)
            ->first();

        $detallesConciliados = [];
        if ($conciliacion) {
            $detallesConciliados = $conciliacion->detalles->pluck('asiento_detalle_id')->toArray();
        }

        // Obtener el saldo inicial hasta el último día del mes anterior
        $inicioDeMes = \Carbon\Carbon::createFromDate($anio, $mes, 1)->startOfDay();
        
        $saldoInicialQuery = AsientoDetalle::join('asientos_contables', 'asiento_detalles.asiento_id', '=', 'asientos_contables.id')
            ->where('asiento_detalles.cuenta_id', $bancoId)
            ->where('asientos_contables.fecha', '<', $inicioDeMes)
            ->select(DB::raw('SUM(debe - haber) as total'))
            ->first();
            
        $saldoInicial = $saldoInicialQuery ? (double) $saldoInicialQuery->total : 0.0;

        // Obtener todos los movimientos contables de esta cuenta en el periodo
        $movimientos = AsientoDetalle::with(['cuenta', 'centro_costo'])
            ->join('asientos_contables', 'asiento_detalles.asiento_id', '=', 'asientos_contables.id')
            ->where('asiento_detalles.cuenta_id', $bancoId)
            ->whereYear('asientos_contables.fecha', $anio)
            ->whereMonth('asientos_contables.fecha', $mes)
            ->select('asiento_detalles.*', 'asientos_contables.fecha', 'asientos_contables.glosa', 'asientos_contables.referencia_tipo', 'asientos_contables.referencia_id')
            ->orderBy('asientos_contables.fecha', 'asc')
            ->get();

        // Mapear movimientos agregando el estado de conciliación
        $saldoSistema = $saldoInicial;
        $movimientosMapped = $movimientos->map(function ($mov) use ($detallesConciliados, &$saldoSistema) {
            $esConciliado = in_array($mov->id, $detallesConciliados);
            $monto = $mov->debe - $mov->haber;
            $saldoSistema += $monto;

            return [
                'id' => $mov->id,
                'fecha' => $mov->fecha,
                'glosa' => $mov->glosa,
                'debe' => $mov->debe,
                'haber' => $mov->haber,
                'monto' => $monto,
                'conciliado' => $esConciliado
            ];
        });

        return response()->json([
            'conciliacion' => $conciliacion,
            'saldo_inicial' => $saldoInicial,
            'saldo_sistema_calculado' => $saldoSistema,
            'movimientos' => $movimientosMapped
        ]);
    }

    /**
     * Guardar el resultado de la conciliación
     */
    public function saveConciliacion(Request $request)
    {
        $request->validate([
            'banco_id' => 'required|exists:catalogo_cuentas,id',
            'anio' => 'required|integer',
            'mes' => 'required|integer|min:1|max:12',
            'saldo_banco' => 'required|numeric',
            'saldo_sistema' => 'required|numeric',
            'movimientos_conciliados' => 'required|array'
        ]);

        DB::beginTransaction();
        try {
            $diferencia = $request->saldo_banco - $request->saldo_sistema;
            $estado = abs($diferencia) < 0.01 ? 'conciliado' : 'borrador';

            $conciliacion = ConciliacionBancaria::updateOrCreate(
                [
                    'banco_id' => $request->banco_id,
                    'anio' => $request->anio,
                    'mes' => $request->mes
                ],
                [
                    'saldo_banco' => $request->saldo_banco,
                    'saldo_sistema' => $request->saldo_sistema,
                    'diferencia' => $diferencia,
                    'estado' => $estado,
                    'conciliado_por' => auth()->id() ?? 1
                ]
            );

            // Eliminar detalles anteriores si es actualización
            $conciliacion->detalles()->delete();

            // Guardar nuevos detalles
            foreach ($request->movimientos_conciliados as $detalleId) {
                ConciliacionDetalle::create([
                    'conciliacion_id' => $conciliacion->id,
                    'asiento_detalle_id' => $detalleId,
                    'estado' => 'conciliado'
                ]);
            }

            DB::commit();

            return response()->json([
                'message' => 'Conciliación guardada exitosamente',
                'conciliacion' => $conciliacion
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Error al guardar', 'error' => $e->getMessage()], 500);
        }
    }

    /**
     * Generar PDF de la conciliación
     */
    public function generarPdf(Request $request)
    {
        $request->validate([
            'banco_id' => 'required|exists:catalogo_cuentas,id',
            'anio' => 'required|integer',
            'mes' => 'required|integer|min:1|max:12',
        ]);

        $banco = CatalogoCuenta::findOrFail($request->banco_id);
        
        $conciliacion = ConciliacionBancaria::with('detalles.asientoDetalle.asiento')
            ->where('banco_id', $request->banco_id)
            ->where('anio', $request->anio)
            ->where('mes', $request->mes)
            ->first();

        // Obtener todos los movimientos de ese mes
        $movimientosQuery = AsientoDetalle::with(['cuenta', 'asiento'])
            ->join('asientos_contables', 'asiento_detalles.asiento_id', '=', 'asientos_contables.id')
            ->where('asiento_detalles.cuenta_id', $request->banco_id)
            ->whereYear('asientos_contables.fecha', $request->anio)
            ->whereMonth('asientos_contables.fecha', $request->mes)
            ->select('asiento_detalles.*')
            ->orderBy('asientos_contables.fecha', 'asc')
            ->get();

        $detallesConciliados = $conciliacion ? $conciliacion->detalles->pluck('asiento_detalle_id')->toArray() : [];

        $saldoSistema = 0;
        $movimientos = $movimientosQuery->map(function ($mov) use ($detallesConciliados, &$saldoSistema) {
            $esConciliado = in_array($mov->id, $detallesConciliados);
            $monto = $mov->debe - $mov->haber;
            $saldoSistema += $monto;
            
            $mov->fecha = $mov->asiento->fecha ?? '';
            $mov->glosa = $mov->asiento->glosa ?? '';
            $mov->es_conciliado = $esConciliado;
            return $mov;
        });

        $data = [
            'banco' => $banco,
            'anio' => $request->anio,
            'mes' => $request->mes,
            'conciliacion' => $conciliacion,
            'movimientos' => $movimientos,
            'saldoSistema' => $saldoSistema
        ];

        $pdf = \Barryvdh\DomPDF\Facade\Pdf::loadView('contabilidad.conciliacion-pdf', $data);
        return $pdf->stream("Conciliacion_Banco_{$banco->codigo}_{$request->mes}_{$request->anio}.pdf");
    }
}
