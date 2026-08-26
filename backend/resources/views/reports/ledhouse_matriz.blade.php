<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Reporte de Cuentas - LED-HOUSE</title>
    <style>
        @page {
            margin: 40px 40px 120px 40px;
        }
        body {
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
            font-size: 9px; /* Tamaño de fuente pequeño porque es mucha data horizontal */
            color: #333;
            margin: 0;
        }
        
        /* Header Container */
        .pdf-header-container {
            width: 100%;
            background-color: #0c336b;
            color: #ffffff;
            padding: 15px;
            border-radius: 6px;
            box-sizing: border-box;
            display: table;
            margin-bottom: 15px;
        }
        .header-left, .header-center, .header-right {
            display: table-cell;
            vertical-align: middle;
        }
        .header-left { width: 10%; }
        .header-left img {
            max-width: 50px; max-height: 50px;
            background-color: white; border-radius: 50%; padding: 4px;
        }
        .header-center { width: 60%; text-align: left; padding-left: 15px; }
        .header-center .top-text { font-size: 9px; color: #b0c4de; text-transform: uppercase; }
        .header-center .main-title { font-size: 18px; font-weight: bold; margin: 2px 0 0; }
        .header-right { width: 30%; text-align: right; }
        .header-right .report-label { font-size: 9px; color: #b0c4de; }
        .header-right .report-type { font-size: 12px; color: #fbbc05; font-weight: bold; }

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
            bottom: -50px;
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

        
        /* Contenedor de la Tabla */
        .table-wrapper {
            width: 100%;
            border: 1px solid #ccc;
            border-radius: 6px;
            overflow: hidden;
        }

        table {
            width: 100%;
            border-collapse: collapse;
        }
        
        th, td {
            border-bottom: 1px solid #e2e8f0;
            padding: 6px 4px;
            text-align: right;
        }
        /* Alineación específica */
        th:nth-child(1), td:nth-child(1) { text-align: center; width: 45px; } /* Código */
        th:nth-child(2), td:nth-child(2) { text-align: left; width: 180px; } /* Descripción */

        /* Cabecera Principal */
        thead th {
            background-color: #1e293b;
            color: #ffffff;
            font-weight: bold;
            font-size: 9px;
            text-transform: uppercase;
        }

        /* Colores Base por Módulo */
        .mod-header-VENTAS { background-color: #e8f5e9; color: #2e7d32; font-weight: bold; }
        .mod-header-COSTOS { background-color: #fff3e0; color: #e65100; font-weight: bold; }
        .mod-header-GASTOS { background-color: #ffebee; color: #c62828; font-weight: bold; }
        
        .mod-subtotal {
            background-color: #f8fafc;
            font-weight: bold;
        }

        /* Formateo para Heatmap Textos (blanco cuando está intenso) */
        .text-light { color: #ffffff !important; }
        .text-dark { color: #333333; }
        .text-bold { font-weight: bold; }

        /* Summary Bar */
        .summary-bar {
            background-color: #1e293b;
            color: #ffffff;
            border-radius: 6px;
            padding: 12px;
            width: 100%;
            margin-top: 20px;
            display: table;
            font-size: 10px;
            box-sizing: border-box;
        }
        .summary-item {
            display: table-cell;
            text-align: center;
            vertical-align: middle;
            border-right: 1px solid #334155;
            padding: 0 10px;
            width: 20%;
        }
        .summary-item:last-child {
            border-right: none;
        }
        .summary-item-label {
            color: #94a3b8;
            font-size: 9px;
            text-transform: uppercase;
            margin-bottom: 4px;
        }
        .summary-item-val {
            font-size: 12px;
            font-weight: bold;
        }
        .val-ventas { color: #4ade80; } /* Light Green */
        .val-costos { color: #fbbf24; } /* Amber */
        .val-gastos { color: #ef4444; } /* Red */
        .val-utilidad { font-size: 13px; }
    </style>
</head>
<body>

    @php
        $meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
        
        // Helper function for Heatmap color in PHP
        function getHeatmapColor($monto, $max, $modulo) {
            if ($monto == 0 || $max == 0) return ['bg' => 'transparent', 'text' => 'text-dark'];
            
            $intensity = abs($monto) / $max;
            // Reducido a 0.55 para colores menos intensos
            $alpha = min($intensity * 0.55, 0.55);
            
            // RGB base colors
            $r = 255; $g = 255; $b = 255;
            
            if ($modulo == 'VENTAS') {
                // Green: #4caf50 -> RGB(76, 175, 80)
                $r = 255 - (255 - 76) * $alpha;
                $g = 255 - (255 - 175) * $alpha;
                $b = 255 - (255 - 80) * $alpha;
            } else {
                // Red: #f44336 -> RGB(244, 67, 54)
                $r = 255 - (255 - 244) * $alpha;
                $g = 255 - (255 - 67) * $alpha;
                $b = 255 - (255 - 54) * $alpha;
            }
            
            $bg = sprintf("rgb(%d, %d, %d)", $r, $g, $b);
            // Como el fondo ahora es más claro, siempre podemos usar texto oscuro
            $textClass = 'text-dark';
            
            return ['bg' => $bg, 'text' => $textClass];
        }
        
        function formatMonto($monto) {
            if ($monto == 0) return '-';
            if ($monto < 0) return '($ ' . number_format(abs($monto), 2) . ')';
            return '$ ' . number_format($monto, 2);
        }

        // Totales para Resumen Anual
        $tot_ventas = $matriz['VENTAS']['total_anual_modulo'] ?? 0;
        $tot_costos = $matriz['COSTOS']['total_anual_modulo'] ?? 0;
        $tot_gastos = $matriz['GASTOS']['total_anual_modulo'] ?? 0;
        
        $utilidad = $tot_ventas - $tot_costos - $tot_gastos;
        $margen = $tot_ventas > 0 ? ($utilidad / $tot_ventas) * 100 : 0;
    @endphp

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
                <div style="width: 40px; height: 40px; background-color: white; border-radius: 50%;"></div>
            @endif
        </div>
        <div class="header-center">
            <div class="top-text">EMPRESA</div>
            <div class="main-title">LED-HOUSE</div>
        </div>
        <div class="header-right">
            <div class="report-label">Año: {{ $year }}</div>
            <div class="report-type">Detalle de Cuentas</div>
        </div>
    </div>

    <!-- Subheader con filtros y fecha -->
    <div class="subheader">
        <div class="subheader-left">
            REPORTE DE CUENTAS
            <div style="font-size: 11px; font-weight: normal; margin-top: 6px; color: #555; text-transform: none;">
                Año Seleccionado: <strong>{{ $year }}</strong>
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

    <div class="table-wrapper">
        <table>
            <thead>
                <tr>
                    <th>CÓDIGO</th>
                    <th>CUENTA</th>
                    @for($i = 0; $i < $mesesVisibles; $i++)
                        <th>{{ strtoupper($meses[$i]) }}</th>
                    @endfor
                    <th>TOTAL</th>
                </tr>
            </thead>
            <tbody>
                @foreach(['VENTAS', 'COSTOS', 'GASTOS'] as $modNombre)
                    @if(isset($matriz[$modNombre]))
                        @php 
                            $modData = $matriz[$modNombre]; 
                            $maxModulo = $maximos[$modNombre] ?? 0;
                        @endphp
                        
                        <!-- Cabecera del Modulo -->
                        <tr class="mod-header-{{ $modNombre }}">
                            <td></td>
                            <td colspan="{{ $mesesVisibles + 2 }}">{{ $modNombre }}</td>
                        </tr>
                        
                        <!-- Cuentas -->
                        @foreach($modData['cuentas'] as $cta)
                            <tr>
                                <td>{{ $cta['codigo'] }}</td>
                                <td>{{ $cta['descripcion'] }}</td>
                                @for($i = 1; $i <= $mesesVisibles; $i++)
                                    @php
                                        $val = $cta['meses'][$i] ?? 0;
                                        $colorData = getHeatmapColor($val, $maxModulo, $modNombre);
                                    @endphp
                                    <td style="background-color: {{ $colorData['bg'] }};" class="{{ $colorData['text'] }}">
                                        {{ formatMonto($val) }}
                                    </td>
                                @endfor
                                <td class="text-bold">{{ formatMonto($cta['total_anual']) }}</td>
                            </tr>
                        @endforeach
                        
                        <!-- Subtotales -->
                        <tr class="mod-subtotal">
                            <td></td>
                            <td>Subtotal {{ $modNombre }}</td>
                            @for($i = 1; $i <= $mesesVisibles; $i++)
                                <td>{{ formatMonto($modData['subtotales'][$i] ?? 0) }}</td>
                            @endfor
                            <td class="text-bold">{{ formatMonto($modData['total_anual_modulo']) }}</td>
                        </tr>
                    @endif
                @endforeach
            </tbody>
        </table>
    </div>

    <!-- Barra de Resumen -->
    <div class="summary-bar">
        <div class="summary-item">
            <div class="summary-item-label">Ventas</div>
            <div class="summary-item-val val-ventas">{{ formatMonto($tot_ventas) }}</div>
        </div>
        <div class="summary-item">
            <div class="summary-item-label">Costos</div>
            <div class="summary-item-val val-costos">{{ formatMonto($tot_costos) }}</div>
        </div>
        <div class="summary-item">
            <div class="summary-item-label">Gastos</div>
            <div class="summary-item-val val-gastos">{{ formatMonto($tot_gastos) }}</div>
        </div>
        <div class="summary-item">
            <div class="summary-item-label" style="color: #fff; font-weight: bold;">Utilidad Neta</div>
            <div class="summary-item-val val-utilidad" style="color: {{ $utilidad >= 0 ? '#4ade80' : '#ef4444' }};">{{ formatMonto($utilidad) }}</div>
        </div>
        <div class="summary-item">
            <div class="summary-item-label" style="color: #fff; font-weight: bold;">Margen</div>
            <div class="summary-item-val val-ventas" style="color: {{ $margen >= 0 ? '#4ade80' : '#ef4444' }};">{{ number_format($margen, 2) }}%</div>
        </div>
    </div>

</body>
</html>
