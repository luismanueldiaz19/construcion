<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LedhouseCxp extends Model
{
    protected $fillable = [
        'documento',
        'proveedor',
        'monto_factura',
        'monto_pagado',
        'monto_pendiente',
        'fecha_vencimiento',
        'estado',
    ];
}
