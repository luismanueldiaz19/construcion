<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Historial de Pagos de Obligaciones</title>
    <style>
        @page { margin: 1cm; }
        body { 
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; 
            font-size: 11px; 
            color: #333; 
            background-color: #fff;
            margin: 0;
            padding: 0;
        }
        .header { 
            display: table;
            width: 100%;
            margin-bottom: 20px; 
            border-bottom: 1px solid #ddd; 
            padding-bottom: 10px; 
        }
        .company-info {
            display: table-cell;
            width: 50%;
            vertical-align: middle;
            text-align: left;
        }
        .voucher-title {
            display: table-cell;
            width: 50%;
            vertical-align: middle;
            text-align: right;
        }
        .voucher-title h2 { margin: 0 0 5px 0; font-size: 18px; color: #2c3e50; }
        .voucher-title p { margin: 0; font-size: 12px; color: #7f8c8d; }
        
        table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        th, td { border: 1px solid #ddd; padding: 6px; text-align: left; }
        th { background-color: #f8f9fa; font-weight: bold; text-align: center; }
        .text-right { text-align: right; }
        .text-center { text-align: center; }
    </style>
</head>
<body>
    <div class="header">
        <div class="company-info">
            @php
                $imagePath = public_path('assets/assets/logo.png');
                $logoBase64 = '';
                if(file_exists($imagePath)) {
                    $logoBase64 = 'data:image/png;base64,' . base64_encode(file_get_contents($imagePath));
                }
            @endphp
            @if($logoBase64)
                <img src="{{ $logoBase64 }}" style="max-height: 60px; max-width: 140px; object-fit: contain; margin-bottom: 5px;">
            @endif
            <div style="font-weight: bold; font-size: 14px; color: #555;">NEO PROJECT S.R.L</div>
            <div style="font-size: 11px; color: #777;">
                RNC: 131181181 | Manolo Tavares Justo No. 15<br>
                Tel: 809-320-1668 | Cel: 809-223-8039
            </div>
        </div>
        <div class="voucher-title">
            <h2>Historial de Pagos de Obligaciones Fiscales</h2>
            <p><strong>Fecha de reporte:</strong> {{ date('d/m/Y') }}</p>
            @if(isset($startDate) && isset($endDate))
                <p><strong>Período:</strong> {{ date('d/m/Y', strtotime($startDate)) }} al {{ date('d/m/Y', strtotime($endDate)) }}</p>
            @else
                <p><strong>Período:</strong> Todos los registros</p>
            @endif
        </div>
    </div>

    <table>
        <thead>
            <tr>
                <th class="text-center">Fecha</th>
                <th>Referencia</th>
                <th>Cuenta Pagada</th>
                <th>Banco / Origen</th>
                <th class="text-right">Monto (RD$)</th>
            </tr>
        </thead>
        <tbody>
            @php $total = 0; @endphp
            @foreach($pagos as $pago)
                @php
                    $detallePago = collect($pago->detalles)->first(function($d) {
                        return $d->debe > 0 && optional($d->cuenta)->tipo == 'Pasivo';
                    });
                    $detalleBanco = collect($pago->detalles)->first(function($d) {
                        return $d->haber > 0 && optional($d->cuenta)->tipo == 'Activo';
                    });
                    
                    $nombreObligacion = $detallePago ? optional($detallePago->cuenta)->nombre : 'Obligación';
                    $nombreBanco = $detalleBanco ? optional($detalleBanco->cuenta)->nombre : 'Banco';
                    $monto = $detalleBanco ? $detalleBanco->haber : 0;
                    $total += $monto;
                @endphp
                <tr>
                    <td class="text-center">{{ date('d/m/Y', strtotime($pago->fecha)) }}</td>
                    <td>{{ $pago->glosa }}</td>
                    <td>{{ $nombreObligacion }}</td>
                    <td>{{ $nombreBanco }}</td>
                    <td class="text-right">{{ number_format($monto, 2) }}</td>
                </tr>
            @endforeach
        </tbody>
        <tfoot>
            <tr>
                <th colspan="4" class="text-right">TOTAL PAGADO:</th>
                <th class="text-right">{{ number_format($total, 2) }}</th>
            </tr>
        </tfoot>
    </table>
</body>
</html>
