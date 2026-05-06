<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RecepcionDetalle extends Model
{
    protected $table = 'recepcion_detalles';
    
    protected $fillable = [
        'recepcion_id',
        'compra_detalle_id',
        'cantidad_entregada'
    ];

    public function recepcion()
    {
        return $this->belongsTo(Recepcion::class);
    }

    public function compraDetalle()
    {
        return $this->belongsTo(CompraDetalle::class);
    }
}
