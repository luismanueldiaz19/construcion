<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Presupuesto de Proyecto - Neo Project</title>
    <style>
        @page { margin: 1cm; }
        body { font-family: 'Helvetica', 'Arial', sans-serif; font-size: 11px; color: #333; margin: 0; padding: 0; line-height: 1.4; }
        
        /* Header Layout */
        .header-table { width: 100%; border: none; margin-bottom: 20px; }
        .logo-area { width: 150px; text-align: left; }
        .company-info { text-align: left; vertical-align: top; padding-left: 10px; }
        .budget-title-area { text-align: center; vertical-align: top; }
        .right-logo { width: 120px; text-align: right; }
        
        .company-name { font-size: 18px; font-weight: bold; color: #003366; margin-bottom: 2px; }
        .budget-label { font-size: 20px; font-weight: bold; color: #003366; margin-bottom: 5px; }
        
        /* Project Details */
        .details-area { margin-bottom: 20px; font-size: 12px; }
        .details-area div { margin-bottom: 4px; }
        
        /* Partida Tables */
        .partida-title { font-size: 13px; font-weight: bold; margin-top: 20px; margin-bottom: 5px; color: #333; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 10px; }
        th { background-color: #f2f2f2; border: 1px solid #ddd; padding: 6px; text-align: center; color: #555; }
        td { border: 1px solid #eee; padding: 6px; }
        
        .text-right { text-align: right; }
        .text-center { text-align: center; }
        .total-partida-row { background-color: #f9f9f9; font-weight: bold; }
        
        /* Totals Box */
        .totals-container { width: 100%; margin-top: 15px; }
        .totals-box { width: 280px; float: right; border: 1px solid #ddd; border-radius: 4px; }
        .totals-box table { width: 100%; margin-bottom: 0; }
        .totals-box td { border: none; border-bottom: 1px solid #f2f2f2; padding: 8px; font-size: 12px; }
        .totals-box tr:last-child td { border-bottom: none; }
        .total-proyecto-row { font-weight: bold; background-color: #f2f2f2; }
        
        /* Observations */
        .observations { margin-top: 30px; border: 1px solid #ddd; border-radius: 6px; padding: 10px; background-color: #fdfdfd; }
        .observations-title { font-weight: bold; color: #003366; font-size: 10px; text-transform: uppercase; margin-bottom: 5px; }
        
        /* Signatures */
        .signatures { margin-top: 80px; width: 100%; }
        .sig-box { width: 30%; text-align: center; display: inline-block; }
        .sig-line { border-top: 1px solid #333; width: 80%; margin: 0 auto 5px auto; }
        .sig-label { font-size: 10px; font-weight: bold; }
        
        .clear { clear: both; }
    </style>
</head>
<body>
    <table class="header-table">
        <tr>
            <td class="logo-area">
                <img src="{{ public_path('images/logo.png') }}" style="max-width: 150px; max-height: 80px;">
            </td>
            <td class="company-info">
                <div class="company-name">Neo Project</div>
                <div>RNC: 132-XXXXX-X</div>
                <div>Dirección: Calle Principal #10, Puerto Plata</div>
                <div>Tel: (809) 000-0000</div>
            </td>
            <td class="budget-title-area">
                <div class="budget-label">PRESUPUESTO</div>
                <div><strong>Fecha:</strong> {{ date('d/m/Y') }}</div>
                <div><strong>Número:</strong> PROY-{{ date('Y') }}-{{ str_pad($proyecto->id, 3, '0', STR_PAD_LEFT) }}</div>
            </td>
            <td class="right-logo">
                @if($proyecto->logo_path)
                    <img src="{{ public_path('storage/' . $proyecto->logo_path) }}" style="max-width: 120px; max-height: 60px;">
                @endif
            </td>
        </tr>
    </table>

    <div class="details-area">
        <div><strong>Proyecto:</strong> {{ $proyecto->nombre }}</div>
        <div><strong>Cliente:</strong> {{ $proyecto->cliente }}</div>
        <div><strong>Fecha fin:</strong> {{ $proyecto->fecha_fin ?? '2026-04-23' }}</div>
        <div><strong>Estado:</strong> {{ $proyecto->estado }}</div>
    </div>

    @foreach($proyecto->partidas as $index => $partida)
    <div class="partida-title">{{ $index + 1 }} - {{ strtolower($partida->descripcion) }}</div>
    <table>
        <thead>
            <tr>
                <th width="40%">Descripción</th>
                <th width="10%">Cant</th>
                <th width="10%">Unidad</th>
                <th width="20%">Precio</th>
                <th width="20%">Subtotal</th>
            </tr>
        </thead>
        <tbody>
            @foreach($partida->subpartidas as $sub)
            <tr>
                <td>{{ $sub->descripcion }}</td>
                <td class="text-center">{{ number_format($sub->cantidad, 2) }}</td>
                <td class="text-center">{{ $sub->unidad }}</td>
                <td class="text-right">{{ number_format($sub->costo_unitario, 2) }}</td>
                <td class="text-right">{{ number_format($sub->total_presupuestado, 2) }}</td>
            </tr>
            @endforeach
            <tr class="total-partida-row">
                <td colspan="4" class="text-right">Total Partida</td>
                <td class="text-right">{{ number_format($partida->subpartidas->sum('total_presupuestado'), 2) }}</td>
            </tr>
        </tbody>
    </table>
    @endforeach

    <div class="totals-container">
        <div class="totals-box">
            <table>
                @php
                    $subtotalGral = $proyecto->partidas->sum(function($p) { return $p->subpartidas->sum('total_presupuestado'); });
                @endphp
                <tr>
                    <td>Subtotal Partidas:</td>
                    <td class="text-right bold">RDS $ {{ number_format($subtotalGral, 2) }}</td>
                </tr>
                @if($proyecto->itbis > 0)
                <tr>
                    <td>Itbis:</td>
                    <td class="text-right bold">RDS $ {{ number_format($proyecto->itbis, 2) }}</td>
                </tr>
                @endif
                @if($proyecto->transporte > 0)
                <tr>
                    <td>Transporte:</td>
                    <td class="text-right bold">RDS $ {{ number_format($proyecto->transporte, 2) }}</td>
                </tr>
                @endif
                @if($proyecto->otros_costos > 0)
                <tr>
                    <td>Otros Costos:</td>
                    <td class="text-right bold">RDS $ {{ number_format($proyecto->otros_costos, 2) }}</td>
                </tr>
                @endif
                @if($proyecto->supervision_tecnica > 0)
                <tr>
                    <td>Supervisión Técnica:</td>
                    <td class="text-right bold">RDS $ {{ number_format($proyecto->supervision_tecnica, 2) }}</td>
                </tr>
                @endif
                <tr class="total-proyecto-row">
                    <td>Total Proyecto:</td>
                    <td class="text-right bold">RDS $ {{ number_format($proyecto->total_presupuesto_con_globales, 2) }}</td>
                </tr>
            </table>
        </div>
        <div class="clear"></div>
    </div>

    <div class="observations">
        <div class="observations-title">OBSERVACIONES / NOTAS:</div>
        <div style="font-size: 11px; color: #555;">
            {{ $proyecto->notas ?? 'Sin observaciones adicionales.' }}
        </div>
    </div>

    <div class="signatures">
        <div class="sig-box">
            <div class="sig-line"></div>
            <div class="sig-label">Entregado por</div>
        </div>
        <div class="sig-box">
            <div class="sig-line"></div>
            <div class="sig-label">Aprobado por</div>
        </div>
        <div class="sig-box">
            <div class="sig-line"></div>
            <div class="sig-label">Autorizado por</div>
        </div>
    </div>

</body>
</html>
