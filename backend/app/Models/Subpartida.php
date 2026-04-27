<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Subpartida extends Model
{
    protected $fillable = [
        'partida_id', 'descripcion', 'unidad', 'cantidad', 'costo_unitario', 'total_presupuestado'
    ];

    public function setUnidadAttribute($value)
    {
        $this->attributes['unidad'] = strtoupper($value);
    }

    public function avances()
    {
        return $this->hasMany(AvanceProyecto::class, 'subpartida_id');
    }
}
