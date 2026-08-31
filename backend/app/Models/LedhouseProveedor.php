<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class LedhouseProveedor extends Model
{
    use HasFactory;

    protected $table = 'ledhouse_proveedores';

    protected $fillable = [
        'nombre',
        'empresa',
        'rnc_cedula',
        'whatsapp',
        'correo',
        'direccion'
    ];
}
