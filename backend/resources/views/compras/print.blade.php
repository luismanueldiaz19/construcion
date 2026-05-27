<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Factura #{{ $compra->id }}</title>
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
            margin-bottom: 20px;
        }
        .items-table th {
            background-color: #003366;
            color: #fff;
            padding: 8px;
            text-align: left;
        }
        .items-table td {
            padding: 8px;
            border-bottom: 1px solid #ddd;
        }
        .text-right {
            text-align: right;
        }
        .totals-table {
            width: 40%;
            margin-left: 60%;
            border-collapse: collapse;
        }
        .totals-table td {
            padding: 5px 8px;
        }
        .total-row {
            font-weight: bold;
            font-size: 14px;
            border-top: 2px solid #003366;
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
        <!-- Encabezado con Tabla -->
        <table class="header-table">
            <tr>
                <td>
                    <img src="{{ public_path('images/logo.png') }}" style="max-height: 60px;">
                    <div style="color: #666; margin-top: 5px;">Gestión de Construcción e Ingeniería</div>
                </td>
                <td class="text-right">
                    <div class="invoice-title">FACTURA / ORDEN DE COMPRA</div>
                    <div style="font-weight: bold;">Nº: #{{ str_pad($compra->id, 6, '0', STR_PAD_LEFT) }}</div>
                    <div>Fecha: {{ \Carbon\Carbon::parse($compra->fecha)->format('d/m/Y') }}</div>
                </td>
            </tr>
        </table>

        <!-- Información con Tabla -->
        <table class="info-table">
            <tr>
                <td class="info-box">
                    <h3>Datos del Proveedor</h3>
                    <div><strong>Nombre:</strong> {{ $compra->proveedor->nombre ?? 'N/A' }}</div>
                    <div><strong>RNC/Cédula:</strong> {{ $compra->proveedor->rnc ?? 'N/A' }}</div>
                    <div><strong>Teléfono:</strong> {{ $compra->proveedor->telefono ?? 'N/A' }}</div>
                    <div><strong>Tipo:</strong> {{ $compra->tipo_compra }}</div>
                </td>
                <td style="width: 4%;"></td>
                <td class="info-box">
                    <h3>Datos del Proyecto</h3>
                    <div><strong>Nombre:</strong> {{ $compra->proyecto->nombre ?? 'N/A' }}</div>
                    <div><strong>Cliente:</strong> {{ $compra->proyecto->cliente ?? 'N/A' }}</div>
                    <div><strong>Ubicación:</strong> {{ $compra->proyecto->ubicacion ?? 'N/A' }}</div>
                </td>
            </tr>
        </table>

        <!-- Detalles Adicionales de la Compra -->
        <table class="info-table" style="margin-top: -10px;">
            <tr>
                <td class="info-box" style="width: 100%;">
                    <h3>Detalles de la Factura</h3>
                    <table style="width: 100%; font-size: 12px;">
                        <tr>
                            <td><strong>Comprobante:</strong> {{ $compra->comprobante ?? 'N/A' }}</td>
                            <td><strong>Orden #:</strong> {{ $compra->orden ?? 'N/A' }}</td>
                            <td><strong>Código Ref:</strong> {{ $compra->codigo ?? 'N/A' }}</td>
                            @if($compra->tipo_compra == 'Crédito')
                            <td><strong>Vencimiento:</strong> {{ $compra->fecha_vencimiento ? \Carbon\Carbon::parse($compra->fecha_vencimiento)->format('d/m/Y') : 'N/A' }}</td>
                            @endif
                        </tr>
                    </table>
                </td>
            </tr>
        </table>

        <!-- Detalles -->
        <table class="items-table">
            <thead>
                <tr>
                    <th>Código</th>
                    <th>Descripción</th>
                    <th class="text-right">Cant.</th>
                    <th class="text-right">Precio</th>
                    <th class="text-right">Total</th>
                </tr>
            </thead>
            <tbody>
                @foreach($compra->detalles as $detalle)
                <tr>
                    <td>{{ $detalle->material->codigo ?? 'N/A' }}</td>
                    <td>{{ $detalle->material->nombre ?? 'Desconocido' }}</td>
                    <td class="text-right">{{ number_format($detalle->cantidad, 2) }}</td>
                    <td class="text-right">${{ number_format($detalle->precio_unitario, 2) }}</td>
                    <td class="text-right">${{ number_format($detalle->subtotal, 2) }}</td>
                </tr>
                @endforeach
            </tbody>
        </table>

        <!-- Totales -->
        <table class="totals-table">
            <tr>
                <td class="text-right">Subtotal:</td>
                <td class="text-right">${{ number_format($compra->subtotal, 2) }}</td>
            </tr>
            <tr>
                <td class="text-right">ITBIS (18%):</td>
                <td class="text-right">${{ number_format($compra->itbis, 2) }}</td>
            </tr>
            <tr class="total-row">
                <td class="text-right">TOTAL:</td>
                <td class="text-right">${{ number_format($compra->total, 2) }}</td>
            </tr>
        </table>

        @if($compra->nota)
        <div style="margin-top: 20px; padding: 10px; background-color: #f9f9f9; border: 1px solid #ddd;">
            <strong>Notas / Observaciones:</strong><br>
            {{ $compra->nota }}
        </div>
        @endif

        <!-- Firmas -->
        <table class="signature-table">
            <tr>
                <td class="signature-line">
                    <div class="line">Entregado por</div>
                    <div style="font-size: 10px; color: #666;">Firma y Sello del Proveedor</div>
                </td>
                <td style="width: 10%;"></td>
                <td class="signature-line">
                    <div class="line">Recibido por</div>
                    <div style="font-size: 10px; color: #666;">Firma de Neo Project</div>
                </td>
            </tr>
        </table>
    </div>
</body>
</html>
