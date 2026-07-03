<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Reporte de Pagos de Clientes - Neo Project</title>
    <style>
        body { font-family: 'Helvetica', Arial, sans-serif; font-size: 11px; color: #333; margin: 0; padding: 0; }
        .header { width: 100%; border-bottom: 2px solid #0056b3; padding-bottom: 15px; margin-bottom: 25px; }
        table { width: 100%; border-collapse: collapse; }
        .company-info { text-align: left; vertical-align: top; }
        .company-name { font-size: 22px; font-weight: bold; color: #0056b3; margin-bottom: 5px; }
        .company-details { font-size: 10px; color: #555; line-height: 1.4; }
        .report-info { text-align: right; vertical-align: top; }
        .report-title { font-size: 18px; font-weight: bold; color: #333; margin-bottom: 5px; text-transform: uppercase; }
        .report-meta { font-size: 10px; color: #555; line-height: 1.4; }
        
        .data-table { width: 100%; border-collapse: collapse; margin-bottom: 30px; }
        .data-table th { background-color: #0056b3; color: white; padding: 10px 8px; text-align: left; font-size: 11px; text-transform: uppercase; }
        .data-table td { padding: 9px 8px; border-bottom: 1px solid #e0e0e0; }
        .data-table tbody tr:nth-child(even) { background-color: #f9f9f9; }
        .text-right { text-align: right; }
        .text-center { text-align: center; }
        
        .totals-container { width: 45%; float: right; }
        .totals-table { width: 100%; border-collapse: collapse; }
        .totals-table td { padding: 8px; border-bottom: 1px solid #e0e0e0; }
        .totals-table .label { font-weight: bold; color: #555; }
        .totals-table .amount { text-align: right; font-weight: bold; }
        .totals-table .grand-total td { background-color: #0056b3; color: white; font-weight: bold; font-size: 14px; border: none; }
        
        .filters { margin-bottom: 20px; font-size: 10px; color: #666; background-color: #f4f6f9; padding: 10px; border-radius: 4px; border-left: 4px solid #0056b3; }
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
                    <div class="report-title">Historial de Cobros</div>
                    <div class="report-meta">
                        <strong>Fecha de Emisión:</strong> {{ date('d/m/Y') }}<br>
                        <strong>Hora:</strong> {{ date('H:i') }}
                    </div>
                </td>
            </tr>
        </table>
    </div>

    <div class="filters">
        <strong>Filtros aplicados:</strong> 
        @if(isset($filtros['fecha_inicio']) || isset($filtros['fecha_fin']))
            Periodo: {{ $filtros['fecha_inicio'] ?? '...' }} al {{ $filtros['fecha_fin'] ?? '...' }} &nbsp;|&nbsp;
        @endif
        Resultados: {{ count($pagos) }} registros.
    </div>

    <table class="data-table">
        <thead>
            <tr>
                <th>ID</th>
                <th>Fecha</th>
                <th>Cliente</th>
                <th>Proyecto</th>
                <th>Método de Pago</th>
                <th>Cuenta</th>
                <th class="text-right">Monto</th>
            </tr>
        </thead>
        <tbody>
            @forelse($pagos as $pago)
            <tr>
                <td>#{{ $pago->id }}</td>
                <td>{{ \Carbon\Carbon::parse($pago->fecha)->format('d/m/Y') }}</td>
                <td>{{ $pago->proyecto->client->name ?? $pago->proyecto->cliente ?? 'N/A' }}</td>
                <td>{{ $pago->proyecto->nombre ?? 'N/A' }}</td>
                <td>{{ $pago->metodo_pago }}</td>
                <td>{{ $pago->cuentaContable->nombre ?? 'N/A' }}</td>
                <td class="text-right" style="font-weight: bold;">${{ number_format($pago->monto, 2) }}</td>
            </tr>
            @empty
            <tr>
                <td colspan="7" class="text-center" style="padding: 20px;">No se encontraron registros de cobros con los filtros seleccionados.</td>
            </tr>
            @endforelse
        </tbody>
    </table>

    <div class="clearfix">
        <div class="totals-container">
            <table class="totals-table">
                <tr class="grand-total">
                    <td class="label" style="color: white;">GRAN TOTAL COBRADO:</td>
                    <td class="amount">${{ number_format($total, 2) }}</td>
                </tr>
            </table>
        </div>
    </div>

    <div class="footer">
        NEO PROJECT S.R.L - Reporte generado automáticamente el {{ date('d/m/Y') }} a las {{ date('H:i') }}
        <br><br><br>
        <div style="width: 200px; margin: 0 auto; border-top: 1px solid #333; padding-top: 5px;">
            Firma de Autorización / Revisión
        </div>
    </div>
</body>
</html>
