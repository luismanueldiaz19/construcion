<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Detalle de nómina por empleado y concepto.
 * NUNCA guardar solo totales — siempre desglosado para trazabilidad y auditoría.
 */
class PayrollDetail extends Model
{
    protected $fillable = [
        'payroll_id',
        'employee_id',
        'payroll_concept_id',
        'type',
        'amount',
        'quantity',
        'rate',
        'notes',
        'is_manual_override',
    ];

    protected $casts = [
        'amount'             => 'decimal:2',
        'quantity'           => 'decimal:4',
        'rate'               => 'decimal:4',
        'is_manual_override' => 'boolean',
    ];

    public function payroll(): BelongsTo
    {
        return $this->belongsTo(Payroll::class);
    }

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class);
    }

    public function concept(): BelongsTo
    {
        return $this->belongsTo(PayrollConcept::class, 'payroll_concept_id');
    }
}
