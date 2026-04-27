<?php

namespace App\Services;

use App\Models\AsientoContable;
use App\Models\AsientoDetalle;
use App\Models\CatalogoCuenta;
use Illuminate\Support\Facades\DB;

class AsientoService
{
    /**
     * Registra un asiento contable completo.
     * 
     * @param string $fecha
     * @param string $glosa
     * @param array $detalles [['cuenta_id' => 1, 'debe' => 100, 'haber' => 0, 'centro_costo_id' => null], ...]
     * @param string|null $referenciaTipo
     * @param int|null $referenciaId
     * @return AsientoContable
     */
    public function registrarAsiento(string $fecha, string $glosa, array $detalles, $referenciaTipo = null, $referenciaId = null)
    {
        return DB::transaction(function () use ($fecha, $glosa, $detalles, $referenciaTipo, $referenciaId) {
            $asiento = AsientoContable::create([
                'fecha' => $fecha,
                'glosa' => $glosa,
                'referencia_tipo' => $referenciaTipo,
                'referencia_id' => $referenciaId
            ]);

            foreach ($detalles as $detalle) {
                AsientoDetalle::create([
                    'asiento_id' => $asiento->id,
                    'cuenta_id' => $detalle['cuenta_id'],
                    'debe' => $detalle['debe'] ?? 0,
                    'haber' => $detalle['haber'] ?? 0,
                    'centro_costo_id' => $detalle['centro_costo_id'] ?? null,
                    'subpartida_id' => $detalle['subpartida_id'] ?? null,
                ]);
            }

            return $asiento;
        });
    }
}
