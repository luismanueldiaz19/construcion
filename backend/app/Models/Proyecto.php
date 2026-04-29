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

    public function pagos()
    {
        return $this->hasMany(PagoCliente::class);
    }

    public function getTotalPresupuestoConGlobalesAttribute()
    {
        $base = $this->partidas->sum(function($p) {
            return $p->subpartidas->sum('total_presupuestado');
        });
        return $base + $this->itbis + $this->transporte + $this->otros_costos + $this->supervision_tecnica;
    }

    public function getPorcentajeAvanceTotalAttribute()
    {
        $totalPresupuestado = $this->partidas->sum(function($p) {
            return $p->subpartidas->sum('total_presupuestado');
        });

        if ($totalPresupuestado == 0) return 0;

        $totalEjecutado = $this->partidas->sum(function($p) {
            return $p->subpartidas->sum('valor_ejecutado');
        });

        return round(($totalEjecutado / $totalPresupuestado) * 100, 2);
    }

    public function getMontoEjecutadoTotalAttribute()
    {
        return $this->partidas->sum(function($p) {
            return $p->subpartidas->sum('valor_ejecutado');
        });
    }

    public function getTotalCobradoAttribute()
    {
        return $this->pagos()->sum('monto');
    }
}
