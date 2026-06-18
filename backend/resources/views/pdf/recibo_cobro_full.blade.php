<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <title>Recibo de Cobro - {{ $data['id'] }}</title>
    <style>
        body {
            font-family: 'Helvetica', 'Arial', sans-serif;
            font-size: 13px;
            color: #2c3e50;
            margin: 30px;
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
        .company-details {
            color: #7f8c8d;
            font-size: 11px;
            margin-top: 5px;
            line-height: 1.4;
        }
        .badge {
            background-color: #27ae60;
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
            border-left: 4px solid #27ae60;
            padding: 20px;
            margin-bottom: 30px;
        }
        .details-table {
            width: 100%;
            border-collapse: collapse;
        }
        .details-table td {
            padding: 10px 0;
            vertical-align: top;
        }
        .details-label {
            width: 25%;
            font-size: 10px;
            color: #7f8c8d;
            text-transform: uppercase;
            font-weight: bold;
        }
        .details-value {
            width: 75%;
            font-size: 14px;
            color: #2c3e50;
            font-weight: bold;
            border-bottom: 1px solid #ecf0f1;
            padding-bottom: 4px;
        }
        .total-section {
            width: 100%;
            margin-top: 20px;
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
            width: 50%;
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
        .watermark { 
            position: absolute; 
            top: 40%; 
            left: 20%; 
            font-size: 90px; 
            font-weight: bold;
            color: rgba(39, 174, 96, 0.06); 
            transform: rotate(-35deg); 
            z-index: -1; 
            letter-spacing: 5px;
        }
    </style>
</head>
<body>
    <div class="watermark">RECIBIDO / PAGADO</div>

    <table class="header-top">
        <tr>
            <td style="width: 50%; vertical-align: top;">
                <img src="{{ public_path('images/logo.png') }}" style="max-height: 60px; margin-bottom: 10px;" alt="NEO PROJECT">
                <div class="company-details">
                    RNC: 132-XXXXX-X<br>
                    Gestión, Construcción y Remodelación<br>
                    Tel: (809) 000-0000
                </div>
            </td>
            <td style="width: 50%; text-align: right; vertical-align: top;">
                <div style="margin-bottom: 15px;">
                    <span class="badge">Recibo Oficial de Ingreso</span>
                </div>
                <div style="font-size: 14px;">
                    <strong>Recibo N°:</strong> <span style="color: #e74c3c; font-weight: bold;">#{{ str_pad($data['id'], 6, '0', STR_PAD_LEFT) }}</span>
                </div>
                <div style="font-size: 12px; color: #7f8c8d; margin-top: 4px;">
                    Fecha de emisión: {{ \Carbon\Carbon::parse($data['fecha'])->format('d/m/Y') }}
                </div>
            </td>
        </tr>
    </table>

    <div class="info-card">
        <table class="details-table">
            <tr>
                <td class="details-label">RECIBIDO DE:</td>
                <td class="details-value" style="font-size: 16px;">{{ $data['entidad'] }}</td>
            </tr>
            <tr>
                <td class="details-label">CONCEPTO DE:</td>
                <td class="details-value">{{ $data['subtitulo'] }}</td>
            </tr>
            <tr>
                <td class="details-label">PROYECTO:</td>
                <td class="details-value">{{ $data['proyecto']->nombre ?? 'N/A' }}</td>
            </tr>
            <tr>
                <td class="details-label">MÉTODO DE PAGO:</td>
                <td class="details-value">
                    <span style="background: #e8f8f5; color: #16a085; padding: 3px 8px; border-radius: 4px; font-size: 11px; display: inline-block; border: 1px solid #b2e8d9;">
                        {{ $data['metodo'] }}
                    </span>
                </td>
            </tr>
            @if(!empty($data['referencia']))
            <tr>
                <td class="details-label">REFERENCIA:</td>
                <td class="details-value">{{ $data['referencia'] }}</td>
            </tr>
            @endif
        </table>
    </div>

    <table class="total-section">
        <tr>
            <td style="width: 45%; vertical-align: middle;">
                <div style="font-style: italic; color: #7f8c8d; font-size: 11px; padding-right: 20px;">
                    Este documento es un comprobante oficial de pago recibido por Neo Project S.R.L. y sirve como descargo del monto especificado.
                </div>
            </td>
            <td style="width: 55%; text-align: right; vertical-align: middle;">
                <div style="color: #7f8c8d; font-size: 11px; text-transform: uppercase; font-weight: bold; margin-bottom: 8px; letter-spacing: 1px;">Valor Recibido</div>
                <div class="total-box">
                    RD$ {{ number_format($data['monto'], 2) }}
                </div>
            </td>
        </tr>
    </table>

    <table class="signatures">
        <tr>
            <td style="width: 100%; vertical-align: bottom; height: 80px;">
                <div class="sig-line">
                    <strong>Firma Autorizada / Sello</strong><br>
                    <span style="color: #7f8c8d;">NEO PROJECT S.R.L</span>
                </div>
            </td>
        </tr>
    </table>

    <div class="footer">
        Generado automáticamente por el Sistema el {{ date('d/m/Y') }} a las {{ date('H:i:s') }}
    </div>
</body>
</html>
