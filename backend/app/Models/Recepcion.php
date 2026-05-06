<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Recepcion extends Model
{
    // Forzamos el nombre de la tabla en español
    protected $table = 'recepciones';
    
    protected $fillable = ['compra_id', 'fecha', 'recibido_por', 'observaciones'];

    public function detalles()
    {
        return $this->hasMany(RecepcionDetalle::class);
    }

    public function compra()
    {
        return $this->belongsTo(Compra::class);
    }
}
