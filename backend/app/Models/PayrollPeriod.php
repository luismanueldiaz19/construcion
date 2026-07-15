<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class PayrollPeriod extends Model
{
    protected $fillable = [
        'payroll_group_id',
        'start_date',
        'end_date',
        'payment_date',
        'fiscal_year',
        'period_number',
        'status',
    ];

    protected $casts = [
        'start_date'   => 'date',
        'end_date'     => 'date',
        'payment_date' => 'date',
        'fiscal_year'  => 'integer',
    ];

    public function payrollGroup(): BelongsTo
    {
        return $this->belongsTo(PayrollGroup::class);
    }

    public function payrolls(): HasMany
    {
        return $this->hasMany(Payroll::class);
    }

    public function latestPayroll(): HasOne
    {
        return $this->hasOne(Payroll::class)->latestOfMany();
    }

    public function isClosed(): bool
    {
        return $this->status === 'cerrado';
    }
}
