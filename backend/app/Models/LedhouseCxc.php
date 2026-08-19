<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LedhouseCxc extends Model
{
    protected $fillable = [
        'documento',
        'cliente',
        'monto_factura',
        'monto_pagado',
        'monto_pendiente',
        'fecha_vencimiento',
        'estado',
    ];

    public function soportes()
    {
        return $this->hasMany(LedhouseCxcSoporte::class, 'ledhouse_cxc_id');
    }
}
