<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Reporte de Costos Partida - Neo Project</title>
    <style>
        body { font-family: Arial, sans-serif; font-size: 11px; color: #333; margin: 0; padding: 0; }
        .header { width: 100%; border-bottom: 2px solid #003366; padding-bottom: 10px; margin-bottom: 20px; }
        .company-name { font-size: 20px; font-weight: bold; color: #003366; }
        .report-title { text-align: right; font-size: 16px; color: #555; }
        .partida-info { background-color: #f9f9f9; padding: 15px; border: 1px solid #ddd; border-radius: 5px; margin-bottom: 20px; }
        .partida-info h2 { margin-top: 0; color: #003366; border-bottom: 1px solid #eee; padding-bottom: 5px; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
        th { background-color: #003366; color: white; padding: 8px; text-align: left; }
        td { padding: 8px; border-bottom: 1px solid #ddd; }
        .text-right { text-align: right; }
        .section-title { font-size: 14px; font-weight: bold; color: #003366; margin-bottom: 10px; border-left: 4px solid #003366; padding-left: 10px; }
        .summary-box { width: 100%; padding: 15px; background-color: #003366; color: #fff; margin-top: 20px; }
        .summary-box table { margin-bottom: 0; color: white; }
        .summary-box td { border: none; padding: 5px; }
        .budget-vs-real { font-size: 16px; font-weight: bold; }
    </style>
</head>
<body>
    <div class="header">
        <table style="width: 100%; border: none;">
            <tr>
                <td style="border: none;">
                    <img src="{{ public_path('images/logo.png') }}" style="max-height: 50px;">
                    <div>Análisis de Costos Reales por Partida</div>
                </td>
                <td style="border: none;" class="text-right">
                    <div>Fecha: {{ date('d/m/Y H:i') }}</div>
                </td>
            </tr>
        </table>
    </div>

    <div class="partida-info">
        <h2>Partida: {{ $partida->descripcion }}</h2>
        <table style="width: 100%; border: none;">
            <tr>
                <td style="border: none; padding: 2px;"><strong>Proyecto:</strong> {{ $partida->proyecto->nombre }}</td>
                <td style="border: none; padding: 2px;" class="text-right"><strong>Presupuesto Original:</strong> ${{ number_format($partida->subpartidas->sum('total_presupuestado'), 2) }}</td>
            </tr>
        </table>
    </div>

    <!-- Sección de Materiales (Inventario) -->
    <div class="section-title">DETALLE DE CONSUMO DE MATERIALES (INVENTARIO)</div>
    @if(count($consumos) > 0)
    <table>
        <thead>
            <tr>
                <th>Fecha</th>
                <th>Subpartida</th>
                <th>Material</th>
                <th class="text-right">Cantidad</th>
                <th class="text-right">Costo Unit.</th>
                <th class="text-right">Total</th>
            </tr>
        </thead>
        <tbody>
            @foreach($consumos as $c)
            <tr>
                <td>{{ \Carbon\Carbon::parse($c->fecha)->format('d/m/Y') }}</td>
                <td>{{ $c->subpartida->descripcion }}</td>
                <td>{{ $c->material->nombre }}</td>
                <td class="text-right">{{ number_format($c->cantidad, 2) }} {{ $c->material->unidad }}</td>
                <td class="text-right">${{ number_format($c->costo_unitario, 2) }}</td>
                <td class="text-right">${{ number_format($c->total, 2) }}</td>
            </tr>
            @endforeach
        </tbody>
        <tfoot>
            <tr>
                <td colspan="5" class="text-right"><strong>Subtotal Materiales:</strong></td>
                <td class="text-right"><strong>${{ number_format($totalConsumos, 2) }}</strong></td>
            </tr>
        </tfoot>
    </table>
    @else
    <p>No hay consumos de materiales registrados para esta partida.</p>
    @endif

    <!-- Sección de Gastos (Pagos) -->
    <div class="section-title">DETALLE DE GASTOS DIRECTOS (PAGOS / MANO DE OBRA)</div>
    @if(count($gastos) > 0)
    <table>
        <thead>
            <tr>
                <th>Fecha</th>
                <th>Subpartida</th>
                <th>Beneficiario</th>
                <th>Descripción</th>
                <th class="text-right">Monto</th>
            </tr>
        </thead>
        <tbody>
            @foreach($gastos as $g)
            <tr>
                <td>{{ \Carbon\Carbon::parse($g->fecha)->format('d/m/Y') }}</td>
                <td>{{ $g->subpartida->descripcion }}</td>
                <td>{{ $g->proveedor->nombre ?? 'N/A' }}</td>
                <td>{{ $g->descripcion }}</td>
                <td class="text-right">${{ number_format($g->monto, 2) }}</td>
            </tr>
            @endforeach
        </tbody>
        <tfoot>
            <tr>
                <td colspan="4" class="text-right"><strong>Subtotal Gastos:</strong></td>
                <td class="text-right"><strong>${{ number_format($totalGastos, 2) }}</strong></td>
            </tr>
        </tfoot>
    </table>
    @else
    <p>No hay gastos directos registrados para esta partida.</p>
    @endif

    <!-- Resumen Final -->
    <div class="summary-box">
        <table style="width: 100%;">
            <tr>
                <td class="budget-vs-real">RESUMEN DE COSTO REAL</td>
                <td class="text-right budget-vs-real">${{ number_format($totalReal, 2) }}</td>
            </tr>
            <tr>
                <td>Presupuesto Estimado:</td>
                <td class="text-right">${{ number_format($partida->subpartidas->sum('total_presupuestado'), 2) }}</td>
            </tr>
            <tr>
                <td style="border-top: 1px solid white;">Diferencia (Ahorro/Exceso):</td>
                @php
                    $presupuesto = $partida->subpartidas->sum('total_presupuestado');
                    $dif = $presupuesto - $totalReal;
                @endphp
                <td class="text-right" style="border-top: 1px solid white; color: {{ $dif >= 0 ? '#4caf50' : '#ff5252' }};">
                    ${{ number_format($dif, 2) }} ({{ $dif >= 0 ? 'AHORRO' : 'EXCESO' }})
                </td>
            </tr>
        </table>
    </div>
</body>
</html>
