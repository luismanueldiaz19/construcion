<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class GastoProyecto extends Model
{
    protected $table = 'gastos_proyecto';
    
    protected $fillable = [
        'proyecto_id',
        'subpartida_id',
        'proveedor_id',
        'cuenta_costo_id',
        'monto',
        'tipo_gasto',
        'descripcion',
        'fecha',
        'metodo_pago',
        'estado',
        'banco_id',
    ];

    public function proyecto()
    {
        return $this->belongsTo(Proyecto::class);
    }

    public function subpartida()
    {
        return $this->belongsTo(Subpartida::class);
    }

    public function proveedor()
    {
        return $this->belongsTo(Proveedor::class);
    }

    public function cuentaCosto()
    {
        return $this->belongsTo(CatalogoCuenta::class, 'cuenta_costo_id');
    }

    public function banco()
    {
        return $this->belongsTo(CatalogoCuenta::class, 'banco_id');
    }
}
