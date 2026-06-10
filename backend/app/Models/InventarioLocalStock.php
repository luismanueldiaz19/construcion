<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class InventarioLocalStock extends Model
{
    protected $table = 'inventarios_locales_stock';

    protected $fillable = ['inventario_local_id', 'material_id', 'stock'];

    public function material()
    {
        return $this->belongsTo(Material::class);
    }

    public function inventarioLocal()
    {
        return $this->belongsTo(InventarioLocal::class, 'inventario_local_id');
    }
}
