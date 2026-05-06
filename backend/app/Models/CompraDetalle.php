<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CompraDetalle extends Model
{
    protected $fillable = [
        'compra_id', 
        'material_id', 
        'cantidad', 
        'cantidad_recibida',
        'precio_unitario', 
        'subtotal'
    ];

    public function material()
    {
        return $this->belongsTo(Material::class);
    }

    public function compra()
    {
        return $this->belongsTo(Compra::class);
    }
}
