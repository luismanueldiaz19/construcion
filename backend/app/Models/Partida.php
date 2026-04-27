<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Partida extends Model
{
    protected $fillable = ['proyecto_id', 'codigo', 'descripcion'];

    public function subpartidas()
    {
        return $this->hasMany(Subpartida::class);
    }
}
