<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Recibo de Pago #{{ $pago->id }}</title>
    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }
        body {
            font-family: 'Courier New', Courier, monospace;
            font-size: 10px;
            color: #1a1a1a;
            background: #fff;
            padding: 8px;
            width: 220px;
        }

        /* ── HEADER ── */
        .header {
            text-align: center;
            padding-bottom: 8px;
            border-bottom: 2px solid #1a1a1a;
            margin-bottom: 8px;
        }
        .company-name {
            font-size: 13px;
            font-weight: bold;
            letter-spacing: 1px;
            text-transform: uppercase;
        }
        .receipt-title {
            font-size: 9px;
            margin-top: 3px;
            letter-spacing: 0.5px;
            text-transform: uppercase;
        }
        .receipt-number {
            font-size: 11px;
            font-weight: bold;
            margin-top: 4px;
        }
        .receipt-date {
            font-size: 9px;
            margin-top: 2px;
            color: #444;
        }

        /* ── DIVIDER ── */
        .divider {
            border: none;
            border-top: 1px dashed #555;
            margin: 7px 0;
        }
        .divider-solid {
            border: none;
            border-top: 1px solid #1a1a1a;
            margin: 7px 0;
        }

        /* ── INFO TABLE ── */
        table {
            width: 100%;
            border-collapse: collapse;
        }
        td {
            padding: 2px 0;
            vertical-align: top;
            line-height: 1.4;
        }
        .label {
            font-weight: bold;
            width: 40%;
            white-space: nowrap;
        }
        .value {
            width: 60%;
            word-break: break-word;
        }

        /* ── TOTALS ── */
        .totals-table td {
            padding: 3px 0;
        }
        .amount {
            text-align: right;
            white-space: nowrap;
        }
        .total-row td {
            font-weight: bold;
            font-size: 11px;
            border-top: 1px solid #1a1a1a;
            padding-top: 4px;
            margin-top: 2px;
        }
        .paid-row td {
            font-weight: bold;
            font-size: 12px;
        }
        .balance-row td {
            font-size: 10px;
        }

        /* ── STATUS BADGE ── */
        .status-badge {
            text-align: center;
            margin: 6px 0;
            padding: 3px 0;
            font-weight: bold;
            font-size: 9px;
            letter-spacing: 1px;
            border: 1px solid #1a1a1a;
        }

        /* ── FOOTER ── */
        .footer {
            text-align: center;
            margin-top: 10px;
            font-size: 8px;
            color: #555;
            line-height: 1.6;
        }
        .footer .gracias {
            font-size: 9px;
            font-weight: bold;
            color: #1a1a1a;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
    </style>
</head>
<body>

    {{-- ══ ENCABEZADO ══ --}}
    <div class="header">
        <div class="company-name">NEO PROJECT S.R.L</div>
        <div class="receipt-title">Recibo de Pago a Proveedor</div>
        <div class="receipt-number">#{{ str_pad($pago->id, 6, '0', STR_PAD_LEFT) }}</div>
        <div class="receipt-date">{{ \Carbon\Carbon::parse($pago->fecha)->format('d/m/Y') }}</div>
    </div>

    {{-- ══ DATOS DEL PROVEEDOR ══ --}}
    <table>
        <tr>
            <td class="label">Proveedor:</td>
            <td class="value">{{ $pago->cuentaPorPagar->proveedor->nombre }}</td>
        </tr>
        <tr>
            <td class="label">Compra ID:</td>
            <td class="value">#{{ $pago->cuentaPorPagar->compra_id }}</td>
        </tr>
        <tr>
            <td class="label">Método:</td>
            <td class="value">{{ $pago->metodo_pago }}</td>
        </tr>
        @if($pago->referencia)
        <tr>
            <td class="label">Ref.:</td>
            <td class="value">{{ $pago->referencia }}</td>
        </tr>
        @endif
        @if($pago->notas)
        <tr>
            <td class="label">Notas:</td>
            <td class="value">{{ $pago->notas }}</td>
        </tr>
        @endif
    </table>

    <hr class="divider">

    {{-- ══ MONTOS ══ --}}
    <table class="totals-table">
        <tr>
            <td>Total Factura:</td>
            <td class="amount">${{ number_format($pago->cuentaPorPagar->monto_total, 2) }}</td>
        </tr>
        <tr>
            <td>Pagado Anterior:</td>
            <td class="amount">${{ number_format($pago->cuentaPorPagar->monto_pagado - $pago->monto, 2) }}</td>
        </tr>
        <tr class="total-row">
            <td>ESTE PAGO:</td>
            <td class="amount">${{ number_format($pago->monto, 2) }}</td>
        </tr>
    </table>

    <hr class="divider-solid">

    <table class="totals-table">
        <tr class="balance-row">
            <td>BALANCE PENDIENTE:</td>
            <td class="amount">${{ number_format($pago->cuentaPorPagar->saldo, 2) }}</td>
        </tr>
    </table>

    {{-- ══ ESTADO ══ --}}
    <div class="status-badge">
        @if($pago->cuentaPorPagar->saldo <= 0)
            ✓ CUENTA SALDADA
        @else
            PAGO PARCIAL
        @endif
    </div>

    <hr class="divider">

    {{-- ══ PIE ══ --}}
    <div class="footer">
        <div class="gracias">*** Gracias por su Pago ***</div>
        <div>Generado el {{ date('d/m/Y H:i:s') }}</div>
        <div>Este recibo es válido como comprobante de pago</div>
    </div>

</body>
</html>
