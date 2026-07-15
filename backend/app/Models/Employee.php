<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

/**
 * Modelo principal de Empleado.
 *
 * REGLAS CRÍTICAS:
 * - NUNCA eliminar físicamente un empleado con nómina procesada.
 * - Todo cambio salarial DEBE pasar por employee_salary_history, nunca UPDATE directo.
 * - Al marcar employment_status = 'desvinculado', el sistema dispara cálculo de prestaciones.
 */
class Employee extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'employee_code',
        'first_name',
        'last_name',
        'identification_type',
        'identification_number',
        'birth_date',
        'gender',
        'marital_status',
        'nationality',
        'email',
        'phone',
        'address',
        'city',
        'province',
        'photo_path',
        'hire_date',
        'termination_date',
        'employment_status',
        'contract_type',
        'contract_end_date',
        'position_id',
        'department_id',
        'work_schedule_id',
        'payroll_group_id',
        'base_salary',
        'salary_type',
        'payment_method',
        'bank_id',
        'bank_account_number',
        'bank_account_type',
        'tss_number',
        'afp_id',
        'ars_id',
        'is_tss_exempt',
        'is_isr_exempt',
        'supervisor_id',
        'created_by',
        'updated_by',
    ];

    protected $casts = [
        'birth_date'       => 'date',
        'hire_date'        => 'date',
        'termination_date' => 'date',
        'contract_end_date' => 'date',
        'base_salary'      => 'decimal:2',
        'is_tss_exempt'    => 'boolean',
        'is_isr_exempt'    => 'boolean',
    ];

    // Campos sensibles — no exponer en logs ni listados generales
    protected $hidden = [
        'bank_account_number',
        'identification_number',
    ];

    // ──────────────── RELACIONES ────────────────

    public function position(): BelongsTo
    {
        return $this->belongsTo(Position::class);
    }

    public function department(): BelongsTo
    {
        return $this->belongsTo(Department::class);
    }

    public function workSchedule(): BelongsTo
    {
        return $this->belongsTo(WorkSchedule::class);
    }

    public function payrollGroup(): BelongsTo
    {
        return $this->belongsTo(PayrollGroup::class);
    }

    public function bank(): BelongsTo
    {
        return $this->belongsTo(Bank::class);
    }

    public function afp(): BelongsTo
    {
        return $this->belongsTo(Afp::class);
    }

    public function ars(): BelongsTo
    {
        return $this->belongsTo(Ars::class);
    }

    /** FK autoreferencial para organigrama */
    public function supervisor(): BelongsTo
    {
        return $this->belongsTo(Employee::class, 'supervisor_id');
    }

    public function subordinates(): HasMany
    {
        return $this->hasMany(Employee::class, 'supervisor_id');
    }

    public function dependents(): HasMany
    {
        return $this->hasMany(EmployeeDependent::class);
    }

    public function documents(): HasMany
    {
        return $this->hasMany(EmployeeDocument::class);
    }

    /** AUDITORÍA: solo INSERT, nunca UPDATE/DELETE */
    public function salaryHistory(): HasMany
    {
        return $this->hasMany(EmployeeSalaryHistory::class)->orderByDesc('effective_date');
    }

    public function statusHistory(): HasMany
    {
        return $this->hasMany(EmployeeStatusHistory::class)->orderByDesc('effective_date');
    }

    public function bankAccounts(): HasMany
    {
        return $this->hasMany(EmployeeBankAccount::class);
    }

    public function payrollDetails(): HasMany
    {
        return $this->hasMany(PayrollDetail::class);
    }

    public function loans(): HasMany
    {
        return $this->hasMany(PayrollLoan::class)->where('status', 'activo');
    }

    public function payslips(): HasMany
    {
        return $this->hasMany(Payslip::class);
    }

    // ──────────────── ACCESSORS / HELPERS ────────────────

    public function getFullNameAttribute(): string
    {
        return "{$this->first_name} {$this->last_name}";
    }

    public function isActive(): bool
    {
        return $this->employment_status === 'activo';
    }
}
