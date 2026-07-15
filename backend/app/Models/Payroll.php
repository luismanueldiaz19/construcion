<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * Cabecera del proceso de nómina.
 *
 * Flujo: borrador → calculado → revisado → aprobado → pagado → cerrado
 *
 * REGLA: Una vez en estado "cerrado" es INMUTABLE.
 *        Quien calcula ≠ quien aprueba (segregación de funciones).
 */
class Payroll extends Model
{
    protected $fillable = [
        'payroll_period_id',
        'status',
        'total_gross',
        'total_deductions',
        'total_net',
        'total_employer_cost',
        'total_isr',
        'total_tss_employee',
        'total_tss_employer',
        'processed_by',
        'reviewed_by',
        'approved_by',
        'paid_by',
        'processed_at',
        'reviewed_at',
        'approved_at',
        'paid_at',
        'closed_at',
        'notes',
    ];

    protected $casts = [
        'total_gross'         => 'decimal:2',
        'total_deductions'    => 'decimal:2',
        'total_net'           => 'decimal:2',
        'total_employer_cost' => 'decimal:2',
        'total_isr'           => 'decimal:2',
        'total_tss_employee'  => 'decimal:2',
        'total_tss_employer'  => 'decimal:2',
        'processed_at'        => 'datetime',
        'reviewed_at'         => 'datetime',
        'approved_at'         => 'datetime',
        'paid_at'             => 'datetime',
        'closed_at'           => 'datetime',
    ];

    public function period(): BelongsTo
    {
        return $this->belongsTo(PayrollPeriod::class, 'payroll_period_id');
    }

    public function details(): HasMany
    {
        return $this->hasMany(PayrollDetail::class);
    }

    public function payslips(): HasMany
    {
        return $this->hasMany(Payslip::class);
    }

    public function processedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'processed_by');
    }

    public function approvedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'approved_by');
    }

    public function isClosed(): bool
    {
        return $this->status === 'cerrado';
    }

    public function isEditable(): bool
    {
        return in_array($this->status, ['borrador', 'calculado']);
    }
}
