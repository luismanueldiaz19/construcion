<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class EmployeeDependent extends Model
{
    protected $fillable = [
        'employee_id', 'name', 'relationship', 'birth_date', 'is_isr_dependent',
    ];

    protected $casts = [
        'birth_date'       => 'date',
        'is_isr_dependent' => 'boolean',
    ];

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class);
    }
}
