<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Préstamos y adelantos de nómina con amortización automática.
 * La cuota se descuenta en cada proceso de nómina mientras status = 'activo'.
 */
class PayrollLoan extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'employee_id',
        'reference_code',
        'loan_type',
        'original_amount',
        'outstanding_balance',
        'monthly_installment',
        'total_installments',
        'remaining_installments',
        'start_date',
        'expected_end_date',
        'status',
        'description',
        'approved_by',
        'approved_at',
    ];

    protected $casts = [
        'original_amount'       => 'decimal:2',
        'outstanding_balance'   => 'decimal:2',
        'monthly_installment'   => 'decimal:2',
        'start_date'            => 'date',
        'expected_end_date'     => 'date',
        'approved_at'           => 'datetime',
    ];

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class);
    }

    public function approvedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'approved_by');
    }

    public function isActive(): bool
    {
        return $this->status === 'activo' && $this->outstanding_balance > 0;
    }
}
