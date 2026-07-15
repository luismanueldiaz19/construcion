<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Position extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'title',
        'department_id',
        'salary_min',
        'salary_max',
        'job_description',
        'is_active',
    ];

    protected $casts = [
        'salary_min' => 'decimal:2',
        'salary_max' => 'decimal:2',
        'is_active'  => 'boolean',
    ];

    public function department(): BelongsTo
    {
        return $this->belongsTo(Department::class);
    }

    public function employees(): HasMany
    {
        return $this->hasMany(Employee::class);
    }
}
