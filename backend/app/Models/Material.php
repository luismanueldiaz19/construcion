<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Material extends Model
{
    protected $table = 'materiales';
    protected $fillable = [
        'codigo',
        'nombre',
        'descripcion',
        'categoria_id',
        'unidad',
        'precio_costo',
        'stock_global',
        'estado'
    ];

    public function categoria()
    {
        return $this->belongsTo(Categoria::class);
    }
}
