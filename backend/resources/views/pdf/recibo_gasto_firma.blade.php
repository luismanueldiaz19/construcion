<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Recibo de Gasto #{{ str_pad($gasto->id, 6, '0', STR_PAD_LEFT) }}</title>
    <style>
        body {
            font-family: 'Helvetica', 'Arial', sans-serif;
            font-size: 14px;
            color: #333;
            margin: 0;
            padding: 20px;
        }
        .header {
            text-align: center;
            border-bottom: 2px solid #1a1a1a;
            padding-bottom: 15px;
            margin-bottom: 20px;
        }
        .company-name {
            font-size: 24px;
            font-weight: bold;
            color: #003366;
            margin-bottom: 5px;
        }
        .receipt-title {
            font-size: 18px;
            font-weight: bold;
            text-transform: uppercase;
            letter-spacing: 2px;
            color: #555;
        }
        .receipt-details {
            text-align: right;
            font-size: 12px;
            margin-top: -40px;
            margin-bottom: 20px;
        }
        .info-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 25px;
        }
        .info-table th, .info-table td {
            text-align: left;
            padding: 8px;
            border-bottom: 1px solid #ddd;
        }
        .info-table th {
            width: 30%;
            color: #555;
        }
        .amount-box {
            background-color: #f9f9f9;
            border: 2px solid #ddd;
            padding: 15px;
            text-align: center;
            margin-bottom: 30px;
            border-radius: 5px;
        }
        .amount-box .amount {
            font-size: 28px;
            font-weight: bold;
            color: #d9534f;
        }
        .signature-section {
            margin-top: 80px;
            text-align: center;
        }
        .signature-line {
            width: 300px;
            border-top: 1px solid #000;
            margin: 0 auto;
            padding-top: 10px;
        }
        .signature-text {
            font-size: 12px;
            font-weight: bold;
        }
        .footer {
            margin-top: 40px;
            text-align: center;
            font-size: 10px;
            color: #888;
            border-top: 1px solid #eee;
            padding-top: 10px;
        }
    </style>
</head>
<body>

    <div class="header">
        <div class="company-name">NEO PROJECT S.R.L</div>
        <div class="receipt-title">Comprobante de Pago</div>
    </div>

    <div class="receipt-details">
        <strong>Recibo No:</strong> #{{ str_pad($gasto->id, 6, '0', STR_PAD_LEFT) }}<br>
        <strong>Fecha:</strong> {{ \Carbon\Carbon::parse($gasto->fecha)->format('d/m/Y') }}
    </div>

    <table class="info-table">
        <tr>
            <th>Proyecto:</th>
            <td>{{ $gasto->proyecto->nombre ?? 'N/A' }}</td>
        </tr>
        <tr>
            <th>Beneficiario (Trabajador/Proveedor):</th>
            <td>{{ $gasto->proveedor->name ?? 'Trabajador Independiente / Maestro' }}</td>
        </tr>
        <tr>
            <th>Tipo de Gasto:</th>
            <td>{{ $gasto->tipo_gasto }}</td>
        </tr>
        @if($gasto->subpartida)
        <tr>
            <th>Subpartida:</th>
            <td>{{ $gasto->subpartida->codigo }} - {{ $gasto->subpartida->nombre }}</td>
        </tr>
        @endif
        <tr>
            <th>Método de Pago:</th>
            <td>{{ $gasto->metodo_pago }}</td>
        </tr>
        <tr>
            <th>Descripción / Concepto:</th>
            <td>{{ $gasto->descripcion }}</td>
        </tr>
    </table>

    <div class="amount-box">
        <div style="font-size: 14px; text-transform: uppercase; margin-bottom: 5px; color: #777;">Monto Pagado</div>
        <div class="amount">${{ number_format($gasto->monto, 2) }}</div>
    </div>

    <div class="signature-section">
        <div class="signature-line"></div>
        <div class="signature-text">Firma del Beneficiario / Trabajador</div>
        <div style="margin-top: 5px; font-size: 12px; color: #555;">{{ $gasto->proveedor->name ?? '__________________________________' }}</div>
    </div>

    <div class="footer">
        Este documento sirve como constancia del desembolso de fondos para los gastos del proyecto.<br>
        Generado el {{ date('d/m/Y H:i:s') }}
    </div>

</body>
</html>
