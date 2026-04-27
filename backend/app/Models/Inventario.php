<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Inventario extends Model
{
    protected $fillable = ['proyecto_id', 'material_id', 'stock'];

    public function material()
    {
        return $this->belongsTo(Material::class);
    }
}
