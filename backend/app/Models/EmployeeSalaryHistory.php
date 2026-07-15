<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Histórico INMUTABLE de cambios salariales.
 * Solo INSERT permitido — nunca UPDATE ni DELETE.
 * Requerido por auditoría contable y legal.
 */
class EmployeeSalaryHistory extends Model
{
    protected $table = 'employee_salary_history';

    protected $fillable = [
        'employee_id',
        'previous_salary',
        'new_salary',
        'effective_date',
        'reason',
        'approved_by',
    ];

    protected $casts = [
        'previous_salary' => 'decimal:2',
        'new_salary'      => 'decimal:2',
        'effective_date'  => 'date',
    ];

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class);
    }

    public function approvedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'approved_by');
    }
}
