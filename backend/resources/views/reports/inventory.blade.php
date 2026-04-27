<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Reporte de Inventario - {{ $proyecto->nombre }}</title>
    <style>
        body { font-family: 'Helvetica', sans-serif; font-size: 12px; color: #333; }
        .header { text-align: center; margin-bottom: 30px; border-bottom: 2px solid #2c3e50; padding-bottom: 10px; }
        .header h1 { margin: 0; color: #2c3e50; text-transform: uppercase; }
        .project-info { margin-bottom: 20px; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
        th { background-color: #2c3e50; color: white; padding: 8px; text-align: left; }
        td { border: 1px solid #ddd; padding: 8px; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .section-title { background-color: #ecf0f1; padding: 5px 10px; font-weight: bold; margin-bottom: 10px; border-left: 5px solid #2c3e50; }
        .total-row { font-weight: bold; background-color: #d5dbdb !important; }
        .text-right { text-align: right; }
        .text-center { text-align: center; }
        .badge-entrada { color: #27ae60; font-weight: bold; }
        .badge-salida { color: #c0392b; font-weight: bold; }
        .footer { position: fixed; bottom: 0; width: 100%; text-align: center; font-size: 10px; color: #7f8c8d; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Reporte de Inventario</h1>
        <div>Emitido el: {{ now()->format('d/m/Y H:i') }}</div>
    </div>

    <div class="project-info">
        <strong>PROYECTO:</strong> {{ $proyecto->nombre }}<br>
        <strong>UBICACIÓN:</strong> {{ $proyecto->ubicacion }}
    </div>

    @if($tipo == 'balance' || $tipo == 'completo')
    <div class="section-title">BALANCE DE STOCK ACTUAL</div>
    <table>
        <thead>
            <tr>
                <th>Material</th>
                <th>Unidad</th>
                <th class="text-center">Entradas</th>
                <th class="text-center">Salidas</th>
                <th class="text-center">Stock</th>
                <th class="text-right">Últ. Costo</th>
                <th class="text-right">Inversión</th>
            </tr>
        </thead>
        <tbody>
            @php $totalInversion = 0; @endphp
            @foreach($balance as $item)
                @php 
                    $inv = $item['stock'] * $item['ultimo_costo'];
                    $totalInversion += $inv;
                @endphp
                <tr>
                    <td>{{ $item['material'] }}</td>
                    <td>{{ $item['unidad'] }}</td>
                    <td class="text-center">{{ number_format($item['entradas'], 2) }}</td>
                    <td class="text-center">{{ number_format($item['salidas'], 2) }}</td>
                    <td class="text-center" style="font-weight: bold; color: #2980b9;">{{ number_format($item['stock'], 2) }}</td>
                    <td class="text-right">RD$ {{ number_format($item['ultimo_costo'], 2) }}</td>
                    <td class="text-right">RD$ {{ number_format($inv, 2) }}</td>
                </tr>
            @endforeach
        </tbody>
        <tfoot>
            <tr class="total-row">
                <td colspan="6" class="text-right">TOTAL INVERSIÓN GENERAL</td>
                <td class="text-right">RD$ {{ number_format($totalInversion, 2) }}</td>
            </tr>
        </tfoot>
    </table>
    @endif

    @if($tipo == 'movimientos' || $tipo == 'completo')
    <div style="page-break-before: always;"></div>
    <div class="section-title">HISTORIAL DE MOVIMIENTOS</div>
    <table>
        <thead>
            <tr>
                <th>Tipo</th>
                <th>Fecha</th>
                <th>Referencia</th>
                <th>Material</th>
                <th class="text-center">Cant.</th>
                <th class="text-right">Costo</th>
                <th class="text-right">Total</th>
            </tr>
        </thead>
        <tbody>
            @php $totalAcumulado = 0; @endphp
            @foreach($movimientos as $mov)
                @php 
                    $t = $mov['cantidad'] * $mov['costo'];
                    $totalAcumulado += $t;
                @endphp
                <tr>
                    <td class="{{ $mov['tipo'] == 'Entrada' ? 'badge-entrada' : 'badge-salida' }}">
                        {{ $mov['tipo'] }}
                    </td>
                    <td>{{ $mov['fecha'] }}</td>
                    <td>{{ $mov['referencia'] }}</td>
                    <td>{{ $mov['material'] }}</td>
                    <td class="text-center">{{ ($mov['tipo'] == 'Entrada' ? '+' : '-') . number_format($mov['cantidad'], 2) }}</td>
                    <td class="text-right">RD$ {{ number_format($mov['costo'], 2) }}</td>
                    <td class="text-right">RD$ {{ number_format($t, 2) }}</td>
                </tr>
            @endforeach
        </tbody>
        <tfoot>
            <tr class="total-row">
                <td colspan="6" class="text-right">COSTO TOTAL ACUMULADO</td>
                <td class="text-right">RD$ {{ number_format($totalAcumulado, 2) }}</td>
            </tr>
        </tfoot>
    </table>
    @endif

    <div class="footer">
        Generado automáticamente por el Sistema de Control de Construcción
    </div>
</body>
</html>
