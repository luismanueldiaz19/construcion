<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PagoCompra extends Model
{
    protected $table = 'pagos_compras';

    protected $fillable = [
        'cuenta_por_pagar_id', 
        'fecha', 
        'monto', 
        'metodo_pago', 
        'referencia', 
        'notas'
    ];

    public function cuentaPorPagar()
    {
        return $this->belongsTo(CuentaPorPagar::class);
    }
}
