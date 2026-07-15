<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use App\Models\Afp;
use App\Models\Ars;
use App\Models\Bank;
use App\Models\PayrollLegalParameter;
use App\Models\PayrollConcept;
use App\Models\PayrollGroup;
use App\Models\WorkSchedule;

/**
 * TAREA 05 — Seeder del Módulo de Nómina
 *
 * Siembra datos de referencia para la República Dominicana 2026.
 * IMPORTANTE: Validar porcentajes TSS e ISR con valores oficiales vigentes
 * de la Tesorería de la Seguridad Social (TSS) y la DGII antes de usar
 * este sistema en producción.
 *
 * Fuentes legales:
 *   - Ley 87-01 (Seguridad Social RD)
 *   - Código Tributario RD (ISR sobre salarios)
 *   - Decreto 258-19 (INFOTEP)
 */
class NominaSeeder extends Seeder
{
    public function run(): void
    {
        $this->seedAfps();
        $this->seedArss();
        $this->seedBanks();
        $this->seedPayrollGroups();
        $this->seedWorkSchedules();
        $this->seedLegalParameters();
        $this->seedPayrollConcepts();
    }

    // ──────────────── AFPs ────────────────

    private function seedAfps(): void
    {
        $afps = [
            ['name' => 'AFP Siembra',   'code' => 'SIE', 'is_active' => true],
            ['name' => 'AFP Popular',   'code' => 'POP', 'is_active' => true],
            ['name' => 'AFP Reservas',  'code' => 'RES', 'is_active' => true],
            ['name' => 'AFP Scotia',    'code' => 'SCO', 'is_active' => true],
            ['name' => 'AFP Romana',    'code' => 'ROM', 'is_active' => true],
            ['name' => 'AFP ProFuturo', 'code' => 'PRO', 'is_active' => true],
        ];

        foreach ($afps as $afp) {
            Afp::firstOrCreate(['code' => $afp['code']], $afp);
        }
    }

    // ──────────────── ARSs ────────────────

    private function seedArss(): void
    {
        $arss = [
            ['name' => 'ARS SENASA',         'code' => 'SEN', 'is_active' => true],
            ['name' => 'ARS Humano',         'code' => 'HUM', 'is_active' => true],
            ['name' => 'ARS Reservas',       'code' => 'RES', 'is_active' => true],
            ['name' => 'ARS Futuro',         'code' => 'FUT', 'is_active' => true],
            ['name' => 'ARS Meta Salud',     'code' => 'MET', 'is_active' => true],
            ['name' => 'ARS Yunen',          'code' => 'YUN', 'is_active' => true],
            ['name' => 'ARS Universal',      'code' => 'UNI', 'is_active' => true],
            ['name' => 'ARS Simag',          'code' => 'SIM', 'is_active' => true],
        ];

        foreach ($arss as $ars) {
            Ars::firstOrCreate(['code' => $ars['code']], $ars);
        }
    }

    // ──────────────── BANCOS ────────────────

    private function seedBanks(): void
    {
        $banks = [
            ['name' => 'Banco Popular Dominicano', 'code' => 'BPD'],
            ['name' => 'Banco de Reservas',        'code' => 'BDR'],
            ['name' => 'Scotiabank',               'code' => 'SCO'],
            ['name' => 'BHD León',                 'code' => 'BHD'],
            ['name' => 'Banreservas',              'code' => 'BAN'],
            ['name' => 'Banco Santa Cruz',         'code' => 'BSC'],
            ['name' => 'Citibank',                 'code' => 'CIT'],
            ['name' => 'Banco López de Haro',      'code' => 'BLH'],
            ['name' => 'Asociación Popular',       'code' => 'APS'],
            ['name' => 'Asociación La Nacional',   'code' => 'ALN'],
            ['name' => 'Banesco',                  'code' => 'BNE'],
        ];

        foreach ($banks as $bank) {
            Bank::firstOrCreate(['code' => $bank['code']], array_merge($bank, ['is_active' => true]));
        }
    }

    // ──────────────── GRUPOS DE NÓMINA ────────────────

    private function seedPayrollGroups(): void
    {
        $groups = [
            [
                'name'        => 'Nómina Mensual',
                'frequency'   => 'monthly',
                'cutoff_day'  => 25,
                'payment_day' => 30,
                'is_active'   => true,
            ],
            [
                'name'        => 'Nómina Quincenal',
                'frequency'   => 'biweekly',
                'cutoff_day'  => 13,
                'payment_day' => 15,
                'is_active'   => true,
            ],
            [
                'name'        => 'Nómina Semanal',
                'frequency'   => 'weekly',
                'cutoff_day'  => 4,
                'payment_day' => 5,
                'is_active'   => true,
            ],
        ];

        foreach ($groups as $group) {
            PayrollGroup::firstOrCreate(['name' => $group['name']], $group);
        }
    }

    // ──────────────── HORARIOS DE TRABAJO ────────────────

    private function seedWorkSchedules(): void
    {
        $schedules = [
            [
                'name'          => 'Jornada Regular (8h)',
                'days_per_week' => 5,
                'hours_per_day' => 8.00,
                'entry_time'    => '08:00',
                'exit_time'     => '17:00',
                'is_night_shift' => false,
                'is_active'      => true,
            ],
            [
                'name'          => 'Jornada Nocturna',
                'days_per_week' => 5,
                'hours_per_day' => 7.50,
                'entry_time'    => '21:00',
                'exit_time'     => '05:00',
                'is_night_shift' => true,
                'is_active'      => true,
            ],
            [
                'name'          => 'Jornada 6 días',
                'days_per_week' => 6,
                'hours_per_day' => 8.00,
                'entry_time'    => '07:00',
                'exit_time'     => '15:00',
                'is_night_shift' => false,
                'is_active'      => true,
            ],
        ];

        foreach ($schedules as $schedule) {
            WorkSchedule::firstOrCreate(['name' => $schedule['name']], $schedule);
        }
    }

    // ──────────────── PARÁMETROS LEGALES 2026 (RD) ────────────────

    private function seedLegalParameters(): void
    {
        /**
         * AVISO: Estos valores son de referencia para República Dominicana 2026.
         * Fuente: TSS (www.tss.gob.do) y DGII (www.dgii.gov.do)
         * VALIDAR antes de usar en producción.
         */
        $params = [
            // ── TSS Empleado ──
            [
                'code'            => 'TSS_EMPLEADO_SFS',
                'name'            => 'TSS Empleado - Seguro Familiar de Salud',
                'category'        => 'tss',
                'value'           => 3.04,
                'value_type'      => 'percentage',
                'cap_amount'      => null,
                'country_code'    => 'DO',
                'fiscal_year'     => 2026,
                'effective_from'  => '2024-01-01',
                'effective_to'    => null,
                'legal_reference' => 'Ley 87-01, Art. 135 — modificado por Decreto',
                'is_active'       => true,
            ],
            [
                'code'            => 'TSS_EMPLEADO_AFP',
                'name'            => 'TSS Empleado - Pensión (AFP)',
                'category'        => 'tss',
                'value'           => 2.87,
                'value_type'      => 'percentage',
                'cap_amount'      => null,
                'country_code'    => 'DO',
                'fiscal_year'     => 2026,
                'effective_from'  => '2024-01-01',
                'effective_to'    => null,
                'legal_reference' => 'Ley 87-01',
                'is_active'       => true,
            ],
            // ── TSS Patronal ──
            [
                'code'            => 'TSS_PATRONAL_SFS',
                'name'            => 'TSS Patronal - Seguro Familiar de Salud',
                'category'        => 'tss',
                'value'           => 7.09,
                'value_type'      => 'percentage',
                'cap_amount'      => null,
                'country_code'    => 'DO',
                'fiscal_year'     => 2026,
                'effective_from'  => '2024-01-01',
                'effective_to'    => null,
                'legal_reference' => 'Ley 87-01',
                'is_active'       => true,
            ],
            [
                'code'            => 'TSS_PATRONAL_AFP',
                'name'            => 'TSS Patronal - Pensión (AFP)',
                'category'        => 'tss',
                'value'           => 7.10,
                'value_type'      => 'percentage',
                'cap_amount'      => null,
                'country_code'    => 'DO',
                'fiscal_year'     => 2026,
                'effective_from'  => '2024-01-01',
                'effective_to'    => null,
                'legal_reference' => 'Ley 87-01',
                'is_active'       => true,
            ],
            [
                'code'            => 'TSS_PATRONAL_SRL',
                'name'            => 'Seguro de Riesgos Laborales (Patronal)',
                'category'        => 'tss',
                'value'           => 1.10,
                'value_type'      => 'percentage',
                'cap_amount'      => null,
                'country_code'    => 'DO',
                'fiscal_year'     => 2026,
                'effective_from'  => '2024-01-01',
                'effective_to'    => null,
                'legal_reference' => 'Ley 87-01, Art. 196',
                'is_active'       => true,
            ],
            // ── INFOTEP ──
            [
                'code'            => 'INFOTEP',
                'name'            => 'Contribución INFOTEP (Patronal)',
                'category'        => 'infotep',
                'value'           => 1.00,
                'value_type'      => 'percentage',
                'cap_amount'      => null,
                'country_code'    => 'DO',
                'fiscal_year'     => 2026,
                'effective_from'  => '2024-01-01',
                'effective_to'    => null,
                'legal_reference' => 'Decreto 258-19',
                'is_active'       => true,
            ],
            // ── ISR — Exención anual y escala progresiva 2026 (valores de ejemplo) ──
            [
                'code'            => 'ISR_EXENTO_ANUAL',
                'name'            => 'ISR - Monto Exento Anual',
                'category'        => 'isr',
                'value'           => 416220.00,  // Ajustar según DGII cada año
                'value_type'      => 'amount',
                'cap_amount'      => null,
                'country_code'    => 'DO',
                'fiscal_year'     => 2026,
                'effective_from'  => '2026-01-01',
                'effective_to'    => '2026-12-31',
                'legal_reference' => 'Código Tributario RD, Art. 296 — Indexado por inflación (publicar en enero)',
                'is_active'       => true,
            ],
            // Tramos ISR — almacenamos como parámetros separados (tasa marginal de cada tramo)
            [
                'code'            => 'ISR_TRAMO_2_TASA',
                'name'            => 'ISR - Tasa Tramo 2 (416,220.01 a 624,329)',
                'category'        => 'isr',
                'value'           => 15.00,
                'value_type'      => 'percentage',
                'cap_amount'      => 624329.00,
                'country_code'    => 'DO',
                'fiscal_year'     => 2026,
                'effective_from'  => '2026-01-01',
                'effective_to'    => '2026-12-31',
                'legal_reference' => 'Código Tributario RD, Art. 296',
                'is_active'       => true,
            ],
            [
                'code'            => 'ISR_TRAMO_3_TASA',
                'name'            => 'ISR - Tasa Tramo 3 (624,329.01 a 867,123)',
                'category'        => 'isr',
                'value'           => 20.00,
                'value_type'      => 'percentage',
                'cap_amount'      => 867123.00,
                'country_code'    => 'DO',
                'fiscal_year'     => 2026,
                'effective_from'  => '2026-01-01',
                'effective_to'    => '2026-12-31',
                'legal_reference' => 'Código Tributario RD, Art. 296',
                'is_active'       => true,
            ],
            [
                'code'            => 'ISR_TRAMO_4_TASA',
                'name'            => 'ISR - Tasa Tramo 4 (más de 867,123)',
                'category'        => 'isr',
                'value'           => 25.00,
                'value_type'      => 'percentage',
                'cap_amount'      => null,
                'country_code'    => 'DO',
                'fiscal_year'     => 2026,
                'effective_from'  => '2026-01-01',
                'effective_to'    => '2026-12-31',
                'legal_reference' => 'Código Tributario RD, Art. 296',
                'is_active'       => true,
            ],
        ];

        foreach ($params as $param) {
            PayrollLegalParameter::firstOrCreate(
                ['code' => $param['code'], 'effective_from' => $param['effective_from']],
                $param
            );
        }
    }

    // ──────────────── CONCEPTOS DE NÓMINA ────────────────

    private function seedPayrollConcepts(): void
    {
        $concepts = [
            // ── INGRESOS ──
            ['code' => 'SAL_BASE',       'name' => 'Salario Base',                    'type' => 'ingreso',         'calculation_method' => 'formula',    'is_taxable_isr' => true,  'is_tss_applicable' => true,  'is_system' => true,  'sort_order' => 1],
            ['code' => 'HE_DIURNA',      'name' => 'Horas Extras Diurnas (35%)',      'type' => 'ingreso',         'calculation_method' => 'formula',    'is_taxable_isr' => true,  'is_tss_applicable' => true,  'is_system' => false, 'sort_order' => 2],
            ['code' => 'HE_NOCTURNA',    'name' => 'Horas Extras Nocturnas (50%)',    'type' => 'ingreso',         'calculation_method' => 'formula',    'is_taxable_isr' => true,  'is_tss_applicable' => true,  'is_system' => false, 'sort_order' => 3],
            ['code' => 'HE_FESTIVO',     'name' => 'Horas Extras Festivos (100%)',    'type' => 'ingreso',         'calculation_method' => 'formula',    'is_taxable_isr' => true,  'is_tss_applicable' => true,  'is_system' => false, 'sort_order' => 4],
            ['code' => 'COMISION',       'name' => 'Comisiones',                      'type' => 'ingreso',         'calculation_method' => 'manual',     'is_taxable_isr' => true,  'is_tss_applicable' => true,  'is_system' => false, 'sort_order' => 5],
            ['code' => 'BONIFICACION',   'name' => 'Bonificación',                    'type' => 'ingreso',         'calculation_method' => 'manual',     'is_taxable_isr' => true,  'is_tss_applicable' => true,  'is_system' => false, 'sort_order' => 6],
            ['code' => 'INCENTIVO',      'name' => 'Incentivo',                       'type' => 'ingreso',         'calculation_method' => 'manual',     'is_taxable_isr' => true,  'is_tss_applicable' => true,  'is_system' => false, 'sort_order' => 7],
            ['code' => 'VIATICO_EXENTO', 'name' => 'Viáticos No Sujetos a ISR',      'type' => 'ingreso',         'calculation_method' => 'manual',     'is_taxable_isr' => false, 'is_tss_applicable' => false, 'is_system' => false, 'sort_order' => 8],
            ['code' => 'REGALIA',        'name' => 'Regalía Pascual (13vo)',          'type' => 'ingreso',         'calculation_method' => 'formula',    'is_taxable_isr' => true,  'is_tss_applicable' => false, 'is_system' => true,  'sort_order' => 9],
            ['code' => 'BONO_VAC',       'name' => 'Bono Vacacional',                'type' => 'ingreso',         'calculation_method' => 'manual',     'is_taxable_isr' => true,  'is_tss_applicable' => false, 'is_system' => false, 'sort_order' => 10],

            // ── DEDUCCIONES EMPLEADO ──
            ['code' => 'DED_TSS_SFS',    'name' => 'Deducción TSS - SFS (3.04%)',    'type' => 'deduccion',       'calculation_method' => 'porcentaje',  'default_value' => 3.04,  'is_taxable_isr' => false, 'is_tss_applicable' => false, 'is_system' => true,  'sort_order' => 20],
            ['code' => 'DED_AFP',        'name' => 'Deducción AFP - Pensión (2.87%)','type' => 'deduccion',       'calculation_method' => 'porcentaje',  'default_value' => 2.87,  'is_taxable_isr' => false, 'is_tss_applicable' => false, 'is_system' => true,  'sort_order' => 21],
            ['code' => 'DED_ISR',        'name' => 'Retención ISR',                  'type' => 'deduccion',       'calculation_method' => 'formula',    'is_taxable_isr' => false, 'is_tss_applicable' => false, 'is_system' => true,  'sort_order' => 22],
            ['code' => 'DED_PRESTAMO',   'name' => 'Descuento Préstamo/Adelanto',    'type' => 'deduccion',       'calculation_method' => 'formula',    'is_taxable_isr' => false, 'is_tss_applicable' => false, 'is_system' => false, 'sort_order' => 23],
            ['code' => 'DED_EMBARGO',    'name' => 'Embargo Judicial',               'type' => 'deduccion',       'calculation_method' => 'manual',     'is_taxable_isr' => false, 'is_tss_applicable' => false, 'is_system' => false, 'sort_order' => 24],
            ['code' => 'DED_SINDICAL',   'name' => 'Cuota Sindical',                 'type' => 'deduccion',       'calculation_method' => 'manual',     'is_taxable_isr' => false, 'is_tss_applicable' => false, 'is_system' => false, 'sort_order' => 25],
            ['code' => 'DED_SEGURO_VOL', 'name' => 'Seguro Voluntario / Cooperativa','type' => 'deduccion',      'calculation_method' => 'manual',     'is_taxable_isr' => false, 'is_tss_applicable' => false, 'is_system' => false, 'sort_order' => 26],
            ['code' => 'DED_AUSENCIA',   'name' => 'Descuento por Ausencia/Tardanza','type' => 'deduccion',      'calculation_method' => 'formula',    'is_taxable_isr' => false, 'is_tss_applicable' => false, 'is_system' => false, 'sort_order' => 27],

            // ── APORTES PATRONALES ──
            ['code' => 'PAT_TSS_SFS',    'name' => 'Aporte Patronal TSS - SFS (7.09%)',  'type' => 'aporte_patronal', 'calculation_method' => 'porcentaje', 'default_value' => 7.09,  'is_taxable_isr' => false, 'is_tss_applicable' => false, 'is_system' => true,  'sort_order' => 40],
            ['code' => 'PAT_AFP',        'name' => 'Aporte Patronal AFP - Pensión (7.10%)','type' => 'aporte_patronal','calculation_method' => 'porcentaje','default_value' => 7.10, 'is_taxable_isr' => false, 'is_tss_applicable' => false, 'is_system' => true,  'sort_order' => 41],
            ['code' => 'PAT_SRL',        'name' => 'Seguro Riesgos Laborales (1.10%)', 'type' => 'aporte_patronal',  'calculation_method' => 'porcentaje', 'default_value' => 1.10,  'is_taxable_isr' => false, 'is_tss_applicable' => false, 'is_system' => true,  'sort_order' => 42],
            ['code' => 'PAT_INFOTEP',    'name' => 'Contribución INFOTEP (1.00%)',     'type' => 'aporte_patronal',  'calculation_method' => 'porcentaje', 'default_value' => 1.00,  'is_taxable_isr' => false, 'is_tss_applicable' => false, 'is_system' => false, 'sort_order' => 43],
            ['code' => 'PROV_REGALIA',   'name' => 'Provisión Regalía Pascual (1/12)', 'type' => 'aporte_patronal',  'calculation_method' => 'formula',    'is_taxable_isr' => false, 'is_tss_applicable' => false, 'is_system' => true,  'sort_order' => 44],
            ['code' => 'PROV_VACACIONES','name' => 'Provisión Vacaciones',             'type' => 'aporte_patronal',  'calculation_method' => 'formula',    'is_taxable_isr' => false, 'is_tss_applicable' => false, 'is_system' => true,  'sort_order' => 45],
            ['code' => 'PROV_CESANTIA',  'name' => 'Provisión Cesantía/Prestaciones', 'type' => 'aporte_patronal',  'calculation_method' => 'formula',    'is_taxable_isr' => false, 'is_tss_applicable' => false, 'is_system' => true,  'sort_order' => 46],
        ];

        foreach ($concepts as $concept) {
            PayrollConcept::firstOrCreate(
                ['code' => $concept['code']],
                array_merge($concept, ['is_active' => true])
            );
        }
    }
}
