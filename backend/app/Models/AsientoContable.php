<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AsientoContable extends Model
{
    protected $table = 'asientos_contables';
    protected $fillable = ['fecha', 'glosa', 'referencia_tipo', 'referencia_id'];

    public function detalles()
    {
        return $this->hasMany(AsientoDetalle::class, 'asiento_id');
    }
}
