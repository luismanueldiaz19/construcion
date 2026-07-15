<?php

namespace App\Services;

use App\Models\Employee;
use App\Models\Payroll;
use App\Models\PayrollDetail;
use App\Models\PayrollLoan;
use App\Models\EmployeeSalaryHistory;
use Illuminate\Support\Facades\DB;

class NominaReportService
{
    /**
     * Obtiene los datos para la Nómina Consolidada por periodo.
     */
    public function getNominaConsolidada(int $payrollId): array
    {
        $payroll = Payroll::with(['period.payrollGroup'])->findOrFail($payrollId);

        $details = PayrollDetail::where('payroll_id', $payroll->id)
            ->with(['employee.department', 'concept'])
            ->get()
            ->groupBy('employee_id');

        $rows = [];
        $totals = [
            'sal_base' => 0, 'he_var' => 0, 'bruto' => 0, 'tss_sfs' => 0,
            'afp' => 0, 'isr' => 0, 'prestamo' => 0, 'total_ded' => 0,
            'neto' => 0, 'patronal' => 0
        ];

        foreach ($details as $employeeId => $empDetails) {
            $employee   = $empDetails->first()->employee;
            $byCode     = $empDetails->keyBy(fn($d) => $d->concept?->code);
            $ingresos   = $empDetails->where('type', 'ingreso');
            $deducciones = $empDetails->where('type', 'deduccion');
            $patronal   = $empDetails->where('type', 'aporte_patronal');

            $salBase  = (float)($byCode['SAL_BASE']->amount  ?? 0);
            $heVar    = $ingresos->whereNotIn('payroll_concept_id', [1])->sum('amount');
            $bruto    = $ingresos->sum('amount');
            $tssSFS   = (float)($byCode['DED_TSS_SFS']->amount ?? 0);
            $afp      = (float)($byCode['DED_AFP']->amount     ?? 0);
            $isr      = (float)($byCode['DED_ISR']->amount     ?? 0);
            $prestamo = (float)($byCode['DED_PRESTAMO']->amount ?? 0);
            $totalDed = $deducciones->sum('amount');
            $neto     = $bruto - $totalDed;
            $patronalTotal = $patronal->sum('amount');

            $totals['sal_base'] += $salBase;
            $totals['he_var'] += $heVar;
            $totals['bruto'] += $bruto;
            $totals['tss_sfs'] += $tssSFS;
            $totals['afp'] += $afp;
            $totals['isr'] += $isr;
            $totals['prestamo'] += $prestamo;
            $totals['total_ded'] += $totalDed;
            $totals['neto'] += $neto;
            $totals['patronal'] += $patronalTotal;

            $rows[] = [
                'codigo' => $employee->employee_code,
                'empleado' => $employee->full_name,
                'departamento' => $employee->department?->name ?? '—',
                'sal_base' => $salBase,
                'he_var' => $heVar,
                'bruto' => $bruto,
                'tss_sfs' => $tssSFS,
                'afp' => $afp,
                'isr' => $isr,
                'prestamo' => $prestamo,
                'total_ded' => $totalDed,
                'neto' => $neto,
                'patronal' => $patronalTotal,
            ];
        }

        return [
            'meta' => [
                'title' => 'NÓMINA CONSOLIDADA — ' . strtoupper($payroll->period->payrollGroup->name),
                'subtitle' => "Periodo: {$payroll->period->start_date} al {$payroll->period->end_date} | Pago: {$payroll->period->payment_date}",
            ],
            'rows' => $rows,
            'totals' => $totals,
        ];
    }

    /**
     * Obtiene los datos para Planilla TSS.
     */
    public function getPlanillaTSS(int $payrollId): array
    {
        $payroll = Payroll::with(['period.payrollGroup'])->findOrFail($payrollId);

        $details = PayrollDetail::where('payroll_id', $payroll->id)
            ->whereHas('concept', fn($q) => $q->whereIn('code', ['DED_TSS_SFS', 'DED_AFP', 'PAT_TSS_SFS', 'PAT_AFP', 'PAT_SRL']))
            ->with(['employee.afp', 'employee.ars', 'concept'])
            ->get()
            ->groupBy('employee_id');

        $rows = [];
        $totals = [
            'sal_cotizable' => 0, 'afp_emp' => 0, 'sfs_emp' => 0, 'afp_patron' => 0, 'sfs_patron' => 0
        ];
        $num = 1;

        foreach ($details as $employeeId => $empDetails) {
            $employee = $empDetails->first()->employee;
            $byCode   = $empDetails->keyBy(fn($d) => $d->concept?->code);
            $salBase  = Employee::find($employeeId)?->base_salary ?? 0;

            $afpEmp = (float)($byCode['DED_AFP']->amount ?? 0);
            $sfsEmp = (float)($byCode['DED_TSS_SFS']->amount ?? 0);
            $afpPatron = (float)($byCode['PAT_AFP']->amount ?? 0);
            $sfsPatron = (float)($byCode['PAT_TSS_SFS']->amount ?? 0);

            $totals['sal_cotizable'] += $salBase;
            $totals['afp_emp'] += $afpEmp;
            $totals['sfs_emp'] += $sfsEmp;
            $totals['afp_patron'] += $afpPatron;
            $totals['sfs_patron'] += $sfsPatron;

            $rows[] = [
                'num' => $num++,
                'no_tss' => $employee->tss_number ?? 'N/A',
                'nombre' => $employee->full_name,
                'afp' => $employee->afp?->name ?? 'N/A',
                'ars' => $employee->ars?->name ?? 'N/A',
                'sal_cotizable' => $salBase,
                'afp_emp' => $afpEmp,
                'sfs_emp' => $sfsEmp,
                'afp_patron' => $afpPatron,
                'sfs_patron' => $sfsPatron,
            ];
        }

        return [
            'meta' => [
                'title' => 'PLANILLA TSS — TESORERÍA DE LA SEGURIDAD SOCIAL',
                'subtitle' => "Periodo: {$payroll->period->start_date} al {$payroll->period->end_date}",
            ],
            'rows' => $rows,
            'totals' => $totals,
        ];
    }

    /**
     * Obtiene los datos para Retenciones ISR.
     */
    public function getRetencionesISR(int $payrollId): array
    {
        $payroll = Payroll::with('period.payrollGroup')->findOrFail($payrollId);

        $isrDetails = PayrollDetail::where('payroll_id', $payroll->id)
            ->whereHas('concept', fn($q) => $q->where('code', 'DED_ISR'))
            ->with(['employee.department'])
            ->get();

        $rows = [];
        $totals = ['ingreso_bruto' => 0, 'isr_retenido' => 0, 'isr_anualizado' => 0];

        foreach ($isrDetails as $detail) {
            $employee   = $detail->employee;
            $bruto      = PayrollDetail::where('payroll_id', $payroll->id)
                ->where('employee_id', $employee->id)->where('type', 'ingreso')->sum('amount');
            $periodsYear = $payroll->period->payrollGroup->periods_per_year ?? 12;
            $isrAnual   = $detail->amount * $periodsYear;

            $totals['ingreso_bruto'] += $bruto;
            $totals['isr_retenido'] += $detail->amount;
            $totals['isr_anualizado'] += $isrAnual;

            $rows[] = [
                'codigo' => $employee->employee_code,
                'empleado' => $employee->full_name,
                'departamento' => $employee->department?->name ?? '—',
                'ingreso_bruto' => $bruto,
                'isr_retenido' => $detail->amount,
                'isr_anualizado' => $isrAnual,
            ];
        }

        return [
            'meta' => [
                'title' => 'REPORTE DE RETENCIONES ISR — ' . $payroll->period->start_date . ' al ' . $payroll->period->end_date,
                'subtitle' => '',
            ],
            'rows' => $rows,
            'totals' => $totals,
        ];
    }

    /**
     * Obtiene los datos para Provisiones Acumuladas.
     */
    public function getProvisiones(string $from, string $to): array
    {
        $provCodes = ['PROV_REGALIA', 'PROV_VACACIONES', 'PROV_CESANTIA'];
        $data = PayrollDetail::whereHas('concept', fn($q) => $q->whereIn('code', $provCodes))
            ->whereHas('payroll', function ($q) use ($from, $to) {
                $q->whereHas('period', fn($p) => $p->whereBetween('payment_date', [$from, $to]));
            })
            ->with(['employee.department', 'concept'])
            ->get()
            ->groupBy('employee_id');

        $rows = [];
        $totals = ['regalia' => 0, 'vacaciones' => 0, 'cesantia' => 0, 'total' => 0];

        foreach ($data as $employeeId => $empDetails) {
            $employee  = $empDetails->first()->employee;
            $byCode    = $empDetails->groupBy(fn($d) => $d->concept?->code)->map(fn($g) => $g->sum('amount'));

            $reg = (float)($byCode['PROV_REGALIA']    ?? 0);
            $vac = (float)($byCode['PROV_VACACIONES'] ?? 0);
            $ces = (float)($byCode['PROV_CESANTIA']   ?? 0);
            $tot = $reg + $vac + $ces;

            $totals['regalia'] += $reg;
            $totals['vacaciones'] += $vac;
            $totals['cesantia'] += $ces;
            $totals['total'] += $tot;

            $rows[] = [
                'codigo' => $employee->employee_code,
                'empleado' => $employee->full_name,
                'departamento' => $employee->department?->name ?? '—',
                'prov_regalia' => $reg,
                'prov_vacaciones' => $vac,
                'prov_cesantia' => $ces,
                'total_prov' => $tot,
            ];
        }

        return [
            'meta' => [
                'title' => "PROVISIONES LABORALES ACUMULADAS",
                'subtitle' => "Del $from al $to",
            ],
            'rows' => $rows,
            'totals' => $totals,
        ];
    }

    /**
     * Obtiene los datos para Historial de Salarios.
     */
    public function getHistorialSalarios(?int $employeeId, ?string $from, ?string $to): array
    {
        $query = EmployeeSalaryHistory::with(['employee.department', 'approvedBy'])
            ->when($employeeId, fn($q, $id) => $q->where('employee_id', $id))
            ->when($from, fn($q, $d) => $q->whereDate('effective_date', '>=', $d))
            ->when($to,   fn($q, $d) => $q->whereDate('effective_date', '<=', $d))
            ->orderByDesc('effective_date');

        $records = $query->get();

        $rows = [];
        foreach ($records as $record) {
            $diff = $record->new_salary - $record->previous_salary;
            $rows[] = [
                'empleado' => $record->employee->full_name,
                'codigo' => $record->employee->employee_code,
                'departamento' => $record->employee->department?->name ?? '—',
                'fecha_efectiva' => $record->effective_date->format('Y-m-d'),
                'salario_anterior' => $record->previous_salary,
                'salario_nuevo' => $record->new_salary,
                'diferencia' => $diff,
                'motivo' => $record->reason,
                'aprobado_por' => $record->approvedBy?->name ?? 'Sistema',
            ];
        }

        $subtitle = '';
        if ($from && $to) {
            $subtitle = "Del $from al $to";
        } elseif ($from) {
            $subtitle = "Desde $from";
        } elseif ($to) {
            $subtitle = "Hasta $to";
        }

        return [
            'meta' => [
                'title' => 'HISTORIAL DE CAMBIOS SALARIALES',
                'subtitle' => $subtitle,
            ],
            'rows' => $rows,
            'totals' => [], // No hay totales para esto
        ];
    }
}
