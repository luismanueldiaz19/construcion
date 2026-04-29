<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CuentaPorPagar extends Model
{
    protected $table = 'cuentas_por_pagar';
    
    protected $fillable = [
        'compra_id', 
        'proveedor_id', 
        'monto_total', 
        'monto_pagado', 
        'saldo', 
        'fecha_vencimiento',
        'estado'
    ];

    public function compra()
    {
        return $this->belongsTo(Compra::class);
    }

    public function proveedor()
    {
        return $this->belongsTo(Proveedor::class);
    }

    public function pagos()
    {
        return $this->hasMany(PagoCompra::class);
    }
}
