<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class PayrollGroup extends Model
{
    protected $fillable = [
        'name',
        'frequency',
        'cutoff_day',
        'payment_day',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function employees(): HasMany
    {
        return $this->hasMany(Employee::class);
    }

    public function payrollPeriods(): HasMany
    {
        return $this->hasMany(PayrollPeriod::class);
    }

    /**
     * Retorna la cantidad de periodos por año según la frecuencia.
     */
    public function getPeriodsPerYearAttribute(): int
    {
        return match ($this->frequency) {
            'weekly'   => 52,
            'biweekly' => 24,
            'monthly'  => 12,
            default    => 12,
        };
    }
}
