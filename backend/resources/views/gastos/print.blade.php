<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Comprobante de Gasto #{{ $gasto->id }}</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            color: #333;
            font-size: 12px;
            margin: 0;
            padding: 0;
        }
        .container {
            width: 100%;
        }
        .header-table {
            width: 100%;
            border-bottom: 2px solid #003366;
            margin-bottom: 20px;
            padding-bottom: 10px;
        }
        .company-name {
            color: #003366;
            font-size: 24px;
            font-weight: bold;
            margin: 0;
        }
        .invoice-title {
            text-align: right;
            font-size: 18px;
            color: #555;
            margin: 0;
        }
        .info-table {
            width: 100%;
            margin-bottom: 20px;
        }
        .info-box {
            width: 48%;
            vertical-align: top;
            padding: 10px;
            background-color: #f9f9f9;
            border: 1px solid #ddd;
        }
        .info-box h3 {
            margin-top: 0;
            font-size: 14px;
            color: #003366;
            border-bottom: 1px solid #ccc;
            padding-bottom: 5px;
        }
        .items-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 30px;
        }
        .items-table th {
            background-color: #003366;
            color: #fff;
            padding: 8px;
            text-align: left;
        }
        .items-table td {
            padding: 12px 8px;
            border-bottom: 1px solid #ddd;
        }
        .text-right {
            text-align: right;
        }
        .total-box {
            width: 100%;
            padding: 15px;
            background-color: #003366;
            color: #fff;
            text-align: right;
            font-size: 18px;
            font-weight: bold;
            margin-bottom: 30px;
        }
        .signature-table {
            width: 100%;
            margin-top: 50px;
        }
        .signature-line {
            width: 45%;
            text-align: center;
            vertical-align: bottom;
        }
        .line {
            border-top: 1px solid #000;
            margin-top: 40px;
            padding-top: 5px;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Encabezado -->
        <table class="header-table">
            <tr>
                <td>
                    <img src="{{ public_path('images/logo.png') }}" style="max-height: 60px;">
                    <div style="color: #666; margin-top: 5px;">Gestión de Construcción e Ingeniería</div>
                </td>
                <td class="text-right">
                    <div class="invoice-title">COMPROBANTE DE GASTO / PAGO</div>
                    <div style="font-weight: bold;">Nº: #{{ str_pad($gasto->id, 6, '0', STR_PAD_LEFT) }}</div>
                    <div>Fecha: {{ \Carbon\Carbon::parse($gasto->fecha)->format('d/m/Y') }}</div>
                </td>
            </tr>
        </table>

        <!-- Información -->
        <table class="info-table">
            <tr>
                <td class="info-box">
                    <h3>Datos del Proyecto</h3>
                    <div><strong>Proyecto:</strong> {{ $gasto->proyecto->nombre ?? 'N/A' }}</div>
                    <div><strong>Cliente:</strong> {{ $gasto->proyecto->cliente ?? 'N/A' }}</div>
                    <div><strong>Partida/Subpartida:</strong> {{ $gasto->subpartida->descripcion ?? 'General' }}</div>
                </td>
                <td style="width: 4%;"></td>
                <td class="info-box">
                    <h3>Detalles del Pago</h3>
                    <div><strong>Tipo de Gasto:</strong> {{ $gasto->tipo_gasto }}</div>
                    <div><strong>Método de Pago:</strong> {{ $gasto->metodo_pago }}</div>
                    <div><strong>Proveedor/Beneficiario:</strong> {{ $gasto->proveedor->nombre ?? 'N/A' }}</div>
                </td>
            </tr>
        </table>

        <!-- Concepto -->
        <table class="items-table">
            <thead>
                <tr>
                    <th>Concepto / Descripción del Gasto</th>
                    <th class="text-right" style="width: 150px;">Monto</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td style="height: 60px; vertical-align: top;">
                        {{ $gasto->descripcion }}
                    </td>
                    <td class="text-right" style="vertical-align: top; font-weight: bold; font-size: 16px;">
                        ${{ number_format($gasto->monto, 2) }}
                    </td>
                </tr>
            </tbody>
        </table>

        <div class="total-box">
            TOTAL PAGADO: ${{ number_format($gasto->monto, 2) }}
        </div>

        <!-- Firmas -->
        <table class="signature-table">
            <tr>
                <td class="signature-line">
                    <div class="line">Entregado / Pagado por</div>
                    <div style="font-size: 10px; color: #666;">Firma de Neo Project</div>
                </td>
                <td style="width: 10%;"></td>
                <td class="signature-line">
                    <div class="line">Recibido por</div>
                    <div style="font-size: 10px; color: #666;">Firma y Cédula del Beneficiario</div>
                </td>
            </tr>
        </table>
    </div>
</body>
</html>
