<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Compra extends Model
{
    protected $fillable = [
        'proveedor_id', 
        'proyecto_id', 
        'fecha', 
        'tipo_compra', 
        'subtotal', 
        'itbis', 
        'total', 
        'fecha_vencimiento',
        'estado'
    ];

    public function detalles()
    {
        return $this->hasMany(CompraDetalle::class);
    }

    public function proveedor()
    {
        return $this->belongsTo(Proveedor::class);
    }

    public function proyecto()
    {
        return $this->belongsTo(Proyecto::class);
    }
}
