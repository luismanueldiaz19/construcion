<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Transferencia extends Model
{
    protected $fillable = [
        'material_id',
        'proyecto_origen_id',
        'proyecto_destino_id',
        'cantidad',
        'fecha',
        'observaciones'
    ];

    public function material()
    {
        return $this->belongsTo(Material::class);
    }

    public function proyectoOrigen()
    {
        return $this->belongsTo(Proyecto::class, 'proyecto_origen_id');
    }

    public function proyectoDestino()
    {
        return $this->belongsTo(Proyecto::class, 'proyecto_destino_id');
    }
}
