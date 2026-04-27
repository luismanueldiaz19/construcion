<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Consumo extends Model
{
    protected $fillable = [
        'proyecto_id', 
        'material_id', 
        'subpartida_id', 
        'cantidad', 
        'costo_unitario', 
        'total', 
        'fecha'
    ];

    public function proyecto()
    {
        return $this->belongsTo(Proyecto::class);
    }

    public function material()
    {
        return $this->belongsTo(Material::class);
    }

    public function subpartida()
    {
        return $this->belongsTo(Subpartida::class, 'subpartida_id');
    }
}
