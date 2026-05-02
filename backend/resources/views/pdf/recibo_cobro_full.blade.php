<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Recibo de Cobro - {{ $data['id'] }}</title>
    <style>
        @page { margin: 1cm; }
        body { font-family: 'Helvetica', 'Arial', sans-serif; font-size: 12px; color: #333; margin: 0; padding: 0; line-height: 1.5; }
        
        .header-table { width: 100%; border: none; margin-bottom: 30px; }
        .logo-area { width: 150px; text-align: left; }
        .company-info { text-align: left; vertical-align: top; padding-left: 10px; }
        .title-area { text-align: center; vertical-align: top; }
        
        .company-name { font-size: 20px; font-weight: bold; color: #003366; margin-bottom: 2px; }
        .receipt-label { font-size: 24px; font-weight: bold; color: #003366; margin-bottom: 5px; }
        
        .details-box { border: 1px solid #ddd; border-radius: 8px; padding: 20px; margin-bottom: 30px; background-color: #f9f9f9; }
        .details-row { margin-bottom: 10px; display: table; width: 100%; }
        .details-label { display: table-cell; width: 30%; font-weight: bold; color: #555; }
        .details-value { display: table-cell; width: 70%; border-bottom: 1px solid #eee; }

        .monto-box { margin-top: 20px; text-align: right; padding: 20px; border-top: 2px solid #003366; }
        .monto-label { font-size: 16px; font-weight: bold; }
        .monto-value { font-size: 24px; font-weight: bold; color: #28a745; }

        .footer { margin-top: 100px; text-align: center; }
        .signature-line { border-top: 1px solid #333; width: 250px; margin: 0 auto 5px auto; }
        .signature-label { font-weight: bold; font-size: 12px; }
        
        .watermark { position: absolute; top: 40%; left: 25%; font-size: 80px; color: rgba(40, 167, 69, 0.1); transform: rotate(-45deg); z-index: -1; }
    </style>
</head>
<body>
    <div class="watermark">PAGADO</div>

    <table class="header-table">
        <tr>
            <td class="logo-area">
                <img src="{{ public_path('images/logo.png') }}" style="max-width: 150px; max-height: 80px;">
            </td>
            <td class="company-info">
                <div class="company-name">Neo Project S.R.L</div>
                <div>RNC: 132-XXXXX-X</div>
                <div>Construcción y Remodelación</div>
                <div>Tel: (809) 000-0000</div>
            </td>
            <td class="title-area">
                <div class="receipt-label">RECIBO DE PAGO</div>
                <div style="font-size: 14px;"><strong>No:</strong> #{{ str_pad($data['id'], 5, '0', STR_PAD_LEFT) }}</div>
                <div style="font-size: 14px;"><strong>Fecha:</strong> {{ \Carbon\Carbon::parse($data['fecha'])->format('d/m/Y') }}</div>
            </td>
        </tr>
    </table>

    <div class="details-box">
        <div class="details-row">
            <div class="details-label">RECIBIDO DE:</div>
            <div class="details-value">{{ $data['entidad'] }}</div>
        </div>
        <div class="details-row">
            <div class="details-label">CONCEPTO DE:</div>
            <div class="details-value">{{ $data['subtitulo'] }}</div>
        </div>
        <div class="details-row">
            <div class="details-label">PROYECTO:</div>
            <div class="details-value">{{ $data['proyecto']->nombre ?? 'N/A' }}</div>
        </div>
        <div class="details-row">
            <div class="details-label">MÉTODO DE PAGO:</div>
            <div class="details-value">{{ $data['metodo'] }}</div>
        </div>
        @if($data['referencia'])
        <div class="details-row">
            <div class="details-label">REFERENCIA:</div>
            <div class="details-value">{{ $data['referencia'] }}</div>
        </div>
        @endif
    </div>

    <div class="monto-box">
        <span class="monto-label">VALOR RECIBIDO:</span>
        <br>
        <span class="monto-value">RD$ {{ number_format($data['monto'], 2) }}</span>
    </div>

    <div style="margin-top: 40px; font-style: italic; color: #666;">
        Este documento es un comprobante oficial de pago recibido por Neo Project S.R.L.
    </div>

    <div class="footer">
        <div class="signature-line"></div>
        <div class="signature-label">Firma Autorizada / Sello</div>
        <div style="font-size: 10px; margin-top: 5px; color: #999;">Generado el {{ date('d/m/Y H:i:s') }}</div>
    </div>
</body>
</html>
