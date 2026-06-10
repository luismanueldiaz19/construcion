<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AssetExpense extends Model
{
    use HasFactory;

    protected $fillable = [
        'asset_id',
        'proyecto_id',
        'expense_type',
        'amount',
        'date',
        'description',
        'mileage',
        'gallons',
        'proveedor_id',
        'payment_method',
        'banco_id',
        'asiento_contable_id',
    ];

    public function asset()
    {
        return $this->belongsTo(Asset::class, 'asset_id');
    }

    public function proyecto()
    {
        return $this->belongsTo(Proyecto::class, 'proyecto_id');
    }

    public function proveedor()
    {
        return $this->belongsTo(Proveedor::class, 'proveedor_id');
    }

    public function banco()
    {
        return $this->belongsTo(CatalogoCuenta::class, 'banco_id');
    }

    public function asientoContable()
    {
        return $this->belongsTo(AsientoContable::class, 'asiento_contable_id');
    }
}
