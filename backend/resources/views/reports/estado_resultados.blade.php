<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Estado de Resultados - Neo Project</title>
    <style>
        body { font-family: 'Helvetica', Arial, sans-serif; font-size: 12px; color: #333; margin: 0; padding: 0; }
        .header { width: 100%; border-bottom: 2px solid #0056b3; padding-bottom: 15px; margin-bottom: 25px; }
        table { width: 100%; border-collapse: collapse; }
        .company-info { text-align: left; vertical-align: top; }
        .company-name { font-size: 22px; font-weight: bold; color: #0056b3; margin-bottom: 5px; }
        .company-details { font-size: 10px; color: #555; line-height: 1.4; }
        .report-info { text-align: right; vertical-align: top; }
        .report-title { font-size: 18px; font-weight: bold; color: #333; margin-bottom: 5px; text-transform: uppercase; }
        .report-meta { font-size: 10px; color: #555; line-height: 1.4; }
        
        .data-table { width: 100%; border-collapse: collapse; margin-bottom: 30px; margin-top: 20px;}
        .data-table th { background-color: #0056b3; color: white; padding: 12px 10px; text-align: left; font-size: 12px; text-transform: uppercase; }
        .data-table td { padding: 12px 10px; border-bottom: 1px solid #e0e0e0; font-size: 14px; }
        .data-table tr.total-row td { background-color: #f0f8ff; font-weight: bold; color: #0056b3; }
        .data-table tr.grand-total td { background-color: #0056b3; color: white; font-weight: bold; font-size: 16px; border: none; }
        
        .text-right { text-align: right; }
        
        .filters { margin-bottom: 20px; font-size: 12px; color: #666; background-color: #f4f6f9; padding: 12px; border-radius: 4px; border-left: 4px solid #0056b3; }
        .footer { position: fixed; bottom: -30px; left: 0px; right: 0px; height: 50px; font-size: 9px; color: #777; text-align: center; border-top: 1px solid #ddd; padding-top: 10px; }
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
                    @else
                        <div style="font-size:12px;color:red;border:1px solid red;padding:10px;">Logo no encontrado</div>
                    @endif
                </td>
                <td class="company-info" style="width: 40%;">
                    <div class="company-name">NEO PROJECT S.R.L</div>
                    <div class="company-details">
                        <strong>RNC:</strong> 131181181<br>
                        <strong>Dirección:</strong> Manolo Tavares Justo No. 15, Puerto Plata<br>
                        <strong>Teléfono:</strong> 809-320-1668<br>
                        <strong>Celular:</strong> 809-223-8039
                    </div>
                </td>
                <td class="report-info" style="width: 40%;">
                    <div class="report-title">Estado de Resultados</div>
                    <div class="report-meta">
                        <strong>Fecha de Emisión:</strong> {{ date('d/m/Y') }}<br>
                        <strong>Hora:</strong> {{ date('H:i') }}
                    </div>
                </td>
            </tr>
        </table>
    </div>

    <div class="filters">
        @if($proyecto)
            <strong>Proyecto:</strong> {{ $proyecto->nombre }} <br>
            <strong>Cliente:</strong> {{ $proyecto->client->name ?? $proyecto->cliente ?? 'N/A' }} <br>
        @else
            <strong>Reporte Global</strong> (Todos los proyectos) <br>
        @endif
    </div>

    @php
        $margenBruto = $ingresos > 0 ? ($utilidad_bruta / $ingresos) * 100 : 0;
        $margenNeto = $ingresos > 0 ? ($utilidad_neta / $ingresos) * 100 : 0;

        $contrato = 0;
        $cobrado = 0;
        $pendiente = 0;
        $avanceFinanciero = 0;
        $cuentasPorCobrar = 0;
        
        $totalPresupuesto = 0;
        $totalReal = 0;

        if ($proyecto) {
            $contrato = $proyecto->total_presupuesto_con_globales ?? $proyecto->presupuesto_estimado ?? 0;
            $cobrado = $proyecto->total_cobrado ?? 0;
            $pendiente = $contrato - $cobrado;
            $avanceFinanciero = $contrato > 0 ? ($cobrado / $contrato * 100) : 0;
            $cuentasPorCobrar = $contrato - $cobrado;

            $totalPresupuesto = $contrato;

            $gastosTotales = 0;
            foreach($gastosReales as $g) {
                $gastosTotales += $g->monto;
            }
            
            $consumosTotales = 0;
            foreach($consumosReales as $c) {
                $consumosTotales += $c->total;
            }

            $totalReal = $gastosTotales + $consumosTotales;
        }
    @endphp

    <table class="data-table">
        <thead>
            <tr>
                <th>Concepto</th>
                <th class="text-right">Monto (RD$)</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td>Ingresos Operativos</td>
                <td class="text-right">${{ number_format($ingresos, 2) }}</td>
            </tr>
            <tr>
                <td>Costos de Operación</td>
                <td class="text-right">(${{ number_format(abs($costos), 2) }})</td>
            </tr>
            <tr class="total-row">
                <td>UTILIDAD BRUTA (Margen: {{ number_format($margenBruto, 2) }}%)</td>
                <td class="text-right">${{ number_format($utilidad_bruta, 2) }}</td>
            </tr>
            <tr>
                <td colspan="2" style="height: 10px; border: none;"></td>
            </tr>
            <tr>
                <td>Gastos Generales y Administrativos</td>
                <td class="text-right">(${{ number_format(abs($gastos), 2) }})</td>
            </tr>
            <tr class="grand-total">
                <td>UTILIDAD NETA (Margen: {{ number_format($margenNeto, 2) }}%)</td>
                <td class="text-right">${{ number_format($utilidad_neta, 2) }}</td>
            </tr>
        </tbody>
    </table>

    @if($proyecto)
    <div style="page-break-inside: avoid; margin-top: 20px;">
        <table style="width: 100%;">
            <tr>
                <td style="width: 48%; vertical-align: top;">
                    <div style="background-color: #f9f9f9; padding: 15px; border-radius: 5px; border: 1px solid #ddd;">
                        <div style="font-weight: bold; font-size: 14px; margin-bottom: 15px; color: #0056b3;">Información del Contrato y Cobros</div>
                        <table style="width: 100%;">
                            <tr>
                                <td style="padding: 5px 0; color: #555;">Monto Total del Proyecto</td>
                                <td class="text-right" style="padding: 5px 0;"><strong>RD$ {{ number_format($contrato, 2) }}</strong></td>
                            </tr>
                            <tr>
                                <td style="padding: 5px 0; color: #555;">Total Cobrado al Cliente</td>
                                <td class="text-right" style="padding: 5px 0; color: green;"><strong>RD$ {{ number_format($cobrado, 2) }}</strong></td>
                            </tr>
                            <tr>
                                <td style="padding: 5px 0; color: #555;"><strong>Balance Pendiente de Pago</strong></td>
                                <td class="text-right" style="padding: 5px 0; color: #d35400;"><strong>RD$ {{ number_format($pendiente, 2) }}</strong></td>
                            </tr>
                            <tr>
                                <td colspan="2" style="border-bottom: 1px solid #eee; padding-top: 5px;"></td>
                            </tr>
                            <tr>
                                <td style="padding: 10px 0 5px; color: #555;">Ingresos Contables (Sin Impuestos)</td>
                                <td class="text-right" style="padding: 10px 0 5px; color: #0056b3;"><strong>RD$ {{ number_format($ingresos, 2) }}</strong></td>
                            </tr>
                            <tr>
                                <td style="padding: 5px 0; color: #555;">Avance Financiero (Cobrado / Proyecto)</td>
                                <td class="text-right" style="padding: 5px 0; color: #0056b3;"><strong>{{ number_format($avanceFinanciero, 1) }}%</strong></td>
                            </tr>
                            <tr>
                                <td style="padding: 5px 0; color: #555;">Avance Físico (Ejecución Real)</td>
                                <td class="text-right" style="padding: 5px 0; color: #008080;"><strong>{{ number_format($avanceFisicoTotal ?? 0, 1) }}%</strong></td>
                            </tr>
                        </table>
                    </div>
                </td>
                <td style="width: 4%;"></td>
                <td style="width: 48%; vertical-align: top;">
                    <div style="background-color: #f9f9f9; padding: 15px; border-radius: 5px; border: 1px solid #ddd;">
                        <div style="font-weight: bold; font-size: 14px; margin-bottom: 15px; color: #0056b3;">Indicadores Financieros y Gestión</div>
                        <table style="width: 100%;">
                            <tr>
                                <td style="padding: 5px 0; color: #555;">Margen Bruto</td>
                                <td class="text-right" style="padding: 5px 0; color: #0056b3;"><strong>{{ number_format($margenBruto, 1) }}%</strong></td>
                            </tr>
                            <tr>
                                <td style="padding: 5px 0; color: #555;">Margen Neto</td>
                                <td class="text-right" style="padding: 5px 0; color: {{ $margenNeto >= 0 ? 'green' : 'red' }};"><strong>{{ number_format($margenNeto, 1) }}%</strong></td>
                            </tr>
                            <tr>
                                <td style="padding: 5px 0; color: #555;">Cuentas por Cobrar</td>
                                <td class="text-right" style="padding: 5px 0; color: #d35400;"><strong>RD$ {{ number_format($cuentasPorCobrar, 2) }}</strong></td>
                            </tr>
                            <tr>
                                <td style="padding: 5px 0; color: #555;">Ejecución del Presupuesto</td>
                                <td class="text-right" style="padding: 5px 0;"><strong>{{ $contrato > 0 ? number_format(($totalReal / $contrato) * 100, 1) : 0 }}%</strong></td>
                            </tr>
                        </table>
                    </div>
                </td>
            </tr>
        </table>
    </div>

    <div style="page-break-inside: avoid; margin-top: 20px;">
        <div style="font-weight: bold; font-size: 14px; margin-bottom: 10px; color: #0056b3;">Comparativa Presupuesto vs Real</div>
        <table class="data-table" style="margin-top: 0;">
            <thead>
                <tr>
                    <th>Concepto</th>
                    <th class="text-right">Presupuesto</th>
                    <th class="text-right">Real</th>
                    <th class="text-right">Diferencia</th>
                </tr>
            </thead>
            <tbody>
                <tr class="total-row">
                    <td>Costo Total del Proyecto</td>
                    <td class="text-right">RD$ {{ number_format($totalPresupuesto, 2) }}</td>
                    <td class="text-right">RD$ {{ number_format($totalReal, 2) }}</td>
                    <td class="text-right" style="color: {{ ($totalPresupuesto - $totalReal) < 0 ? 'red' : 'green' }}; font-weight: bold;">
                        RD$ {{ number_format($totalPresupuesto - $totalReal, 2) }}
                    </td>
                </tr>
            </tbody>
        </table>
    </div>
    @endif
    <div class="footer">
        NEO PROJECT S.R.L - Reporte generado automáticamente el {{ date('d/m/Y') }} a las {{ date('H:i') }}
    </div>
</body>
</html>
