<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AssetCategory extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'description',
        'default_asset_account_id',
        'default_expense_account_id',
    ];

    public function assets()
    {
        return $this->hasMany(Asset::class, 'category_id');
    }

    public function defaultAssetAccount()
    {
        return $this->belongsTo(CatalogoCuenta::class, 'default_asset_account_id');
    }

    public function defaultExpenseAccount()
    {
        return $this->belongsTo(CatalogoCuenta::class, 'default_expense_account_id');
    }
}
