<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LedhouseEstadoResultado extends Model
{
    protected $table = 'ledhouse_estado_resultado';

    protected $fillable = [
        'codigo_cuenta',
        'monto',
        'fecha',
        'registed_by',
    ];

    public function catalogo()
    {
        return $this->belongsTo(CuentaCatalogoLedhouse::class, 'codigo_cuenta', 'codigo');
    }
}
