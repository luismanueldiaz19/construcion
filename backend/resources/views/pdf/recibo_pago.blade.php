<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Recibo de Pago</title>
    <style>
        body {
            font-family: 'Courier', monospace;
            font-size: 12px;
            width: 80mm; /* Tirilla standard */
            margin: 0;
            padding: 10px;
        }
        .header {
            text-align: center;
            margin-bottom: 15px;
        }
        .header h2 {
            margin: 5px 0;
        }
        .divider {
            border-bottom: 1px dashed #000;
            margin: 10px 0;
        }
        .row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 5px;
        }
        .footer {
            text-align: center;
            margin-top: 20px;
            font-size: 10px;
        }
        .bold {
            font-weight: bold;
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        td {
            padding: 2px 0;
        }
        .text-right {
            text-align: right;
        }
    </style>
</head>
<body>
    <div class="header">
        <h2>NEO PROJECT S.R.L</h2>
        <p>Recibo de Pago No: #{{ $pago->id }}</p>
        <p>Fecha: {{ \Carbon\Carbon::parse($pago->fecha)->format('d/MM/Y') }}</p>
    </div>

    <div class="divider"></div>

    <table>
        <tr>
            <td class="bold">Proveedor:</td>
            <td>{{ $pago->cuentaPorPagar->proveedor->nombre }}</td>
        </tr>
        <tr>
            <td class="bold">Compra ID:</td>
            <td>#{{ $pago->cuentaPorPagar->compra_id }}</td>
        </tr>
        <tr>
            <td class="bold">Método:</td>
            <td>{{ $pago->metodo_pago }}</td>
        </tr>
        @if($pago->referencia)
        <tr>
            <td class="bold">Referencia:</td>
            <td>{{ $pago->referencia }}</td>
        </tr>
        @endif
    </table>

    <div class="divider"></div>

    <table>
        <tr>
            <td class="bold">MONTO PAGADO:</td>
            <td class="text-right bold">${{ number_format($pago->monto, 2) }}</td>
        </tr>
        <tr>
            <td>Total Factura:</td>
            <td class="text-right">${{ number_format($pago->cuentaPorPagar->monto_total, 2) }}</td>
        </tr>
        <tr class="bold">
            <td>BALANCE PENDIENTE:</td>
            <td class="text-right">${{ number_format($pago->cuentaPorPagar->saldo, 2) }}</td>
        </tr>
    </table>

    <div class="divider"></div>

    <div class="footer">
        <p>*** Gracias por su Pago ***</p>
        <p>Generado el {{ date('d/m/Y H:i:s') }}</p>
    </div>
</body>
</html>
