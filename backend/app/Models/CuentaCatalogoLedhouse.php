<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CuentaCatalogoLedhouse extends Model
{
    protected $table = 'cuenta_catalogo_ledhouse';
    protected $fillable = ['codigo', 'descripcion', 'origen'];
}
