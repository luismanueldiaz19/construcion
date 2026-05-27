<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Ticket de Compra</title>
    <style>
        body {
            font-family: 'Courier', monospace;
            font-size: 10px;
            width: 100%;
            margin: 0;
            padding: 5px;
        }
        .header {
            text-align: center;
            margin-bottom: 10px;
        }
        .header h2 {
            margin: 5px 0;
            font-size: 16px;
        }
        .divider {
            border-bottom: 1px dashed #000;
            margin: 8px 0;
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        .bold {
            font-weight: bold;
        }
        .text-right {
            text-align: right;
        }
        .footer {
            text-align: center;
            margin-top: 15px;
            font-size: 9px;
        }
        .items-table td {
            padding: 4px 0;
        }
    </style>
</head>
<body>
    <div class="header">
        <h2>NEO PROJECT S.R.L</h2>
        <p>ORDEN DE COMPRA #{{ $compra->id }}</p>
        <p>Fecha: {{ \Carbon\Carbon::parse($compra->fecha)->format('d/m/Y') }}</p>
    </div>

    <div class="divider"></div>

    <table>
        <tr>
            <td class="bold">Proveedor:</td>
            <td>{{ $compra->proveedor->nombre }}</td>
        </tr>
        <tr>
            <td class="bold">Proyecto:</td>
            <td>{{ $compra->proyecto->nombre }}</td>
        </tr>
        <tr>
            <td class="bold">Orden #:</td>
            <td>{{ $compra->orden ?? 'N/A' }}</td>
        </tr>
        <tr>
            <td class="bold">Código Ref:</td>
            <td>{{ $compra->codigo ?? 'N/A' }}</td>
        </tr>
        <tr>
            <td class="bold">Comprobante:</td>
            <td>{{ $compra->comprobante }}</td>
        </tr>
        <tr>
            <td class="bold">Tipo:</td>
            <td>{{ $compra->tipo_compra }}</td>
        </tr>
        @if($compra->tipo_compra == 'Crédito')
        <tr>
            <td class="bold">Vence:</td>
            <td>{{ $compra->fecha_vencimiento ? \Carbon\Carbon::parse($compra->fecha_vencimiento)->format('d/m/Y') : 'N/A' }}</td>
        </tr>
        @endif
    </table>

    <div class="divider"></div>

    <table class="items-table">
        <thead>
            <tr class="bold">
                <td style="width: 15%">Cant.</td>
                <td style="width: 45%">Descripción</td>
                <td class="text-right" style="width: 20%">Precio</td>
                <td class="text-right" style="width: 20%">Total</td>
            </tr>
        </thead>
        <tbody>
            @foreach($compra->detalles as $detalle)
            <tr>
                <td>{{ number_format($detalle->cantidad, 2) }}</td>
                <td>{{ $detalle->material->nombre }}</td>
                <td class="text-right">${{ number_format($detalle->precio_unitario, 2) }}</td>
                <td class="text-right">${{ number_format($detalle->subtotal, 2) }}</td>
            </tr>
            @endforeach
        </tbody>
    </table>

    <div class="divider"></div>

    <table>
        <tr>
            <td>Subtotal:</td>
            <td class="text-right">${{ number_format($compra->subtotal, 2) }}</td>
        </tr>
        <tr>
            <td>ITBIS (18%):</td>
            <td class="text-right">${{ number_format($compra->itbis, 2) }}</td>
        </tr>
        <tr class="bold">
            <td style="font-size: 13px;">TOTAL RD$:</td>
            <td class="text-right" style="font-size: 13px;">${{ number_format($compra->total, 2) }}</td>
        </tr>
    </table>

    <div class="divider"></div>

    @if($compra->nota)
    <div style="margin: 10px 0;">
        <span class="bold">Notas:</span><br>
        {{ $compra->nota }}
    </div>
    <div class="divider"></div>
    @endif

    <div class="footer">
        <p>Generado por Sistema ERP</p>
        <p>{{ date('d/m/Y H:i:s') }}</p>
    </div>
</body>
</html>
