<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Asset extends Model
{
    use HasFactory;

    protected $fillable = [
        'category_id',
        'name',
        'brand',
        'model',
        'serial_number',
        'purchase_date',
        'initial_cost',
        'status',
        'notes',
    ];

    protected $appends = ['tco'];

    public function getTcoAttribute()
    {
        return $this->initial_cost + $this->expenses()->sum('amount');
    }

    public function category()
    {
        return $this->belongsTo(AssetCategory::class, 'category_id');
    }

    public function assignments()
    {
        return $this->hasMany(AssetAssignment::class, 'asset_id');
    }

    public function expenses()
    {
        return $this->hasMany(AssetExpense::class, 'asset_id');
    }
}
