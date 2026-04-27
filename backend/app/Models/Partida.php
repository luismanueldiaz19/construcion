<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Partida extends Model
{
    protected $fillable = ['proyecto_id', 'codigo', 'descripcion'];

    public function proyecto()
    {
        return $this->belongsTo(Proyecto::class);
    }

    public function subpartidas()
    {
        return $this->hasMany(Subpartida::class);
    }

    public function documentos()
    {
        return $this->hasMany(Documento::class);
    }
}
