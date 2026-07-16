<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Conciliación Bancaria</title>
    <style>
        body { font-family: sans-serif; font-size: 12px; }
        .header { text-align: center; margin-bottom: 20px; }
        .title { font-size: 18px; font-weight: bold; }
        .subtitle { font-size: 14px; color: #555; }
        .summary-box { border: 1px solid #ccc; padding: 10px; margin-bottom: 20px; background-color: #f9f9f9; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 6px; text-align: left; }
        th { background-color: #f2f2f2; }
        .text-right { text-align: right; }
        .text-center { text-align: center; }
        .status-badge { padding: 3px 6px; border-radius: 4px; font-size: 10px; font-weight: bold; }
        .status-conciliado { background-color: #d4edda; color: #155724; }
        .status-pendiente { background-color: #f8d7da; color: #721c24; }
    </style>
</head>
<body>
    <div class="header">
        <div class="title">REPORTE DE CONCILIACIÓN BANCARIA</div>
        <div class="subtitle">Mes: {{ $mes }} / Año: {{ $anio }}</div>
    </div>

    <div class="summary-box">
        <p><strong>Banco:</strong> {{ $banco->codigo }} - {{ $banco->nombre }}</p>
        <table style="border: none; margin-bottom: 0;">
            <tr>
                <td style="border: none;"><strong>Saldo del Sistema:</strong></td>
                <td style="border: none;" class="text-right">${{ $conciliacion ? number_format($conciliacion->saldo_sistema, 2) : number_format($saldoSistema, 2) }}</td>
            </tr>
            <tr>
                <td style="border: none;"><strong>Saldo Estado de Cuenta (Banco):</strong></td>
                <td style="border: none;" class="text-right">
                    ${{ $conciliacion ? number_format($conciliacion->saldo_banco, 2) : '0.00' }}
                </td>
            </tr>
            <tr>
                <td style="border: none;"><strong>Diferencia:</strong></td>
                <td style="border: none;" class="text-right">
                    ${{ $conciliacion ? number_format($conciliacion->saldo_banco - $conciliacion->saldo_sistema, 2) : number_format(-$saldoSistema, 2) }}
                </td>
            </tr>
            <tr>
                <td style="border: none;"><strong>Estado de la Conciliación:</strong></td>
                <td style="border: none;" class="text-right">
                    @if($conciliacion && $conciliacion->estado === 'conciliado')
                        <span style="color: green; font-weight: bold;">CUADRADO PERFECTO</span>
                    @else
                        <span style="color: red; font-weight: bold;">NO CONCILIADO / BORRADOR</span>
                    @endif
                </td>
            </tr>
        </table>
    </div>

    <h4>Detalle de Movimientos en el Periodo</h4>
    <table>
        <thead>
            <tr>
                <th>Fecha</th>
                <th>Concepto / Glosa</th>
                <th class="text-right">Ingreso (Debe)</th>
                <th class="text-right">Salida (Haber)</th>
                <th class="text-center">Estado</th>
            </tr>
        </thead>
        <tbody>
            @foreach($movimientos as $mov)
            <tr>
                <td>{{ \Carbon\Carbon::parse($mov->fecha)->format('d/m/Y') }}</td>
                <td>{{ $mov->glosa }}</td>
                <td class="text-right">${{ number_format($mov->debe, 2) }}</td>
                <td class="text-right">${{ number_format($mov->haber, 2) }}</td>
                <td class="text-center">
                    @if($mov->es_conciliado)
                        <span class="status-badge status-conciliado">CONCILIADO</span>
                    @else
                        <span class="status-badge status-pendiente">PENDIENTE</span>
                    @endif
                </td>
            </tr>
            @endforeach
            @if(count($movimientos) === 0)
            <tr>
                <td colspan="5" class="text-center">No hay movimientos en este periodo.</td>
            </tr>
            @endif
        </tbody>
    </table>

    <div style="margin-top: 50px; width: 100%;">
        <table style="border: none; width: 100%;">
            <tr style="border: none;">
                <td style="border: none; text-align: center; width: 50%;">
                    ____________________________________<br>
                    <strong>Elaborado por</strong><br>
                    (Contabilidad)
                </td>
                <td style="border: none; text-align: center; width: 50%;">
                    ____________________________________<br>
                    <strong>Revisado por</strong><br>
                    (Gerencia/Auditoría)
                </td>
            </tr>
        </table>
    </div>
</body>
</html>
