<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class EmployeeBankAccount extends Model
{
    protected $fillable = [
        'employee_id',
        'bank_id',
        'account_number',
        'account_type',
        'allocation_percentage',
        'is_primary',
        'is_active',
    ];

    protected $casts = [
        'allocation_percentage' => 'decimal:2',
        'is_primary'            => 'boolean',
        'is_active'             => 'boolean',
    ];

    protected $hidden = ['account_number'];

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class);
    }

    public function bank(): BelongsTo
    {
        return $this->belongsTo(Bank::class);
    }
}
