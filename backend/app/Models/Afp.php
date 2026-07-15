<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Afp extends Model
{
    protected $table = 'afps';

    protected $fillable = ['name', 'code', 'phone', 'website', 'is_active'];

    protected $casts = ['is_active' => 'boolean'];

    public function employees(): HasMany
    {
        return $this->hasMany(Employee::class, 'afp_id');
    }
}
