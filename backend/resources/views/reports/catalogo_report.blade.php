<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Reporte de Catálogo de Cuentas - Neo Project</title>
    <style>
        body { font-family: 'Helvetica', Arial, sans-serif; font-size: 11px; color: #333; margin: 0; padding: 0; }
        .header { width: 100%; border-bottom: 2px solid #6610f2; padding-bottom: 15px; margin-bottom: 25px; }
        table { width: 100%; border-collapse: collapse; }
        .company-info { text-align: left; vertical-align: top; }
        .company-name { font-size: 22px; font-weight: bold; color: #6610f2; margin-bottom: 5px; }
        .company-details { font-size: 10px; color: #555; line-height: 1.4; }
        .report-info { text-align: right; vertical-align: top; }
        .report-title { font-size: 18px; font-weight: bold; color: #333; margin-bottom: 5px; text-transform: uppercase; }
        .report-meta { font-size: 10px; color: #555; line-height: 1.4; }
        
        .data-table { width: 100%; border-collapse: collapse; margin-bottom: 30px; }
        .data-table th { background-color: #6610f2; color: white; padding: 10px 8px; text-align: left; font-size: 11px; text-transform: uppercase; }
        .data-table td { padding: 9px 8px; border-bottom: 1px solid #e0e0e0; }
        .data-table tbody tr:nth-child(even) { background-color: #f9f9f9; }
        .text-right { text-align: right; }
        .text-center { text-align: center; }
        
        .badge { padding: 4px 8px; border-radius: 4px; font-size: 9px; font-weight: bold; color: white; text-transform: uppercase; }
        .badge-ventas { background-color: #28a745; }
        .badge-costos { background-color: #dc3545; }
        .badge-gastos { background-color: #fd7e14; }

        .filters { margin-bottom: 20px; font-size: 10px; color: #666; background-color: #f4f6f9; padding: 10px; border-radius: 4px; border-left: 4px solid #6610f2; }
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
                    <div class="report-title">Catálogo de Cuentas</div>
                    <div class="report-meta">
                        @if(isset($origen))
                            <strong>Filtro Origen:</strong> {{ $origen }}<br>
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
                <th style="width: 20%;">Código</th>
                <th style="width: 50%;">Descripción</th>
                <th style="width: 30%;" class="text-center">Origen</th>
            </tr>
        </thead>
        <tbody>
            @forelse($cuentas as $cuenta)
            <tr>
                <td style="font-weight: bold;">{{ $cuenta->codigo }}</td>
                <td>{{ $cuenta->descripcion }}</td>
                <td class="text-center">
                    <span class="badge badge-{{ strtolower($cuenta->origen) }}">{{ $cuenta->origen }}</span>
                </td>
            </tr>
            @empty
            <tr>
                <td colspan="3" class="text-center" style="padding: 20px;">No hay cuentas registradas en el catálogo.</td>
            </tr>
            @endforelse
        </tbody>
    </table>

    <div class="footer">
        NEO PROJECT S.R.L - Reporte generado automáticamente el {{ date('d/m/Y H:i') }}
    </div>
</body>
</html>
