<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PagoCliente extends Model
{
    protected $table = 'pagos_clientes';
    protected $fillable = ['proyecto_id', 'fecha', 'monto', 'metodo_pago', 'cuenta_contable_id'];
}
