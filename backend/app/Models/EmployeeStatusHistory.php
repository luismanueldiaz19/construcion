<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class EmployeeStatusHistory extends Model
{
    protected $table = 'employee_status_history';

    protected $fillable = [
        'employee_id',
        'previous_status',
        'new_status',
        'previous_department',
        'new_department',
        'previous_position',
        'new_position',
        'effective_date',
        'reason',
        'registered_by',
    ];

    protected $casts = [
        'effective_date' => 'date',
    ];

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class);
    }

    public function registeredBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'registered_by');
    }
}
