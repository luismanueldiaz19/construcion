<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class InventarioLocal extends Model
{
    protected $table = 'inventarios_locales';

    protected $fillable = ['name_inventario', 'location'];

    public function stocks()
    {
        return $this->hasMany(InventarioLocalStock::class, 'inventario_local_id');
    }
}
