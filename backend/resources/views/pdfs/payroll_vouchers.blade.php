<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Vouchers de Nómina - {{ $payroll->period->name }}</title>
    <style>
        @page {
            size: 21.59cm 15.5cm; /* Un poco más alto que Half Letter para que quepa todo */
            margin: 0.8cm;
        }
        body { 
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; 
            font-size: 11px; 
            color: #333; 
            background-color: #fff;
            margin: 0;
            padding: 0;
        }
        .voucher-container {
            margin: 0 auto;
        }
        .voucher { 
            border: 1px solid #999; 
            padding: 15px; 
            box-sizing: border-box; 
            page-break-after: always; 
            page-break-inside: avoid;
        }
        .voucher:last-child {
            page-break-after: auto;
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
        .company-info h1 {
            margin: 0 0 5px 0;
            font-size: 18px;
            color: #2c3e50;
        }
        .company-info p {
            margin: 0;
            font-size: 11px;
            color: #555;
        }
        .voucher-title {
            display: table-cell;
            width: 50%;
            vertical-align: middle;
            text-align: right;
        }
        .voucher-title h2 { margin: 0 0 5px 0; font-size: 18px; color: #2c3e50; }
        .voucher-title p { margin: 0; font-size: 12px; color: #7f8c8d; }
        
        .employee-info { margin-bottom: 15px; }
        .employee-info table { width: 100%; }
        .employee-info td { padding: 3px 0; }
        
        .details-table { width: 100%; border-collapse: collapse; margin-bottom: 15px; }
        .details-table th, .details-table td { border: 1px solid #ddd; padding: 6px; text-align: right; }
        .details-table th { background-color: #f8f9fa; text-align: center; }
        .details-table td:first-child { text-align: left; }
        
        .totals { width: 100%; }
        .totals td { padding: 4px 0; text-align: right; }
        .totals strong { font-size: 14px; }
        
        .signatures { margin-top: 35px; width: 100%; text-align: center; }
        .sig-line { border-top: 1px solid #333; width: 250px; margin: 0 auto; padding-top: 5px; }
    </style>
</head>
<body>
    <div class="voucher-container">
        @foreach($employees as $employee)
            <div class="voucher">
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
                        <h2>Comprobante de Pago de Nómina</h2>
                        <p style="font-size: 14px; font-weight: bold; margin-bottom: 2px;">{{ $payroll->period->payrollGroup->name ?? 'Nómina' }}</p>
                        <p><strong>Período:</strong> {{ \Carbon\Carbon::parse($payroll->period->start_date)->format('d/m/Y') }} al {{ \Carbon\Carbon::parse($payroll->period->end_date)->format('d/m/Y') }}</p>
                        @if($payroll->paid_at)
                            <p><strong>Fecha de Pago:</strong> {{ \Carbon\Carbon::parse($payroll->paid_at)->format('d/m/Y') }}</p>
                        @endif
                    </div>
                </div>

                <div class="employee-info">
                    <table>
                        <tr>
                            <td><strong>Empleado:</strong> {{ $employee->first_name }} {{ $employee->last_name }}</td>
                            <td style="text-align: right;"></td>
                        </tr>
                        <tr>
                            <td><strong>Cargo:</strong> {{ $employee->position->title ?? 'N/A' }}</td>
                            <td style="text-align: right;"></td>
                        </tr>
                    </table>
                </div>

                <table class="details-table">
                    <thead>
                        <tr>
                            <th>Concepto</th>
                            <th>Ingresos</th>
                            <th>Deducciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        @php
                            $totalIngresos = 0;
                            $totalDeducciones = 0;
                        @endphp
                        @foreach($employee->payrollDetails as $detail)
                            @if($detail->type === 'ingreso' || $detail->type === 'deduccion')
                                @php
                                    $conceptName = $detail->concept->name;
                                    // Abreviar los nombres de los conceptos
                                    if (str_contains(strtoupper($conceptName), 'TSS')) {
                                        $conceptName = 'TSS';
                                    } elseif (str_contains(strtoupper($conceptName), 'AFP')) {
                                        $conceptName = 'AFP';
                                    } elseif (str_contains(strtoupper($conceptName), 'ISR')) {
                                        $conceptName = 'Imp./Renta';
                                    }
                                @endphp
                                <tr>
                                    <td>{{ $conceptName }}</td>
                                    <td>{{ $detail->type === 'ingreso' ? 'RD$ ' . number_format($detail->amount, 2) : '' }}</td>
                                    <td>{{ $detail->type === 'deduccion' ? 'RD$ ' . number_format($detail->amount, 2) : '' }}</td>
                                </tr>
                                @php
                                    if ($detail->type === 'ingreso') $totalIngresos += $detail->amount;
                                    if ($detail->type === 'deduccion') $totalDeducciones += $detail->amount;
                                @endphp
                            @endif
                        @endforeach
                    </tbody>
                </table>

                <table class="totals">
                    <tr>
                        <td style="width: 70%;">Pago Bruto:</td>
                        <td>RD$ {{ number_format($totalIngresos, 2) }}</td>
                    </tr>
                    <tr>
                        <td>Total Deducciones:</td>
                        <td>- RD$ {{ number_format($totalDeducciones, 2) }}</td>
                    </tr>
                    <tr>
                        <td><strong>PAGO NETO:</strong></td>
                        <td><strong>RD$ {{ number_format($totalIngresos - $totalDeducciones, 2) }}</strong></td>
                    </tr>
                </table>

                <div class="signatures">
                    <div class="sig-line">Firma de Recibido conforme</div>
                </div>
            </div>
        @endforeach
    </div>
</body>
</html>
