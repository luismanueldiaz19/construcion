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
        'estado',
        'orden',
        'codigo',
        'comprobante',
        'nota'
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

    public function documentos()
    {
        return $this->hasMany(CompraDocumento::class);
    }
}
