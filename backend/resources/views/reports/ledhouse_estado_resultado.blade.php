<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Estado de Resultados - LED-HOUSE</title>
    <style>
        @page {
            margin: 40px 40px 120px 40px;
        }
        body {
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
            font-size: 12px;
            color: #333;
            margin: 0;
        }
        /* Header Container */
        .pdf-header-container {
            width: 100%;
            background-color: #0c336b;
            color: #ffffff;
            padding: 20px;
            border-radius: 8px;
            box-sizing: border-box;
            display: table;
            margin-bottom: 20px;
        }
        .header-left, .header-center, .header-right {
            display: table-cell;
            vertical-align: middle;
        }
        .header-left {
            width: 15%;
        }
        .header-left img {
            max-width: 70px;
            max-height: 70px;
            background-color: white;
            border-radius: 50%;
            padding: 5px;
        }
        .header-center {
            width: 60%;
            text-align: left;
            padding-left: 15px;
        }
        .header-center .top-text {
            font-size: 10px;
            text-transform: uppercase;
            letter-spacing: 1px;
            color: #b0c4de;
        }
        .header-center .main-title {
            font-size: 24px;
            font-weight: bold;
            margin: 4px 0 0;
            color: #ffffff;
        }
        .header-right {
            width: 25%;
            text-align: right;
        }
        .header-right .report-label {
            font-size: 11px;
            color: #b0c4de;
        }
        .header-right .report-type {
            font-size: 15px;
            color: #fbbc05; /* Dorado */
            font-weight: bold;
        }
        
        /* Subheader */
        .subheader {
            width: 100%;
            border-bottom: 1px solid #ddd;
            padding-bottom: 10px;
            margin-bottom: 25px;
            display: table;
        }
        .subheader-left {
            display: table-cell;
            font-size: 16px;
            font-weight: bold;
            color: #1a1a1a;
            text-transform: uppercase;
        }
        .subheader-right {
            display: table-cell;
            text-align: right;
            font-size: 11px;
            color: #666;
            vertical-align: bottom;
        }

        /* Footer */
        .pdf-footer {
            position: fixed;
            bottom: -80px;
            left: 0;
            right: 0;
            border-top: 1px solid #ccc;
            padding-top: 15px;
            display: table;
            width: 100%;
            font-size: 11px;
            color: #555;
        }
        .footer-left {
            display: table-cell;
            width: 40%;
            vertical-align: bottom;
        }
        .signature-line {
            border-top: 1px solid #888;
            width: 80%;
            padding-top: 5px;
            font-size: 10px;
            color: #666;
        }
        .footer-right {
            display: table-cell;
            width: 60%;
            text-align: right;
            line-height: 1.5;
        }

        /* Tablas */
        .summary-table {
            width: 100%;
            margin-bottom: 30px;
            border-collapse: collapse;
        }
        .summary-table th, .summary-table td {
            border: 1px solid #ddd;
            padding: 10px;
            text-align: right;
        }
        .summary-table th {
            background-color: #f9f9f9;
            font-weight: bold;
        }
        .summary-table .total-row {
            background-color: #f0f0f0;
            font-weight: bold;
        }
        .summary-table .profit-row td {
            background-color: {{ $utilidad >= 0 ? '#e6f4ea' : '#fce8e6' }};
            color: {{ $utilidad >= 0 ? '#1e8e3e' : '#d93025' }};
            font-size: 14px;
            font-weight: bold;
        }
        .details-table {
            width: 100%;
            border-collapse: collapse;
        }
        .details-table th, .details-table td {
            border: 1px solid #eee;
            padding: 8px;
            text-align: left;
        }
        .details-table th {
            background-color: #f5f5f5;
            font-weight: bold;
        }
        .details-table .amount {
            text-align: right;
        }
        .text-center {
            text-align: center;
        }
        .module-badge {
            display: inline-block;
            padding: 3px 6px;
            border-radius: 4px;
            font-size: 10px;
            font-weight: bold;
            color: #fff;
        }
        .module-ventas { background-color: #34a853; }
        .module-costos { background-color: #fbbc05; }
        .module-gastos { background-color: #ea4335; }
    </style>
</head>
<body>

    <!-- Header Azul -->
    <div class="pdf-header-container">
        <div class="header-left">
            @php
                $imagePath = public_path('logo_ledhouse.png');
                $imgBase64 = '';
                if(file_exists($imagePath)) {
                    $imgBase64 = 'data:image/png;base64,' . base64_encode(file_get_contents($imagePath));
                }
            @endphp
            @if($imgBase64)
                <img src="{{ $imgBase64 }}" alt="Logo">
            @else
                <div style="width: 50px; height: 50px; background-color: white; border-radius: 50%;"></div>
            @endif
        </div>
        <div class="header-center">
            <div class="top-text">EMPRESA</div>
            <div class="main-title">LED-HOUSE</div>
        </div>
        <div class="header-right">
            <div class="report-label">Reporte</div>
            <div class="report-type">Estado de Resultados</div>
        </div>
    </div>

    <!-- Subheader con filtros y fecha -->
    <div class="subheader">
        <div class="subheader-left">
            ESTADO DE RESULTADOS
            <div style="font-size: 11px; font-weight: normal; margin-top: 6px; color: #555; text-transform: none;">
                @if($request->start_date && $request->end_date)
                    Período: {{ date('d/m/Y', strtotime($request->start_date)) }} - {{ date('d/m/Y', strtotime($request->end_date)) }}
                @elseif($request->start_date)
                    Desde: {{ date('d/m/Y', strtotime($request->start_date)) }}
                @elseif($request->end_date)
                    Hasta: {{ date('d/m/Y', strtotime($request->end_date)) }}
                @else
                    Histórico Completo
                @endif
                
                @if($request->modulo && $request->modulo !== 'TODOS')
                    | Módulo: <strong>{{ $request->modulo }}</strong>
                @endif
            </div>
        </div>
        <div class="subheader-right">
            Generado: {{ \Carbon\Carbon::now()->subHours(4)->format('d/m/Y, h:i A') }}
        </div>
    </div>

    <!-- Footer Fijo para todas las páginas -->
    <div class="pdf-footer">
        <div class="footer-left">
            <div class="signature-line">
                Administración
            </div>
        </div>
        <div class="footer-right">
            Av. Manolo T. Justo No.15, Puerto Plata<br>
            Tel / WhatsApp: 809-320-1668<br>
            ledhouselaglez@outlook.com
        </div>
    </div>

    <!-- Contenido Principal -->
    <table class="summary-table">
        <thead>
            <tr>
                <th>Concepto</th>
                <th>Monto</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td style="text-align: left;">(+) Ingresos por Ventas</td>
                <td>${{ number_format($ventas, 2) }}</td>
            </tr>
            <tr>
                <td style="text-align: left;">(-) Costos de Ventas</td>
                <td>${{ number_format($costos, 2) }}</td>
            </tr>
            <tr class="total-row">
                <td style="text-align: left;">Utilidad Bruta</td>
                <td>${{ number_format($ventas - $costos, 2) }}</td>
            </tr>
            <tr>
                <td style="text-align: left;">(-) Gastos Operativos</td>
                <td>${{ number_format($gastos, 2) }}</td>
            </tr>
            <tr class="profit-row">
                <td style="text-align: left;">UTILIDAD NETA</td>
                <td>${{ number_format($utilidad, 2) }}</td>
            </tr>
        </tbody>
    </table>

    <h3 style="margin-bottom: 10px; color: #1a1a1a; font-size: 14px;">Detalle de Registros</h3>
    <table class="details-table">
        <thead>
            <tr>
                <th>Fecha</th>
                <th>Código</th>
                <th>Módulo</th>
                <th>Descripción</th>
                <th class="amount">Monto</th>
            </tr>
        </thead>
        <tbody>
            @forelse($registros as $reg)
            <tr>
                <td>{{ date('d/m/Y', strtotime($reg->fecha)) }}</td>
                <td>{{ $reg->codigo_cuenta }}</td>
                <td class="text-center">
                    <span class="module-badge 
                        @if($reg->modulo == 'VENTAS') module-ventas 
                        @elseif($reg->modulo == 'COSTOS') module-costos 
                        @elseif($reg->modulo == 'GASTOS') module-gastos 
                        @endif">
                        {{ $reg->modulo }}
                    </span>
                </td>
                <td>{{ $reg->descripcion_de_cuenta }}</td>
                <td class="amount">${{ number_format($reg->monto, 2) }}</td>
            </tr>
            @empty
            <tr>
                <td colspan="5" class="text-center">No hay registros para los filtros seleccionados.</td>
            </tr>
            @endforelse
        </tbody>
    </table>

</body>
</html>
