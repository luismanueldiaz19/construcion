<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Reporte de Gastos - Neo Project</title>
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
                    <div>Reporte General de Gastos de Proyectos</div>
                </td>
                <td style="border: none;" class="text-right">
                    <div class="report-title">Historial de Gastos / Pagos</div>
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
        @if(isset($filtros['tipo_gasto'])) Tipo: {{ $filtros['tipo_gasto'] }} | @endif
        Resultados: {{ count($gastos) }} registros.
    </div>

    <table>
        <thead>
            <tr>
                <th>ID</th>
                <th>Fecha</th>
                <th>Proyecto</th>
                <th>Subpartida</th>
                <th>Tipo</th>
                <th>Beneficiario</th>
                <th>Descripción</th>
                <th>Método Pago</th>
                <th class="text-right">Monto</th>
            </tr>
        </thead>
        <tbody>
            @foreach($gastos as $gasto)
            <tr>
                <td>#{{ $gasto->id }}</td>
                <td>{{ \Carbon\Carbon::parse($gasto->fecha)->format('d/m/Y') }}</td>
                <td>{{ $gasto->proyecto->nombre ?? 'N/A' }}</td>
                <td>{{ $gasto->subpartida->descripcion ?? 'General' }}</td>
                <td>{{ $gasto->tipo_gasto }}</td>
                <td>{{ $gasto->proveedor->nombre ?? 'N/A' }}</td>
                <td>{{ $gasto->descripcion }}</td>
                <td>{{ $gasto->metodo_pago }}</td>
                <td class="text-right" style="font-weight: bold;">${{ number_format($gasto->monto, 2) }}</td>
            </tr>
            @endforeach
        </tbody>
    </table>

    <div class="grand-total">
        GRAN TOTAL GASTOS FILTRADOS: ${{ number_format($total, 2) }}
    </div>
</body>
</html>
