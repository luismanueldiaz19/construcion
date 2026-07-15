<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class WorkSchedule extends Model
{
    protected $fillable = [
        'name',
        'days_per_week',
        'hours_per_day',
        'entry_time',
        'exit_time',
        'is_night_shift',
        'is_active',
    ];

    protected $casts = [
        'hours_per_day'  => 'decimal:2',
        'is_night_shift' => 'boolean',
        'is_active'      => 'boolean',
    ];

    public function employees(): HasMany
    {
        return $this->hasMany(Employee::class);
    }
}
