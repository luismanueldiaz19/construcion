<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * Conceptos de nómina — tabla paramétrica, NO hardcodeada.
 * Cada concepto tiene su cuenta contable asociada para
 * generar el asiento automático en partida doble.
 */
class PayrollConcept extends Model
{
    protected $fillable = [
        'code',
        'name',
        'type',
        'calculation_method',
        'default_value',
        'is_taxable_isr',
        'is_tss_applicable',
        'accounting_account_id',
        'is_system',
        'is_active',
        'sort_order',
    ];

    protected $casts = [
        'default_value'     => 'decimal:4',
        'is_taxable_isr'    => 'boolean',
        'is_tss_applicable' => 'boolean',
        'is_system'         => 'boolean',
        'is_active'         => 'boolean',
    ];

    public function accountingAccount(): BelongsTo
    {
        return $this->belongsTo(CatalogoCuenta::class, 'accounting_account_id');
    }

    public function payrollDetails(): HasMany
    {
        return $this->hasMany(PayrollDetail::class);
    }

    // ── Scopes útiles ──

    public function scopeIngresos($query)
    {
        return $query->where('type', 'ingreso')->where('is_active', true);
    }

    public function scopeDeducciones($query)
    {
        return $query->where('type', 'deduccion')->where('is_active', true);
    }

    public function scopeAportesPatronales($query)
    {
        return $query->where('type', 'aporte_patronal')->where('is_active', true);
    }
}
