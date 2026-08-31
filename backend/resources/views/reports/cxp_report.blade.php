<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Reporte de Cuentas por Pagar (CXP) - Neo Project</title>
    <style>
        body { font-family: 'Helvetica', Arial, sans-serif; font-size: 11px; color: #333; margin: 0; padding: 0; }
        .header { width: 100%; border-bottom: 2px solid #dc3545; padding-bottom: 15px; margin-bottom: 25px; }
        table { width: 100%; border-collapse: collapse; }
        .company-info { text-align: left; vertical-align: top; }
        .company-name { font-size: 22px; font-weight: bold; color: #dc3545; margin-bottom: 5px; }
        .company-details { font-size: 10px; color: #555; line-height: 1.4; }
        .report-info { text-align: right; vertical-align: top; }
        .report-title { font-size: 18px; font-weight: bold; color: #333; margin-bottom: 5px; text-transform: uppercase; }
        .report-meta { font-size: 10px; color: #555; line-height: 1.4; }
        
        .data-table { width: 100%; border-collapse: collapse; margin-bottom: 30px; }
        .data-table th { background-color: #dc3545; color: white; padding: 10px 8px; text-align: left; font-size: 11px; text-transform: uppercase; }
        .data-table td { padding: 9px 8px; border-bottom: 1px solid #e0e0e0; }
        .data-table tbody tr:nth-child(even) { background-color: #f9f9f9; }
        .text-right { text-align: right; }
        .text-center { text-align: center; }
        
        .badge { padding: 4px 8px; border-radius: 4px; font-size: 9px; font-weight: bold; color: white; text-transform: uppercase; }
        .badge-pendiente { background-color: #ffc107; color: #333; }
        .badge-pagado { background-color: #28a745; }
        .badge-cancelado { background-color: #6c757d; }

        .totals-container { width: 45%; float: right; }
        .totals-table { width: 100%; border-collapse: collapse; }
        .totals-table td { padding: 8px; border-bottom: 1px solid #e0e0e0; }
        .totals-table .label { font-weight: bold; color: #555; }
        .totals-table .amount { text-align: right; font-weight: bold; }
        .totals-table .grand-total td { background-color: #dc3545; color: white; font-weight: bold; font-size: 14px; border: none; }
        
        .filters { margin-bottom: 20px; font-size: 10px; color: #666; background-color: #f4f6f9; padding: 10px; border-radius: 4px; border-left: 4px solid #dc3545; }
        .footer { position: fixed; bottom: -30px; left: 0px; right: 0px; height: 50px; font-size: 9px; color: #777; text-align: center; border-top: 1px solid #ddd; padding-top: 10px; }
        .clearfix::after { content: ""; clear: both; display: table; }
    </style>
</head>
<body>
    <div class="header">
        <table>
            <tr>
                <td style="width: 20%; vertical-align: top;">
                    @php
                        $imagePath = public_path('assets/assets/logo.png');
                        $logoBase64 = '';
                        if(file_exists($imagePath)) {
                            $logoBase64 = 'data:image/png;base64,' . base64_encode(file_get_contents($imagePath));
                        }
                    @endphp
                    @if($logoBase64)
                        <img src="{{ $logoBase64 }}" style="max-height: 80px; max-width: 140px; object-fit: contain;">
                    @endif
                </td>
                <td class="company-info" style="width: 40%;">
                    <div class="company-name">NEO PROJECT S.R.L</div>
                    <div class="company-details">
                        <strong>RNC:</strong> 131181181<br>
                        <strong>Dirección:</strong> Manolo Tavares Justo No. 15, Puerto Plata<br>
                        <strong>Teléfono:</strong> 809-320-1668
                    </div>
                </td>
                <td class="report-info" style="width: 40%;">
                    <div class="report-title">Estado de Cuentas por Pagar</div>
                    <div class="report-meta">
                        @if(isset($proveedor))
                            <strong>Proveedor:</strong> {{ $proveedor }}<br>
                        @endif
                        <strong>Fecha Emisión:</strong> {{ date('d/m/Y') }}
                    </div>
                </td>
            </tr>
        </table>
    </div>

    <table class="data-table">
        <thead>
            <tr>
                <th>Documento</th>
                @if(!isset($proveedor))
                <th>Proveedor</th>
                @endif
                <th>Vencimiento</th>
                <th class="text-right">Monto Factura</th>
                <th class="text-right">Pagado</th>
                <th class="text-right">Deuda</th>
                <th class="text-center">Estado</th>
            </tr>
        </thead>
        <tbody>
            @php 
                $totalFactura = 0; 
                $totalPagado = 0; 
            @endphp
            @forelse($cxps as $cxp)
            @php 
                $deuda = $cxp->monto_factura - $cxp->monto_pagado;
                $totalFactura += $cxp->monto_factura;
                $totalPagado += $cxp->monto_pagado;
            @endphp
            <tr>
                <td>{{ $cxp->documento }}</td>
                @if(!isset($proveedor))
                <td>{{ $cxp->proveedor }}</td>
                @endif
                <td>{{ \Carbon\Carbon::parse($cxp->fecha_vencimiento)->format('d/m/Y') }}</td>
                <td class="text-right">${{ number_format($cxp->monto_factura, 2) }}</td>
                <td class="text-right">${{ number_format($cxp->monto_pagado, 2) }}</td>
                <td class="text-right" style="font-weight: bold; color: {{ $deuda > 0 ? '#dc3545' : '#28a745' }};">
                    ${{ number_format($deuda, 2) }}
                </td>
                <td class="text-center">
                    <span class="badge badge-{{ strtolower($cxp->estado) }}">{{ $cxp->estado }}</span>
                </td>
            </tr>
            @empty
            <tr>
                <td colspan="{{ isset($proveedor) ? 6 : 7 }}" class="text-center" style="padding: 20px;">No hay cuentas por pagar registradas.</td>
            </tr>
            @endforelse
        </tbody>
    </table>

    <div class="clearfix">
        <div class="totals-container">
            <table class="totals-table">
                <tr>
                    <td class="label">Total Facturado:</td>
                    <td class="amount">${{ number_format($totalFactura, 2) }}</td>
                </tr>
                <tr>
                    <td class="label">Total Pagado:</td>
                    <td class="amount">${{ number_format($totalPagado, 2) }}</td>
                </tr>
                <tr class="grand-total">
                    <td class="label" style="color: white;">DEUDA PENDIENTE:</td>
                    <td class="amount">${{ number_format($totalFactura - $totalPagado, 2) }}</td>
                </tr>
            </table>
        </div>
    </div>

    <div class="footer">
        NEO PROJECT S.R.L - Reporte generado automáticamente el {{ date('d/m/Y H:i') }}
    </div>
</body>
</html>
