<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <title>Recibo de Gasto #{{ str_pad($gasto->id, 6, '0', STR_PAD_LEFT) }}</title>
    <style>
        body {
            font-family: 'Helvetica', 'Arial', sans-serif;
            font-size: 13px;
            color: #2c3e50;
            margin: 0;
            padding: 20px;
        }
        .container {
            /* DOMPDF breaks with width:100% + padding. Letting block layout handle it. */
        }
        .header-top {
            width: 100%;
            margin-bottom: 30px;
            border-bottom: 3px solid #2c3e50;
            padding-bottom: 20px;
        }
        .logo-text {
            font-size: 28px;
            font-weight: 900;
            color: #2c3e50;
            letter-spacing: 1px;
            margin: 0;
        }
        .badge {
            background-color: #2c3e50;
            color: #fff;
            padding: 6px 12px;
            border-radius: 4px;
            font-size: 12px;
            text-transform: uppercase;
            font-weight: bold;
            letter-spacing: 1px;
        }
        .info-card {
            background-color: #f8f9fa;
            border-left: 4px solid #3498db;
            padding: 18px;
            margin-bottom: 30px;
        }
        .table-details {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 30px;
        }
        .table-details th {
            background-color: #ecf0f1;
            color: #2c3e50;
            text-align: left;
            padding: 12px;
            font-size: 11px;
            text-transform: uppercase;
            border-top: 1px solid #bdc3c7;
            border-bottom: 1px solid #bdc3c7;
        }
        .table-details td {
            padding: 15px 12px;
            border-bottom: 1px solid #ecf0f1;
            color: #34495e;
            vertical-align: top;
        }
        .total-box {
            background-color: #27ae60;
            color: white;
            padding: 15px 30px;
            border-radius: 6px;
            font-size: 24px;
            font-weight: bold;
            display: inline-block;
        }
        .signatures {
            width: 100%;
            margin-top: 80px;
            text-align: center;
        }
        .sig-line {
            width: 70%;
            border-top: 1px solid #7f8c8d;
            margin: 0 auto;
            padding-top: 8px;
            color: #34495e;
            font-size: 11px;
            text-transform: uppercase;
        }
        .footer {
            width: 100%;
            text-align: center;
            margin-top: 60px;
            font-size: 10px;
            color: #95a5a6;
            border-top: 1px solid #ecf0f1;
            padding-top: 15px;
        }
    </style>
</head>
<body>
    <div class="container">
        
        <table class="header-top">
            <tr>
                <td style="width: 50%; vertical-align: middle;">
                    <h1 class="logo-text">NEO PROJECT S.R.L</h1>
                    <div style="color: #7f8c8d; font-size: 11px; margin-top: 5px; text-transform: uppercase; letter-spacing: 1px;">
                        Gestión y Control de Obras
                    </div>
                </td>
                <td style="width: 50%; text-align: right; vertical-align: middle;">
                    <div style="margin-bottom: 12px;">
                        <span class="badge">Comprobante Oficial de Pago</span>
                    </div>
                    <div style="font-size: 14px;">
                        <strong>Recibo N°:</strong> <span style="color: #e74c3c; font-weight: bold;">#{{ str_pad($gasto->id, 6, '0', STR_PAD_LEFT) }}</span>
                    </div>
                    <div style="font-size: 12px; color: #7f8c8d; margin-top: 4px;">
                        Fecha de emisión: {{ \Carbon\Carbon::parse($gasto->fecha)->format('d/m/Y') }}
                    </div>
                </td>
            </tr>
        </table>

        <div class="info-card">
            <table style="width: 100%;">
                <tr>
                    <td style="width: 50%; vertical-align: top;">
                        <div style="font-size: 10px; color: #7f8c8d; text-transform: uppercase; font-weight: bold; margin-bottom: 4px;">Beneficiario / Proveedor</div>
                        <div style="font-size: 16px; font-weight: bold; color: #2c3e50;">{{ $gasto->proveedor->name ?? 'Trabajador / Proveedor General' }}</div>
                        <div style="font-size: 12px; color: #7f8c8d; margin-top: 3px;">Pagado vía: {{ $gasto->metodo_pago }}</div>
                    </td>
                    <td style="width: 50%; vertical-align: top; text-align: right;">
                        <div style="font-size: 10px; color: #7f8c8d; text-transform: uppercase; font-weight: bold; margin-bottom: 4px;">Proyecto Destino</div>
                        <div style="font-size: 15px; font-weight: bold; color: #2c3e50;">{{ $gasto->proyecto->nombre ?? 'N/A' }}</div>
                        @if($gasto->subpartida)
                        <div style="font-size: 12px; color: #34495e; margin-top: 3px;">Partida: {{ $gasto->subpartida->descripcion }}</div>
                        @endif
                    </td>
                </tr>
            </table>
        </div>

        <table class="table-details">
            <thead>
                <tr>
                    <th style="width: 40%;">Descripción del Concepto</th>
                    <th style="width: 30%; text-align: center;">Tipo de Gasto</th>
                    <th style="width: 30%; text-align: right;">Monto Aplicado</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td style="font-size: 14px;">
                        <strong>{{ $gasto->descripcion }}</strong>
                    </td>
                    <td style="text-align: center;">
                        <div style="background: #e8f4f8; color: #2980b9; padding: 4px 8px; border-radius: 4px; font-size: 11px; display: inline-block; border: 1px solid #bde4f0; margin: 0 auto;">
                            {{ $gasto->tipo_gasto }}
                        </div>
                    </td>
                    <td style="text-align: right; font-size: 16px; font-weight: bold;">
                        RD$ {{ number_format($gasto->monto, 2) }}
                    </td>
                </tr>
            </tbody>
        </table>

        <table style="width: 100%; margin-top: 10px;">
            <tr>
                <td style="width: 40%; vertical-align: top;">
                    <div style="border: 2px dashed #bdc3c7; padding: 25px 15px; border-radius: 6px; color: #95a5a6; font-size: 12px; text-align: center; text-transform: uppercase; letter-spacing: 1px; width: 90%; margin: 0 auto;">
                        Sello de la empresa
                    </div>
                </td>
                <td style="width: 60%; text-align: right; vertical-align: middle;">
                    <div style="color: #7f8c8d; font-size: 11px; text-transform: uppercase; font-weight: bold; margin-bottom: 8px; letter-spacing: 1px;">Total Desembolsado</div>
                    <div class="total-box">
                        RD$ {{ number_format($gasto->monto, 2) }}
                    </div>
                </td>
            </tr>
        </table>

        <table class="signatures">
            <tr>
                <td style="width: 50%; vertical-align: bottom; height: 60px;">
                    <div class="sig-line">
                        <strong>Firma Autorizada</strong><br>
                        <span style="color: #7f8c8d;">NEO PROJECT S.R.L</span>
                    </div>
                </td>
                <td style="width: 50%; vertical-align: bottom; height: 60px;">
                    <div class="sig-line">
                        <strong>Recibí Conforme</strong><br>
                        <span style="color: #7f8c8d;">{{ $gasto->proveedor->name ?? 'Firma / Cédula del Beneficiario' }}</span>
                    </div>
                </td>
            </tr>
        </table>

        <div class="footer">
            Este recibo es un documento oficial de control interno de desembolsos. Válido para auditoría y control de costos.<br>
            Generado automáticamente por el Sistema el {{ date('d/m/Y') }} a las {{ date('H:i:s') }}
        </div>
    </div>
</body>
</html>
