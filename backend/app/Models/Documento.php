<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Documento extends Model
{
    use HasFactory;

    protected $fillable = [
        'proyecto_id',
        'partida_id',
        'nombre',
        'tipo',
        'categoria',
        'file_path',
        'file_extension',
        'file_size',
    ];

    public function proyecto()
    {
        return $this->belongsTo(Proyecto::class);
    }

    public function partida()
    {
        return $this->belongsTo(Partida::class);
    }
}
