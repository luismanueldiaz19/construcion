<?php

namespace App\Services;

use App\Models\Employee;
use App\Models\Payroll;
use App\Models\PayrollPeriod;
use App\Models\PayrollDetail;
use App\Models\PayrollLegalParameter;
use App\Models\PayrollConcept;
use App\Models\PayrollLoan;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

/**
 * TAREA 06 — PayrollCalculationService
 *
 * Motor de cálculo de nómina DESACOPLADO del controlador.
 * Nunca instanciar lógica de cálculo en controladores ni en modelos.
 *
 * Secuencia de cálculo por empleado:
 *  1. Salario base prorrateado (si el periodo no es completo)
 *  2. Ingresos variables (horas extras, comisiones — capturados en el periodo)
 *  3. Salario cotizable TSS (base sobre la que se aplican % TSS)
 *  4. Deducciones TSS empleado (SFS + AFP)
 *  5. ISR:
 *     a. Anualizar ingreso gravable
 *     b. Aplicar tabla progresiva del año fiscal vigente
 *     c. Prorratear al periodo (÷52, ÷24, ÷12)
 *  6. Otras deducciones (préstamos, ausencias, embargos)
 *  7. Neto a pagar = Bruto - Todas las deducciones
 *  8. Aportes patronales y provisiones (gasto empresa, no afecta neto del empleado)
 *  9. Persistir en payroll_details (desglosado por concepto — NUNCA solo totales)
 * 10. Recalcular totales en la cabecera payrolls
 */
class PayrollCalculationService
{
    // Cache de conceptos y parámetros para no consultar N veces la BD en cada empleado
    private array $conceptsCache = [];
    private array $paramsCache   = [];

    // ─────────────────────────────────────────────────
    //  PUNTO DE ENTRADA PRINCIPAL
    // ─────────────────────────────────────────────────

    /**
     * Calcula la nómina completa para un periodo dado.
     * Envuelve todo en una transacción DB — si algo falla, nada se persiste.
     *
     * @param  Payroll      $payroll  La cabecera ya creada (status = borrador)
     * @param  array        $extras   ['employee_id' => ['HE_DIURNA' => horas, 'COMISION' => monto, ...]]
     * @param  Carbon|null  $date     Fecha de referencia para parámetros legales (default: hoy)
     * @return Payroll
     */
    public function calculate(Payroll $payroll, array $extras = [], ?Carbon $date = null): Payroll
    {
        $date = $date ?? now();

        DB::transaction(function () use ($payroll, $extras, $date) {
            // Eliminar cálculos previos si se está recalculando
            $payroll->details()->delete();

            $period    = $payroll->period()->with('payrollGroup')->firstOrFail();
            $employees = $this->getActiveEmployees($period);

            $this->loadCache($date);

            $totals = [
                'total_gross'         => 0,
                'total_deductions'    => 0,
                'total_net'           => 0,
                'total_employer_cost' => 0,
                'total_isr'           => 0,
                'total_tss_employee'  => 0,
                'total_tss_employer'  => 0,
            ];

            foreach ($employees as $employee) {
                $employeeExtras = $extras[$employee->id] ?? [];
                $result = $this->calculateEmployee($payroll, $employee, $period, $date, $employeeExtras);

                $totals['total_gross']         += $result['gross'];
                $totals['total_deductions']    += $result['deductions'];
                $totals['total_net']           += $result['net'];
                $totals['total_employer_cost'] += $result['employer_cost'];
                $totals['total_isr']           += $result['isr'];
                $totals['total_tss_employee']  += $result['tss_employee'];
                $totals['total_tss_employer']  += $result['tss_employer'];
            }

            $payroll->update(array_merge($totals, [
                'status'       => 'calculado',
                'processed_at' => now(),
            ]));
        });

        return $payroll->fresh();
    }

    // ─────────────────────────────────────────────────
    //  CÁLCULO POR EMPLEADO
    // ─────────────────────────────────────────────────

    private function calculateEmployee(
        Payroll $payroll,
        Employee $employee,
        PayrollPeriod $period,
        Carbon $date,
        array $extras
    ): array {
        $detailsToInsert = [];
        $periodsPerYear  = $period->payrollGroup->periods_per_year;

        // ── PASO 1: Salario base prorrateado ──
        $grossSalary = $this->calculateProratedSalary($employee, $period);
        $detailsToInsert[] = $this->makeDetail($payroll, $employee, 'SAL_BASE', 'ingreso', $grossSalary);

        // ── PASO 2: Ingresos variables (horas extras, comisiones, etc.) ──
        $variableIncome = 0;
        foreach ($extras as $conceptCode => $value) {
            $concept = $this->getConcept($conceptCode);
            if (!$concept || $concept->type !== 'ingreso') {
                continue;
            }

            $amount = $this->resolveVariableAmount($employee, $conceptCode, $value, $grossSalary);
            if ($amount > 0) {
                $detailsToInsert[] = $this->makeDetail($payroll, $employee, $conceptCode, 'ingreso', $amount);
                $variableIncome   += $amount;
            }
        }

        $totalGross = $grossSalary + $variableIncome;

        // ── PASO 3: Salario cotizable TSS ──
        // Aplica tope si existe (actualmente sin tope fijo en RD para estos %)
        $taxableSalaryTSS = $totalGross; // Ajustar si hay tope configurado

        // ── PASO 4: Deducciones TSS empleado ──
        $tssSFS = 0;
        $tssAFP = 0;
        $tssEmployee = 0;
        
        if (!$employee->is_tss_exempt) {
            $tssSFS = $this->applyPercentage($taxableSalaryTSS, 'TSS_EMPLEADO_SFS', $date);
            $tssAFP = $this->applyPercentage($taxableSalaryTSS, 'TSS_EMPLEADO_AFP', $date);
            $tssEmployee = $tssSFS + $tssAFP;

            $detailsToInsert[] = $this->makeDetail($payroll, $employee, 'DED_TSS_SFS', 'deduccion', $tssSFS);
            $detailsToInsert[] = $this->makeDetail($payroll, $employee, 'DED_AFP',     'deduccion', $tssAFP);
        }

        // ── PASO 5: ISR — siempre sobre base anualizada ──
        $isr = 0;
        if (!$employee->is_isr_exempt) {
            // Base gravable = ingresos taxables - deducciones TSS (RD permite deducir TSS del ISR)
            $taxableForISR  = $this->getTaxableIncome($detailsToInsert, $totalGross);
            $annualizedIncome = $taxableForISR * $periodsPerYear;
            $annualISR      = $this->calculateISR($annualizedIncome, $date);
            $isr            = round($annualISR / $periodsPerYear, 2);

            if ($isr > 0) {
                $detailsToInsert[] = $this->makeDetail($payroll, $employee, 'DED_ISR', 'deduccion', $isr);
            }
        }

        // ── PASO 6: Otras deducciones (préstamos, embargos, ausencias) ──
        $otherDeductions = 0;
        $loans = PayrollLoan::where('employee_id', $employee->id)
            ->where('status', 'activo')
            ->where('outstanding_balance', '>', 0)
            ->get();

        foreach ($loans as $loan) {
            $installment = min($loan->monthly_installment, $loan->outstanding_balance);
            if ($installment > 0) {
                $detailsToInsert[]  = $this->makeDetail($payroll, $employee, 'DED_PRESTAMO', 'deduccion', $installment, ['notes' => "Préstamo #{$loan->id}"]);
                $otherDeductions   += $installment;
            }
        }

        // ── PASO 7: Neto a pagar ──
        $totalDeductions = $tssEmployee + $isr + $otherDeductions;
        $netPay          = round($totalGross - $totalDeductions, 2);

        // ── PASO 8: Aportes patronales (gasto empresa, no afectan neto del empleado) ──
        $patSFS = 0;
        $patAFP = 0;
        $patSRL = 0;
        
        if (!$employee->is_tss_exempt) {
            $patSFS  = $this->applyPercentage($taxableSalaryTSS, 'TSS_PATRONAL_SFS', $date);
            $patAFP  = $this->applyPercentage($taxableSalaryTSS, 'TSS_PATRONAL_AFP', $date);
            $patSRL  = $this->applyPercentage($taxableSalaryTSS, 'TSS_PATRONAL_SRL', $date);
        }
        
        $infotep = $this->applyPercentage($totalGross,       'INFOTEP',          $date);

        $provRegalia   = round($totalGross / 12, 2);   // 8.33% del bruto
        $provVacaciones = round($totalGross * 0.0416, 2); // ~4.16% del bruto
        
        $months = Carbon::parse($employee->hire_date)->diffInMonths(now());
        $cesantiaPercent = match(true) {
            $months < 3  => 0,
            $months < 6  => 0.017,
            $months < 12 => 0.036,
            $months < 60 => 0.058,
            default       => 0.063,
        };
        $provCesantia  = round($totalGross * $cesantiaPercent, 2);

        $tssEmployer = $patSFS + $patAFP + $patSRL;
        $employerCost = $totalGross + $tssEmployer + $infotep + $provRegalia + $provVacaciones + $provCesantia;

        $patronalDetails = [
            ['PAT_TSS_SFS',     $patSFS],
            ['PAT_AFP',         $patAFP],
            ['PAT_SRL',         $patSRL],
            ['PAT_INFOTEP',     $infotep],
            ['PROV_REGALIA',    $provRegalia],
            ['PROV_VACACIONES', $provVacaciones],
            ['PROV_CESANTIA',   $provCesantia],
        ];

        foreach ($patronalDetails as [$code, $amount]) {
            if ($amount > 0) {
                $detailsToInsert[] = $this->makeDetail($payroll, $employee, $code, 'aporte_patronal', $amount);
            }
        }

        // ── PASO 9: Persistir todos los detalles de golpe ──
        $now = now()->toDateTimeString();
        $rows = array_map(fn($d) => array_merge($d, ['created_at' => $now, 'updated_at' => $now]), $detailsToInsert);
        PayrollDetail::insert($rows);

        return [
            'gross'        => $totalGross,
            'deductions'   => $totalDeductions,
            'net'          => $netPay,
            'employer_cost'=> $employerCost,
            'isr'          => $isr,
            'tss_employee' => $tssEmployee,
            'tss_employer' => $tssEmployer,
        ];
    }

    // ─────────────────────────────────────────────────
    //  HELPERS DE CÁLCULO
    // ─────────────────────────────────────────────────

    /**
     * Prorratear el salario si el empleado ingresó o salió a mitad del periodo.
     */
    private function calculateProratedSalary(Employee $employee, PayrollPeriod $period): float
    {
        $startDate = Carbon::parse($period->start_date);
        $endDate   = Carbon::parse($period->end_date);
        $hireDate  = Carbon::parse($employee->hire_date);

        // Convertir salario mensual a salario del periodo según frecuencia (ej. quincenal = salario / 2)
        $periodsPerYear = $period->payrollGroup->periods_per_year ?? 12;
        $periodSalary = $employee->base_salary / ($periodsPerYear / 12);

        $effectiveStart = $hireDate->gt($startDate) ? $hireDate : $startDate;
        $totalDays      = $startDate->diffInDays($endDate) + 1;
        $workedDays     = $effectiveStart->diffInDays($endDate) + 1;

        if ($workedDays >= $totalDays) {
            return round((float) $periodSalary, 2);
        }

        return round(($periodSalary / $totalDays) * $workedDays, 2);
    }

    /**
     * Calcula el monto de un ingreso variable dado su tipo y valor de entrada.
     * Para horas extras, value = número de horas; se resuelve la tarifa según ley.
     */
    private function resolveVariableAmount(Employee $employee, string $code, $value, float $baseSalary): float
    {
        // Tarifa por hora = salario mensual / (días_por_semana * horas_por_día * semanas_promedio)
        $hourlyRate = $baseSalary / (5 * 8 * 4.33); // aproximación estándar

        return match ($code) {
            'HE_DIURNA'   => round($hourlyRate * 1.35 * (float)$value, 2), // +35%
            'HE_NOCTURNA' => round($hourlyRate * 1.50 * (float)$value, 2), // +50%
            'HE_FESTIVO'  => round($hourlyRate * 2.00 * (float)$value, 2), // +100%
            default        => round((float)$value, 2),  // monto directo (comisiones, bonos, etc.)
        };
    }

    /**
     * Calcula ISR anual según escala progresiva RD.
     * La escala está en payroll_legal_parameters (versionada por año).
     *
     * Tramos aproximados 2026:
     *  ≤ 416,220      → 0%
     *  416,220–624,329 → 15% sobre el excedente
     *  624,329–867,123 → 20% sobre el excedente
     *  > 867,123       → 25% sobre el excedente
     */
    public function calculateISR(float $annualizedIncome, Carbon $date): float
    {
        $exento  = (float) ($this->paramsCache['ISR_EXENTO_ANUAL']  ?? 416220.00);
        $tramo2  = (float) ($this->paramsCache['ISR_TRAMO_2_TASA']  ?? 15.00);
        $cap2    = (float) ($this->paramsCache['ISR_TRAMO_2_CAP']   ?? 624329.00);
        $tramo3  = (float) ($this->paramsCache['ISR_TRAMO_3_TASA']  ?? 20.00);
        $cap3    = (float) ($this->paramsCache['ISR_TRAMO_3_CAP']   ?? 867123.00);
        $tramo4  = (float) ($this->paramsCache['ISR_TRAMO_4_TASA']  ?? 25.00);

        if ($annualizedIncome <= $exento) {
            return 0.00;
        }

        $isr = 0;

        if ($annualizedIncome <= $cap2) {
            $isr = ($annualizedIncome - $exento) * ($tramo2 / 100);
        } elseif ($annualizedIncome <= $cap3) {
            $isr  = ($cap2 - $exento)           * ($tramo2 / 100);
            $isr += ($annualizedIncome - $cap2)  * ($tramo3 / 100);
        } else {
            $isr  = ($cap2 - $exento)  * ($tramo2 / 100);
            $isr += ($cap3 - $cap2)    * ($tramo3 / 100);
            $isr += ($annualizedIncome - $cap3) * ($tramo4 / 100);
        }

        return round($isr, 2);
    }

    /**
     * Aplica un porcentaje desde la tabla de parámetros legales.
     */
    private function applyPercentage(float $base, string $paramCode, Carbon $date): float
    {
        $rate = (float) ($this->paramsCache[$paramCode] ?? 0);
        return round($base * ($rate / 100), 2);
    }

    /**
     * Base gravable para ISR = suma de ingresos taxable_isr = true,
     * descontando las deducciones TSS del empleado (RD permite esta deducción).
     */
    private function getTaxableIncome(array $details, float $totalGross): float
    {
        $tssDeds = 0;
        foreach ($details as $d) {
            if (in_array($d['payroll_concept_id'] ?? null, $this->getTSSConceptIds())) {
                $tssDeds += $d['amount'];
            }
        }
        return max(0, $totalGross - $tssDeds);
    }

    /**
     * Estimación de la provisión mensual de cesantía.
     * Escala según Código de Trabajo RD (Ley 16-92):
     *  < 3 meses:   0
     *  3–6 meses:   6 días
     *  6–1 año:    13 días
     *  1–5 años:   21 días/año
     *  > 5 años:   23 días/año
     */
    public function calculateCesantiaProvision(Employee $employee, float $monthlySalary): float
    {
        $months = Carbon::parse($employee->hire_date)->diffInMonths(now());

        if ($months < 3) {
            return 0;
        }

        $dailySalary = $monthlySalary / 23.83; // días laborables promedio RD

        $anualDays = match (true) {
            $months < 6   => 6,
            $months < 12  => 13,
            $months < 60  => 21,
            default        => 23,
        };

        // Provisión mensual = días de cesantía anuales × salario diario / 12
        return round(($anualDays * $dailySalary) / 12, 2);
    }

    // ─────────────────────────────────────────────────
    //  UTILITARIOS PRIVADOS
    // ─────────────────────────────────────────────────

    private function getActiveEmployees(PayrollPeriod $period): Collection
    {
        return Employee::where('payroll_group_id', $period->payroll_group_id)
            ->whereIn('employment_status', ['activo', 'vacaciones'])
            ->whereNull('deleted_at')
            ->with(['payrollGroup', 'afp', 'ars'])
            ->get();
    }

    private function loadCache(Carbon $date): void
    {
        $codes = [
            'TSS_EMPLEADO_SFS', 'TSS_EMPLEADO_AFP',
            'TSS_PATRONAL_SFS', 'TSS_PATRONAL_AFP', 'TSS_PATRONAL_SRL',
            'INFOTEP',
            'ISR_EXENTO_ANUAL',
            'ISR_TRAMO_2_TASA', 'ISR_TRAMO_3_TASA', 'ISR_TRAMO_4_TASA',
        ];

        $capCodes = [
            'ISR_TRAMO_2_TASA' => 'ISR_TRAMO_2_CAP',
            'ISR_TRAMO_3_TASA' => 'ISR_TRAMO_3_CAP',
        ];

        foreach ($codes as $code) {
            $param = PayrollLegalParameter::getActive($code, $date);
            if ($param) {
                $this->paramsCache[$code] = $param->value_type === 'amount'
                    ? (float) $param->value
                    : (float) $param->value;

                // Si tiene tope asociado
                if (isset($capCodes[$code])) {
                    $this->paramsCache[$capCodes[$code]] = (float) $param->cap_amount;
                }
            }
        }

        // Cache de conceptos por code
        PayrollConcept::where('is_active', true)->get()->each(function ($concept) {
            $this->conceptsCache[$concept->code] = $concept;
        });
    }

    private function getConcept(string $code): ?PayrollConcept
    {
        return $this->conceptsCache[$code] ?? null;
    }

    private function getTSSConceptIds(): array
    {
        return array_filter([
            $this->conceptsCache['DED_TSS_SFS']->id ?? null,
            $this->conceptsCache['DED_AFP']->id      ?? null,
        ]);
    }

    private function makeDetail(
        Payroll $payroll,
        Employee $employee,
        string $conceptCode,
        string $type,
        float $amount,
        array $extra = []
    ): array {
        $concept = $this->getConcept($conceptCode);

        return array_merge([
            'payroll_id'         => $payroll->id,
            'employee_id'        => $employee->id,
            'payroll_concept_id' => $concept?->id,
            'type'               => $type,
            'amount'             => round($amount, 2),
            'quantity'           => 1,
            'rate'               => null,
            'notes'              => null,
            'is_manual_override' => false,
        ], $extra);
    }
}
