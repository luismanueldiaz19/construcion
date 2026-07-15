<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Vouchers de Nómina - {{ $payroll->period->name }}</title>
    <style>
        body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; font-size: 12px; color: #333; }
        .voucher { width: 100%; border: 1px dashed #999; padding: 20px; margin-bottom: 30px; box-sizing: border-box; page-break-inside: avoid; }
        .header { text-align: center; margin-bottom: 20px; border-bottom: 1px solid #ddd; padding-bottom: 10px; }
        .header h2 { margin: 0 0 5px 0; font-size: 18px; color: #2c3e50; }
        .header p { margin: 0; font-size: 12px; color: #7f8c8d; }
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
        .signatures { margin-top: 40px; width: 100%; text-align: center; }
        .signatures td { width: 50%; padding-top: 30px; }
        .sig-line { border-top: 1px solid #333; width: 200px; margin: 0 auto; padding-top: 5px; }
    </style>
</head>
<body>
    @foreach($employees as $employee)
        <div class="voucher">
            <div class="header">
                <h2>Volante de Pago (Voucher)</h2>
                <p>Nómina: {{ $payroll->period->name }} | Fecha de Pago: {{ $payroll->paid_at ? \Carbon\Carbon::parse($payroll->paid_at)->format('d/m/Y') : 'Pendiente' }}</p>
            </div>

            <div class="employee-info">
                <table>
                    <tr>
                        <td><strong>Empleado:</strong> {{ $employee->first_name }} {{ $employee->last_name }}</td>
                        <td style="text-align: right;"><strong>Identificación:</strong> {{ $employee->identification_number }}</td>
                    </tr>
                    <tr>
                        <td><strong>Posición:</strong> {{ $employee->position->name ?? 'N/A' }}</td>
                        <td style="text-align: right;"><strong>Salario Base:</strong> RD$ {{ number_format($employee->base_salary, 2) }}</td>
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
                            <tr>
                                <td>{{ $detail->concept->name }}</td>
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
                    <td style="width: 70%;">Total Ingresos:</td>
                    <td>RD$ {{ number_format($totalIngresos, 2) }}</td>
                </tr>
                <tr>
                    <td>Total Deducciones:</td>
                    <td>- RD$ {{ number_format($totalDeducciones, 2) }}</td>
                </tr>
                <tr>
                    <td><strong>NETO A PAGAR:</strong></td>
                    <td><strong>RD$ {{ number_format($totalIngresos - $totalDeducciones, 2) }}</strong></td>
                </tr>
            </table>

            <table class="signatures">
                <tr>
                    <td>
                        <div class="sig-line">Firma del Empleador</div>
                    </td>
                    <td>
                        <div class="sig-line">Firma del Empleado (Recibí Conforme)</div>
                    </td>
                </tr>
            </table>
        </div>
    @endforeach
</body>
</html>
