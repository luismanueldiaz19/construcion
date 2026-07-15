<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Ars extends Model
{
    protected $table = 'arss';

    protected $fillable = ['name', 'code', 'phone', 'website', 'is_active'];

    protected $casts = ['is_active' => 'boolean'];

    public function employees(): HasMany
    {
        return $this->hasMany(Employee::class, 'ars_id');
    }
}
