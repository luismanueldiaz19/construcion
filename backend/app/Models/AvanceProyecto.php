<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AvanceProyecto extends Model
{
    protected $table = 'avances_proyecto';
    protected $fillable = ['subpartida_id', 'fecha', 'porcentaje', 'valor_ejecutado', 'evidencias_url'];
}
