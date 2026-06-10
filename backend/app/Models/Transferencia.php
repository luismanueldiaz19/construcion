<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Transferencia extends Model
{
    protected $fillable = [
        'material_id',
        'proyecto_origen_id',
        'proyecto_destino_id',
        'inventario_local_origen_id',
        'inventario_local_destino_id',
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

    public function inventarioLocalOrigen()
    {
        return $this->belongsTo(InventarioLocal::class, 'inventario_local_origen_id');
    }

    public function inventarioLocalDestino()
    {
        return $this->belongsTo(InventarioLocal::class, 'inventario_local_destino_id');
    }
}
