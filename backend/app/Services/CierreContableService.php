<?php

namespace App\Services;

use App\Models\CierreContable;
use Carbon\Carbon;
use Exception;

class CierreContableService
{
    /**
     * Valida si la fecha proporcionada cae en un periodo contable cerrado.
     * Si está cerrado, lanza una excepción abortando la transacción.
     *
     * @param string $fecha (Y-m-d)
     * @throws Exception
     */
    public function validarPeriodoAbierto(string $fecha): void
    {
        $parsedDate = Carbon::parse($fecha);
        $anio = $parsedDate->year;
        $mes = $parsedDate->month;

        $cierre = CierreContable::where('anio', $anio)->where('mes', $mes)->first();

        if ($cierre && $cierre->estado === 'cerrado') {
            throw new Exception("Operación rechazada: El periodo contable correspondiente a esta fecha ({$mes}/{$anio}) se encuentra cerrado. Comuníquese con el administrador contable.");
        }
    }

    /**
     * Cambia el estado de un mes a cerrado (Bloqueo/Candado).
     */
    public function cerrarPeriodo(int $anio, int $mes, int $userId): CierreContable
    {
        // TODO: En el futuro, antes de cerrar, verificar que todos los bancos estén cuadrados (Conciliaciones).

        $cierre = CierreContable::firstOrCreate(
            ['anio' => $anio, 'mes' => $mes]
        );

        if ($cierre->estado === 'cerrado') {
            throw new Exception("El periodo ya está cerrado.");
        }

        $cierre->estado = 'cerrado';
        $cierre->cerrado_por = $userId;
        $cierre->cerrado_el = now();
        $cierre->save();

        // TODO: Si es diciembre ($mes == 12), ejecutar Asientos de Cierre para las cuentas de Resultados.

        return $cierre;
    }
}
