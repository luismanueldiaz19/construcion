<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AsientoDetalle extends Model
{
    protected $fillable = ['asiento_id', 'cuenta_id', 'debe', 'haber', 'centro_costo_id'];

    public function cuenta()
    {
        return $this->belongsTo(CatalogoCuenta::class, 'cuenta_id');
    }

    public function centro_costo()
    {
        return $this->belongsTo(Proyecto::class, 'centro_costo_id');
    }
}
