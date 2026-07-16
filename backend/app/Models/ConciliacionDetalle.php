<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ConciliacionDetalle extends Model
{
    use HasFactory;

    protected $table = 'conciliacion_detalles';

    protected $fillable = [
        'conciliacion_id',
        'asiento_detalle_id',
        'estado'
    ];

    public function conciliacion()
    {
        return $this->belongsTo(ConciliacionBancaria::class, 'conciliacion_id');
    }

    public function asientoDetalle()
    {
        return $this->belongsTo(AsientoDetalle::class, 'asiento_detalle_id');
    }
}
