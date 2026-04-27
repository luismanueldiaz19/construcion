<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Reporte de Compras - Neo Project</title>
    <style>
        body { font-family: Arial, sans-serif; font-size: 10px; color: #333; margin: 0; padding: 0; }
        .header { width: 100%; border-bottom: 2px solid #003366; padding-bottom: 10px; margin-bottom: 20px; }
        .company-name { font-size: 20px; font-weight: bold; color: #003366; }
        .report-title { text-align: right; font-size: 16px; color: #555; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
        th { background-color: #003366; color: white; padding: 8px; text-align: left; }
        td { padding: 8px; border-bottom: 1px solid #ddd; }
        .text-right { text-align: right; }
        .grand-total { font-size: 14px; font-weight: bold; background-color: #f2f2f2; padding: 10px; text-align: right; border-top: 2px solid #003366; }
        .filters { margin-bottom: 15px; font-style: italic; color: #666; }
    </style>
</head>
<body>
    <div class="header">
        <table style="width: 100%; border: none;">
            <tr>
                <td style="border: none;">
                    <img src="{{ public_path('images/logo.png') }}" style="max-height: 50px;">
                    <div>Reporte General de Compras</div>
                </td>
                <td style="border: none;" class="text-right">
                    <div class="report-title">Historial de Compras</div>
                    <div>Fecha de Impresión: {{ date('d/m/Y H:i') }}</div>
                </td>
            </tr>
        </table>
    </div>

    <div class="filters">
        Filtros aplicados: 
        @if(isset($filtros['fecha_inicio']) || isset($filtros['fecha_fin']))
            Periodo: {{ $filtros['fecha_inicio'] ?? '...' }} al {{ $filtros['fecha_fin'] ?? '...' }} |
        @endif
        @if(isset($filtros['estado'])) Estado: {{ $filtros['estado'] }} | @endif
        Resultados: {{ count($compras) }} registros.
    </div>

    <table>
        <thead>
            <tr>
                <th>ID</th>
                <th>Fecha</th>
                <th>Proyecto</th>
                <th>Proveedor</th>
                <th>Tipo</th>
                <th>Estado</th>
                <th class="text-right">Subtotal</th>
                <th class="text-right">ITBIS</th>
                <th class="text-right">Total</th>
            </tr>
        </thead>
        <tbody>
            @foreach($compras as $compra)
            <tr>
                <td>#{{ $compra->id }}</td>
                <td>{{ \Carbon\Carbon::parse($compra->fecha)->format('d/m/Y') }}</td>
                <td>{{ $compra->proyecto->nombre ?? 'N/A' }}</td>
                <td>{{ $compra->proveedor->nombre ?? 'N/A' }}</td>
                <td>{{ $compra->tipo_compra }}</td>
                <td>{{ $compra->estado }}</td>
                <td class="text-right">${{ number_format($compra->subtotal, 2) }}</td>
                <td class="text-right">${{ number_format($compra->itbis, 2) }}</td>
                <td class="text-right" style="font-weight: bold;">${{ number_format($compra->total, 2) }}</td>
            </tr>
            @endforeach
        </tbody>
    </table>

    <div class="grand-total">
        GRAN TOTAL COMPRAS: ${{ number_format($total, 2) }}
    </div>
</body>
</html>
