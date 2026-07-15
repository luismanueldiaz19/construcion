<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * Parámetros legales versionados por fecha de vigencia.
 *
 * REGLA: NUNCA hardcodear porcentajes en código.
 * Valores de ejemplo para República Dominicana 2026.
 * Validar con valores oficiales vigentes antes de producción.
 *
 * Ejemplos de codes:
 *   TSS_EMPLEADO_SFS    → 3.04%  (Seguro Familiar de Salud - empleado)
 *   TSS_PATRONAL_SFS    → 7.09%  (Seguro Familiar de Salud - patronal)
 *   AFP_EMPLEADO        → 2.87%  (Pensión - empleado)
 *   AFP_PATRONAL        → 7.10%  (Pensión - patronal)
 *   SRL                 → 1.10%  (Seguro Riesgos Laborales)
 *   INFOTEP             → 1.00%  (Capacitación)
 *   ISR_EXENTO_ANUAL    → monto exento anual en RD$
 */
class PayrollLegalParameter extends Model
{
    protected $fillable = [
        'code',
        'name',
        'category',
        'value',
        'value_type',
        'cap_amount',
        'country_code',
        'fiscal_year',
        'effective_from',
        'effective_to',
        'legal_reference',
        'is_active',
    ];

    protected $casts = [
        'value'          => 'decimal:6',
        'cap_amount'     => 'decimal:2',
        'effective_from' => 'date',
        'effective_to'   => 'date',
        'is_active'      => 'boolean',
    ];

    /**
     * Obtiene el parámetro vigente por code en una fecha dada.
     */
    public static function getActive(string $code, ?\DateTimeInterface $date = null): ?self
    {
        $date = $date ?? now();

        return static::where('code', $code)
            ->where('is_active', true)
            ->where('effective_from', '<=', $date)
            ->where(function ($q) use ($date) {
                $q->whereNull('effective_to')
                  ->orWhere('effective_to', '>=', $date);
            })
            ->orderByDesc('effective_from')
            ->first();
    }
}
