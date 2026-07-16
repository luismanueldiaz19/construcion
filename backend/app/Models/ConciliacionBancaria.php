<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ConciliacionBancaria extends Model
{
    use HasFactory;

    protected $table = 'conciliaciones_bancarias';

    protected $fillable = [
        'banco_id',
        'anio',
        'mes',
        'saldo_banco',
        'saldo_sistema',
        'diferencia',
        'estado',
        'conciliado_por'
    ];

    public function banco()
    {
        return $this->belongsTo(CatalogoCuenta::class, 'banco_id');
    }

    public function usuario()
    {
        return $this->belongsTo(User::class, 'conciliado_por');
    }

    public function detalles()
    {
        return $this->hasMany(ConciliacionDetalle::class, 'conciliacion_id');
    }
}
