<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Employee;
use App\Models\EmployeeSalaryHistory;
use App\Models\EmployeeStatusHistory;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * TAREA 07 — EmployeeController
 *
 * Maneja el CRUD completo de empleados y las acciones especiales:
 *   - change-salary  → solo vía este endpoint (crea histórico inmutable)
 *   - change-status  → activo/suspendido/vacaciones/licencia
 *   - terminate      → desvinculación con cálculo de prestaciones
 *   - restore        → recuperar soft-deleted
 */
class EmployeeController extends Controller
{
    // ── LIST ──
    public function index(Request $request): JsonResponse
    {
        $query = Employee::with([
            'department',
            'position',
            'payrollGroup',
            'afp',
            'ars',
            'bank',
        ])->withTrashed($request->boolean('with_trashed'));

        if ($request->filled('status')) {
            $query->where('employment_status', $request->status);
        }
        if ($request->filled('department_id')) {
            $query->where('department_id', $request->department_id);
        }
        if ($request->filled('payroll_group_id')) {
            $query->where('payroll_group_id', $request->payroll_group_id);
        }
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('first_name', 'like', "%$search%")
                  ->orWhere('last_name', 'like', "%$search%")
                  ->orWhere('employee_code', 'like', "%$search%")
                  ->orWhere('identification_number', 'like', "%$search%");
            });
        }

        $employees = $query->orderBy('first_name')->paginate($request->get('per_page', 20));

        return response()->json($employees);
    }

    // ── SHOW ──
    public function show(int $id): JsonResponse
    {
        $employee = Employee::with([
            'department',
            'position',
            'workSchedule',
            'payrollGroup',
            'bank',
            'afp',
            'ars',
            'supervisor',
            'dependents',
            'documents',
            'bankAccounts.bank',
            'salaryHistory',
            'statusHistory',
            'loans',
        ])->findOrFail($id);

        // Make sensitive fields visible for editing in the frontend
        $employee->makeVisible(['bank_account_number', 'identification_number']);

        return response()->json($employee);
    }

    // ── CREATE ──
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'first_name'             => 'required|string|max:100',
            'last_name'              => 'required|string|max:100',
            'identification_type'    => 'required|in:cedula,pasaporte,rnc',
            'identification_number'  => 'required|string|unique:employees,identification_number',
            'birth_date'             => 'nullable|date',
            'gender'                 => 'nullable|in:M,F,otro',
            'marital_status'         => 'nullable|in:soltero,casado,divorciado,viudo,union_libre',
            'nationality'            => 'nullable|string',
            'email'                  => 'nullable|email|unique:employees,email',
            'phone'                  => 'nullable|string|max:20',
            'address'                => 'nullable|string',
            'city'                   => 'nullable|string|max:100',
            'province'               => 'nullable|string|max:100',
            'hire_date'              => 'required|date',
            'employment_status'      => 'nullable|in:activo,inactivo,suspendido,vacaciones,licencia,desvinculado',
            'contract_type'          => 'required|in:indefinido,definido,por_obra,aprendizaje',
            'contract_end_date'      => 'required_if:contract_type,definido|nullable|date|after:hire_date',
            'position_id'            => 'nullable|exists:positions,id',
            'department_id'          => 'nullable|exists:departments,id',
            'work_schedule_id'       => 'nullable|exists:work_schedules,id',
            'payroll_group_id'       => 'nullable|exists:payroll_groups,id',
            'base_salary'            => 'required|numeric|min:0',
            'salary_type'            => 'required|in:fijo,por_hora,comision,mixto',
            'payment_method'         => 'required|in:transferencia,cheque,efectivo',
            'bank_id'                => 'nullable|exists:banks,id',
            'bank_account_number'    => 'nullable|string|max:30',
            'bank_account_type'      => 'nullable|in:ahorro,corriente',
            'tss_number'             => 'nullable|string|max:30',
            'afp_id'                 => 'nullable|exists:afps,id',
            'ars_id'                 => 'nullable|exists:arss,id',
            'is_tss_exempt'          => 'boolean',
            'is_isr_exempt'          => 'boolean',
            'supervisor_id'          => 'nullable|exists:employees,id',
        ]);

        // Validar que el payroll_group esté activo
        if (!empty($data['payroll_group_id'])) {
            $group = \App\Models\PayrollGroup::find($data['payroll_group_id']);
            if (!$group || !$group->is_active) {
                return response()->json(['message' => 'El grupo de nómina seleccionado no está activo.'], 422);
            }
        }

        $data['employee_code']     = $this->generateEmployeeCode();
        $data['employment_status'] = $data['employment_status'] ?? 'activo';
        $data['created_by']        = auth()->id();

        $employee = DB::transaction(function () use ($data) {
            $employee = Employee::create($data);

            // Registrar salario inicial en el histórico
            EmployeeSalaryHistory::create([
                'employee_id'     => $employee->id,
                'previous_salary' => 0,
                'new_salary'      => $employee->base_salary,
                'effective_date'  => $employee->hire_date,
                'reason'          => 'Salario de ingreso',
                'approved_by'     => auth()->id(),
            ]);

            return $employee;
        });

        $employee->makeVisible(['bank_account_number', 'identification_number']);

        return response()->json($employee->load(['department', 'position', 'payrollGroup']), 201);
    }

    // ── UPDATE ──
    public function update(Request $request, int $id): JsonResponse
    {
        $employee = Employee::findOrFail($id);

        $data = $request->validate([
            'first_name'          => 'sometimes|string|max:100',
            'last_name'           => 'sometimes|string|max:100',
            'identification_type' => 'sometimes|in:cedula,pasaporte,rnc',
            'identification_number' => "sometimes|string|unique:employees,identification_number,{$id}",
            'birth_date'          => 'nullable|date',
            'gender'              => 'nullable|in:M,F,otro',
            'marital_status'      => 'nullable|in:soltero,casado,divorciado,viudo,union_libre',
            'nationality'         => 'nullable|string',
            'email'               => "nullable|email|unique:employees,email,{$id}",
            'phone'               => 'nullable|string|max:20',
            'address'             => 'nullable|string',
            'city'                => 'nullable|string|max:100',
            'province'            => 'nullable|string|max:100',
            'contract_type'       => 'sometimes|in:indefinido,definido,por_obra,aprendizaje',
            'contract_end_date'   => 'required_if:contract_type,definido|nullable|date',
            'position_id'         => 'nullable|exists:positions,id',
            'department_id'       => 'nullable|exists:departments,id',
            'work_schedule_id'    => 'nullable|exists:work_schedules,id',
            'payroll_group_id'    => 'nullable|exists:payroll_groups,id',
            'salary_type'         => 'sometimes|in:fijo,por_hora,comision,mixto',
            'payment_method'      => 'sometimes|in:transferencia,cheque,efectivo',
            'bank_id'             => 'nullable|exists:banks,id',
            'bank_account_number' => 'nullable|string|max:30',
            'bank_account_type'   => 'nullable|in:ahorro,corriente',
            'tss_number'          => 'nullable|string|max:30',
            'afp_id'              => 'nullable|exists:afps,id',
            'ars_id'              => 'nullable|exists:arss,id',
            'is_tss_exempt'       => 'boolean',
            'is_isr_exempt'       => 'boolean',
            'supervisor_id'       => 'nullable|exists:employees,id',
        ]);

        // No permitir cambio de salario vía update genérico
        unset($data['base_salary']);
        $data['updated_by'] = auth()->id();

        $employee->update($data);

        $employee->makeVisible(['bank_account_number', 'identification_number']);

        return response()->json($employee->load(['department', 'position', 'payrollGroup']));
    }

    // ── SOFT DELETE ──
    public function destroy(int $id): JsonResponse
    {
        $employee = Employee::findOrFail($id);

        // Verificar que no tenga nóminas procesadas activas
        if ($employee->payrollDetails()->exists()) {
            return response()->json([
                'message' => 'No se puede eliminar un empleado con nómina procesada. Use la desvinculación.',
            ], 422);
        }

        $employee->delete();
        return response()->json(['message' => 'Empleado archivado correctamente.']);
    }

    // ── RESTORE ──
    public function restore(int $id): JsonResponse
    {
        $employee = Employee::withTrashed()->findOrFail($id);
        $employee->restore();
        return response()->json(['message' => 'Empleado restaurado.', 'employee' => $employee]);
    }

    // ── CAMBIO DE SALARIO (AUDITABLE) ──
    public function changeSalary(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'new_salary'     => 'required|numeric|min:0',
            'effective_date' => 'required|date',
            'reason'         => 'required|string|min:5',
        ]);

        $employee = Employee::findOrFail($id);

        DB::transaction(function () use ($request, $employee) {
            EmployeeSalaryHistory::create([
                'employee_id'     => $employee->id,
                'previous_salary' => $employee->base_salary,
                'new_salary'      => $request->new_salary,
                'effective_date'  => $request->effective_date,
                'reason'          => $request->reason,
                'approved_by'     => auth()->id(),
            ]);

            $employee->update([
                'base_salary' => $request->new_salary,
                'updated_by'  => auth()->id(),
            ]);
        });

        return response()->json([
            'message'  => 'Salario actualizado correctamente.',
            'employee' => $employee->fresh(['salaryHistory']),
        ]);
    }

    // ── CAMBIO DE ESTATUS ──
    public function changeStatus(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'new_status' => 'required|in:activo,inactivo,suspendido,vacaciones,licencia',
            'reason'     => 'nullable|string',
        ]);

        $employee = Employee::findOrFail($id);

        DB::transaction(function () use ($request, $employee) {
            EmployeeStatusHistory::create([
                'employee_id'        => $employee->id,
                'previous_status'    => $employee->employment_status,
                'new_status'         => $request->new_status,
                'effective_date'     => now()->toDateString(),
                'reason'             => $request->reason,
                'registered_by'      => auth()->id(),
            ]);

            $employee->update([
                'employment_status' => $request->new_status,
                'updated_by'        => auth()->id(),
            ]);
        });

        return response()->json(['message' => 'Estatus actualizado.', 'employee' => $employee->fresh()]);
    }

    // ── DESVINCULACIÓN / TERMINATE ──
    public function terminate(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'termination_date' => 'required|date',
            'termination_type' => 'required|in:despido_injustificado,renuncia,desahucio,mutuo_acuerdo',
            'reason'           => 'required|string|min:5',
        ]);

        $employee = Employee::findOrFail($id);

        if ($employee->employment_status === 'desvinculado') {
            return response()->json(['message' => 'El empleado ya está desvinculado.'], 422);
        }

        $prestaciones = $this->calculatePrestaciones($employee, $request->termination_date, $request->termination_type);

        DB::transaction(function () use ($request, $employee, $prestaciones) {
            EmployeeStatusHistory::create([
                'employee_id'     => $employee->id,
                'previous_status' => $employee->employment_status,
                'new_status'      => 'desvinculado',
                'effective_date'  => $request->termination_date,
                'reason'          => "Desvinculación ({$request->termination_type}): {$request->reason}",
                'registered_by'   => auth()->id(),
            ]);

            $employee->update([
                'employment_status'  => 'desvinculado',
                'termination_date'   => $request->termination_date,
                'updated_by'         => auth()->id(),
            ]);
        });

        return response()->json([
            'message'      => 'Empleado desvinculado. Se calcularon las prestaciones laborales.',
            'prestaciones' => $prestaciones,
        ]);
    }

    // ── HISTORIAL DE NÓMINA ──
    public function payrollHistory(int $id): JsonResponse
    {
        $employee = Employee::findOrFail($id);
        $history  = PayrollDetail::where('employee_id', $id)
            ->with(['payroll.period', 'concept'])
            ->orderByDesc('created_at')
            ->paginate(20);

        return response()->json($history);
    }

    // ─── HELPERS PRIVADOS ───────────────────────────

    private function generateEmployeeCode(): string
    {
        $last = Employee::withTrashed()->orderByDesc('id')->first();
        $next = $last ? ($last->id + 1) : 1;
        return 'EMP-' . str_pad($next, 4, '0', STR_PAD_LEFT);
    }

    /**
     * Calcula prestaciones laborales según Código de Trabajo RD (Ley 16-92).
     * Distingue: despido injustificado (preaviso + cesantía) vs renuncia (sin cesantía).
     */
    private function calculatePrestaciones(Employee $employee, string $terminationDate, string $type): array
    {
        $hireDate  = \Carbon\Carbon::parse($employee->hire_date);
        $termDate  = \Carbon\Carbon::parse($terminationDate);
        $months    = $hireDate->diffInMonths($termDate);
        $years     = $hireDate->diffInYears($termDate);
        $dailySalary = (float) $employee->base_salary / 23.83;

        // Preaviso (Código Trabajo Art. 76)
        $preaviso = 0;
        if ($type !== 'renuncia') {
            $preaviso = match (true) {
                $months < 3  => 0,
                $months < 6  => 7  * $dailySalary,
                $months < 12 => 14 * $dailySalary,
                default      => 28 * $dailySalary,
            };
        }

        // Auxilio de cesantía (Art. 80) — solo en despido injustificado y desahucio
        $cesantia = 0;
        if (in_array($type, ['despido_injustificado', 'desahucio'])) {
            $daysPerYear = match (true) {
                $months < 3  => 0,
                $months < 6  => 6,
                $months < 12 => 13,
                $years < 5   => 21,
                default      => 23,
            };
            $cesantia = $daysPerYear * $years * $dailySalary;
        }

        // Vacaciones no disfrutadas (proporcional al año en curso)
        $monthsThisYear    = $termDate->month + ($termDate->day / 30);
        $vacacionesDias    = ($monthsThisYear / 12) * 14; // 14 días estándar
        $vacacionesMonto   = round($vacacionesDias * $dailySalary, 2);

        // Regalía proporcional
        $regaliaProporcional = round(($monthsThisYear / 12) * (float) $employee->base_salary, 2);

        return [
            'preaviso'              => round($preaviso, 2),
            'cesantia'              => round($cesantia, 2),
            'vacaciones_proporcional' => $vacacionesMonto,
            'regalia_proporcional'  => $regaliaProporcional,
            'total'                 => round($preaviso + $cesantia + $vacacionesMonto + $regaliaProporcional, 2),
            'termination_type'      => $type,
            'months_worked'         => $months,
            'years_worked'          => $years,
        ];
    }
}
