<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Department;
use App\Models\Position;
use App\Models\WorkSchedule;
use App\Models\PayrollGroup;
use App\Models\Afp;
use App\Models\Ars;
use App\Models\Bank;
use App\Models\PayrollConcept;
use App\Models\PayrollLegalParameter;
use App\Models\PayrollPeriod;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

/**
 * NominaCatalogController — Catálogos del módulo de nómina.
 * Endpoints de solo lectura y gestión de catálogos de referencia.
 */
class NominaCatalogController extends Controller
{
    // ── DEPARTAMENTOS ──
    public function departments(Request $request): JsonResponse
    {
        $depts = Department::with('manager')
            ->when(!$request->boolean('include_inactive'), fn($q) => $q->where('is_active', true))
            ->orderBy('name')->get();
        return response()->json($depts);
    }

    public function storeDepartment(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name'              => 'required|string|max:150|unique:departments,name',
            'cost_center_code'  => 'nullable|string|max:50',
            'manager_id'        => 'nullable|exists:employees,id',
        ]);
        return response()->json(Department::create($data), 201);
    }

    public function updateDepartment(Request $request, int $id): JsonResponse
    {
        $dept = Department::findOrFail($id);
        $data = $request->validate([
            'name'             => "sometimes|string|max:150|unique:departments,name,{$id}",
            'cost_center_code' => 'nullable|string|max:50',
            'manager_id'       => 'nullable|exists:employees,id',
            'is_active'        => 'boolean',
        ]);
        $dept->update($data);
        return response()->json($dept);
    }

    // ── CARGOS ──
    public function positions(Request $request): JsonResponse
    {
        $positions = Position::with('department')
            ->when($request->department_id, fn($q, $id) => $q->where('department_id', $id))
            ->when(!$request->boolean('include_inactive'), fn($q) => $q->where('is_active', true))
            ->orderBy('title')->get();
        return response()->json($positions);
    }

    public function storePosition(Request $request): JsonResponse
    {
        $data = $request->validate([
            'title'           => 'required|string|max:150',
            'department_id'   => 'nullable|exists:departments,id',
            'salary_min'      => 'nullable|numeric|min:0',
            'salary_max'      => 'nullable|numeric|min:0|gte:salary_min',
            'job_description' => 'nullable|string',
        ]);
        return response()->json(Position::create($data), 201);
    }

    public function updatePosition(Request $request, int $id): JsonResponse
    {
        $position = Position::findOrFail($id);
        $data = $request->validate([
            'title'           => 'sometimes|string|max:150',
            'department_id'   => 'nullable|exists:departments,id',
            'salary_min'      => 'nullable|numeric|min:0',
            'salary_max'      => 'nullable|numeric|min:0',
            'job_description' => 'nullable|string',
            'is_active'       => 'boolean',
        ]);
        $position->update($data);
        return response()->json($position);
    }

    // ── HORARIOS ──
    public function workSchedules(): JsonResponse
    {
        return response()->json(WorkSchedule::where('is_active', true)->orderBy('name')->get());
    }

    // ── GRUPOS DE NÓMINA ──
    public function payrollGroups(): JsonResponse
    {
        return response()->json(PayrollGroup::where('is_active', true)->orderBy('name')->get());
    }

    // ── AFPs / ARSs / BANCOS ──
    public function afps(): JsonResponse
    {
        return response()->json(Afp::where('is_active', true)->orderBy('name')->get());
    }

    public function arss(): JsonResponse
    {
        return response()->json(Ars::where('is_active', true)->orderBy('name')->get());
    }

    public function banks(): JsonResponse
    {
        return response()->json(Bank::where('is_active', true)->orderBy('name')->get());
    }

    // ── CONCEPTOS DE NÓMINA ──
    public function payrollConcepts(Request $request): JsonResponse
    {
        $concepts = PayrollConcept::when($request->type, fn($q, $t) => $q->where('type', $t))
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->get();
        return response()->json($concepts);
    }

    public function storePayrollConcept(Request $request): JsonResponse
    {
        $data = $request->validate([
            'code'                   => 'required|string|unique:payroll_concepts,code',
            'name'                   => 'required|string|max:150',
            'type'                   => 'required|in:ingreso,deduccion,aporte_patronal',
            'calculation_method'     => 'required|in:fijo,porcentaje,formula,manual',
            'default_value'          => 'nullable|numeric',
            'is_taxable_isr'         => 'boolean',
            'is_tss_applicable'      => 'boolean',
            'accounting_account_id'  => 'nullable|exists:catalogo_cuentas,id',
            'sort_order'             => 'nullable|integer',
        ]);
        return response()->json(PayrollConcept::create($data), 201);
    }

    // ── PARÁMETROS LEGALES ──
    public function legalParameters(Request $request): JsonResponse
    {
        $params = PayrollLegalParameter::where('is_active', true)
            ->when($request->category, fn($q, $c) => $q->where('category', $c))
            ->when($request->fiscal_year, fn($q, $y) => $q->where('fiscal_year', $y))
            ->orderBy('category')
            ->orderBy('code')
            ->get();
        return response()->json($params);
    }

    // ── PERIODOS DE NÓMINA ──
    public function payrollPeriods(Request $request): JsonResponse
    {
        $periods = PayrollPeriod::with('payrollGroup')
            ->when($request->payroll_group_id, fn($q, $id) => $q->where('payroll_group_id', $id))
            ->when($request->status, fn($q, $s) => $q->where('status', $s))
            ->when($request->fiscal_year, fn($q, $y) => $q->where('fiscal_year', $y))
            ->orderByDesc('start_date')
            ->paginate(20);
        return response()->json($periods);
    }

    public function storePayrollPeriod(Request $request): JsonResponse
    {
        $data = $request->validate([
            'payroll_group_id' => [
                'required', 
                'exists:payroll_groups,id',
                \Illuminate\Validation\Rule::unique('payroll_periods')->where(function ($query) use ($request) {
                    return $query->where('start_date', $request->start_date)
                                 ->where('end_date', $request->end_date);
                })
            ],
            'start_date'       => 'required|date',
            'end_date'         => 'required|date|after:start_date',
            'payment_date'     => 'required|date',
            'fiscal_year'      => 'required|integer|min:2020|max:2099',
            'period_number'    => 'required|integer|min:1|max:53',
        ], [
            'payroll_group_id.unique' => 'Ya existe un periodo registrado para este grupo con exactamente las mismas fechas.'
        ]);

        $period = PayrollPeriod::create(array_merge($data, ['status' => 'abierto']));
        return response()->json($period->load('payrollGroup'), 201);
    }

    public function destroyPayrollPeriod(int $id): JsonResponse
    {
        $period = PayrollPeriod::findOrFail($id);
        
        // Block if it has an associated payroll
        $hasPayroll = \App\Models\Payroll::where('payroll_period_id', $id)->exists();
        if ($hasPayroll) {
             return response()->json(['message' => 'No se puede eliminar el periodo porque ya tiene una nómina en proceso asociada. Primero elimine la nómina.'], 403);
        }

        $period->delete();
        return response()->json(['message' => 'Periodo eliminado exitosamente.']);
    }
}
