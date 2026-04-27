<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Proyecto extends Model
{
    protected $fillable = [
        'nombre', 'cliente', 'ubicacion', 'fecha_inicio', 'fecha_fin', 
        'presupuesto_estimado', 'estado', 'itbis', 'transporte', 'otros_costos', 'supervision_tecnica',
        'logo_path', 'notas'
    ];

    public function partidas()
    {
        return $this->hasMany(Partida::class);
    }

    public function compraDetalles()
    {
        return $this->hasMany(CompraDetalle::class);
    }

    public function inventarios()
    {
        return $this->hasMany(Inventario::class);
    }

    public function documentos()
    {
        return $this->hasMany(Documento::class);
    }
}
