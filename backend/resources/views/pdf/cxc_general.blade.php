<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reporte General CXC</title>
    <style>
        @page { margin: 40px; }
        body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; font-size: 14px; color: #333; margin: 0; padding: 0; }
        .pdf-header-container { width: 100%; background-color: #0c336b; color: #ffffff; padding: 20px; border-radius: 8px; box-sizing: border-box; display: table; margin-bottom: 20px; }
        .header-left, .header-center, .header-right { display: table-cell; vertical-align: middle; }
        .header-left { width: 15%; }
        .header-left img { max-width: 120px; max-height: 60px; background-color: transparent; padding: 5px; }
        .header-center { width: 60%; text-align: left; padding-left: 15px; }
        .header-center .top-text { font-size: 10px; text-transform: uppercase; letter-spacing: 1px; color: #b0c4de; }
        .header-center .main-title { font-size: 24px; font-weight: bold; margin: 4px 0 0; color: #ffffff; }
        .header-right { width: 25%; text-align: right; }
        .header-right .report-label { font-size: 11px; color: #b0c4de; }
        .header-right .report-type { font-size: 15px; color: #fbbc05; font-weight: bold; }
        .subheader { width: 100%; border-bottom: 1px solid #ddd; padding-bottom: 10px; margin-bottom: 25px; display: table; }
        .subheader-left { display: table-cell; font-size: 16px; font-weight: bold; color: #1a1a1a; text-transform: uppercase; }
        .subheader-right { display: table-cell; text-align: right; font-size: 11px; color: #666; vertical-align: bottom; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; font-size: 12px; }
        table, th, td { border: 1px solid #ddd; }
        th, td { padding: 6px; text-align: left; }
        th { background-color: #f4f4f4; }
    </style>
</head>
<body>
    <div class="pdf-header-container">
        <div class="header-left">
            @php $imagePath = public_path('logo_ledhouse.png'); @endphp
            @if(file_exists($imagePath)) <img src="{{ $imagePath }}" alt="Logo"> @endif
        </div>
        <div class="header-center">
            <div class="top-text">EMPRESA</div>
            <div class="main-title">LED-HOUSE</div>
        </div>
        <div class="header-right">
            <div class="report-label">Documento</div>
            <div class="report-type">Reporte</div>
        </div>
    </div>

    <div class="subheader">
        <div class="subheader-left">
            REPORTE DE ESTADO DE CUENTAS (CXC)
            <div style="font-size: 12px; font-weight: normal; margin-top: 6px; color: #555; text-transform: none;">
                <strong>Reporte:</strong> Todos los Documentos
            </div>
        </div>
        <div class="subheader-right">
            Generado: {{ \Carbon\Carbon::now()->subHours(4)->format('d/m/Y, h:i A') }}
        </div>
    </div>

    <table>
        <thead>
            <tr>
                <th>Cliente</th>
                <th>Factura</th>
                <th>Facturado</th>
                <th>Pagado</th>
                <th>Deuda Pendiente</th>
                <th>Vencimiento</th>
                <th>Estado</th>
            </tr>
        </thead>
        <tbody>
            @php
                $totalFacturado = 0;
                $totalPagado = 0;
                $totalPendiente = 0;
            @endphp
            @forelse($cxcs as $cxc)
                @php
                    $totalFacturado += $cxc->monto_factura;
                    $totalPagado += $cxc->monto_pagado;
                    $totalPendiente += $cxc->monto_pendiente;
                    $fechaVencimiento = \Carbon\Carbon::parse($cxc->fecha_vencimiento);
                    $estaVencido = $fechaVencimiento->isPast() && strtolower($cxc->estado) !== 'pagado';
                    $diasVencido = $estaVencido ? abs(floor(now()->diffInDays($fechaVencimiento))) : 0;
                @endphp
                <tr>
                    <td>{{ $cxc->cliente->nombre ?? 'N/A' }}</td>
                    <td>{{ $cxc->documento }}</td>
                    <td>${{ number_format($cxc->monto_factura, 2) }}</td>
                    <td>${{ number_format($cxc->monto_pagado, 2) }}</td>
                    <td style="color: #d93025; font-weight: bold;">${{ number_format($cxc->monto_pendiente, 2) }}</td>
                    <td>{{ $fechaVencimiento->format('Y-m-d') }}</td>
                    <td>
                        @if(strtolower($cxc->estado) === 'pagado')
                            <span style="color: #1e8e3e; font-weight: bold;">Pagado</span>
                        @elseif($estaVencido)
                            <span style="color: #ea4335; font-weight: bold;">{{ $diasVencido }} días vencidos</span>
                        @else
                            <span style="color: #fbbc05; font-weight: bold;">Pendiente</span>
                        @endif
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="7" style="text-align: center; padding: 20px;">No hay cuentas por cobrar registradas.</td>
                </tr>
            @endforelse
            <tr style="background-color: #f8f9fa; font-weight: bold; font-size: 13px;">
                <td colspan="2" style="text-align: right; color: #555;">TOTALES:</td>
                <td>${{ number_format($totalFacturado, 2) }}</td>
                <td>${{ number_format($totalPagado, 2) }}</td>
                <td style="color: #d93025;">${{ number_format($totalPendiente, 2) }}</td>
                <td colspan="2"></td>
            </tr>
        </tbody>
    </table>
</body>
</html>
