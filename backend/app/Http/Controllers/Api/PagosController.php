<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PagoCompra;
use App\Models\GastoProyecto;
use Illuminate\Http\Request;
use Barryvdh\DomPDF\Facade\Pdf;

class PagosController extends Controller
{
    public function index()
    {
        // Obtener todos los pagos de compras
        $pagosCompras = PagoCompra::with('cuentaPorPagar.proveedor', 'cuentaPorPagar.compra.proyecto')
            ->get()
            ->map(function($pago) {
                return [
                    'id' => $pago->id,
                    'tipo' => 'Compra',
                    'fecha' => $pago->fecha,
                    'monto' => $pago->monto,
                    'metodo_pago' => $pago->metodo_pago,
                    'referencia' => $pago->referencia,
                    'entidad' => $pago->cuentaPorPagar->proveedor->nombre ?? 'N/A',
                    'proyecto' => $pago->cuentaPorPagar->compra->proyecto->nombre ?? 'N/A',
                    'concepto' => "Pago Factura #" . ($pago->cuentaPorPagar->compra_id ?? ''),
                    'original' => $pago
                ];
            });

        // Obtener todos los gastos de proyectos (desembolsos)
        $gastosProyectos = GastoProyecto::with('proyecto', 'proveedor')
            ->get()
            ->map(function($gasto) {
                return [
                    'id' => $gasto->id,
                    'tipo' => 'Proyecto',
                    'fecha' => $gasto->fecha,
                    'monto' => $gasto->monto,
                    'metodo_pago' => $gasto->metodo_pago,
                    'referencia' => $gasto->descripcion,
                    'entidad' => $gasto->proveedor->nombre ?? 'N/A',
                    'proyecto' => $gasto->proyecto->nombre ?? 'N/A',
                    'concepto' => $gasto->tipo_gasto,
                    'original' => $gasto
                ];
            });

        return $pagosCompras->concat($gastosProyectos)->sortByDesc('fecha')->values();
    }

    public function imprimirRecibo($tipo, $id)
    {
        if ($tipo === 'Compra') {
            $pago = PagoCompra::with('cuentaPorPagar.proveedor', 'cuentaPorPagar.compra')->findOrFail($id);
            $data = [
                'id' => $pago->id,
                'fecha' => $pago->fecha,
                'entidad' => $pago->cuentaPorPagar->proveedor->nombre,
                'metodo' => $pago->metodo_pago,
                'referencia' => $pago->referencia,
                'monto' => $pago->monto,
                'subtitulo' => 'ORDEN DE COMPRA #' . $pago->cuentaPorPagar->compra_id,
                'detalles' => [
                    'Total Factura' => $pago->cuentaPorPagar->monto_total,
                    'BALANCE PENDIENTE' => $pago->cuentaPorPagar->saldo
                ]
            ];
        } else {
            $gasto = GastoProyecto::with('proyecto', 'proveedor')->findOrFail($id);
            $data = [
                'id' => $gasto->id,
                'fecha' => $gasto->fecha,
                'entidad' => $gasto->proyecto->nombre,
                'metodo' => $gasto->metodo_pago,
                'referencia' => $gasto->descripcion,
                'monto' => $gasto->monto,
                'subtitulo' => 'GASTO DE PROYECTO',
                'detalles' => [
                    'Tipo Gasto' => $gasto->tipo_gasto,
                    'Beneficiario' => $gasto->proveedor->nombre ?? 'N/A'
                ]
            ];
        }

        $pdf = Pdf::loadView('pdf.recibo_generico', compact('data'))
            ->setPaper([0, 0, 226.77, 500]);
        return $pdf->stream("recibo_{$tipo}_{$id}.pdf");
    }
}
