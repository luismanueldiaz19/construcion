<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * TAREA 03 — Migraciones del Motor de Nómina
 *
 * Tablas creadas:
 *  1. payroll_legal_parameters  — porcentajes TSS, ISR, INFOTEP versionados por vigencia
 *  2. payroll_concepts          — conceptos de nómina paramétricos (no hardcodeados)
 *  3. payroll_periods           — periodos por grupo de nómina
 *  4. payrolls                  — cabecera del proceso de nómina
 *  5. payroll_details           — desglose por empleado y concepto (nunca solo totales)
 *  6. payroll_loans             — préstamos/adelantos con amortización
 *  7. payslips                  — recibos de pago generados
 *
 * REGLA ISR: siempre calculado sobre base anualizada, prorrateado al periodo.
 * REGLA: Una nómina "cerrada" es INMUTABLE. Correcciones solo vía asiento de ajuste.
 */
return new class extends Migration
{
    public function up(): void
    {
        // 1. Parámetros legales versionados por fecha de vigencia
        //    NUNCA hardcodear porcentajes en código — la ley cambia
        Schema::create('payroll_legal_parameters', function (Blueprint $table) {
            $table->id();
            $table->string('code')->comment('ej: TSS_EMPLEADO_SFS, AFP_EMPLEADO, ISR_EXENTO_ANUAL, INFOTEP');
            $table->string('name')->comment('Nombre descriptivo del parámetro');
            $table->enum('category', ['tss', 'isr', 'infotep', 'srl', 'otro']);
            $table->decimal('value', 14, 4)->comment('Porcentaje o monto según aplique (soporta montos ISR como 416220.00)');
            $table->enum('value_type', ['percentage', 'amount'])->default('percentage');
            $table->decimal('cap_amount', 12, 2)->nullable()->comment('Tope salarial cotizable si aplica');
            $table->string('country_code', 5)->default('DO')->comment('DO = República Dominicana');
            $table->smallInteger('fiscal_year')->nullable()->comment('Año fiscal de referencia');
            $table->date('effective_from');
            $table->date('effective_to')->nullable()->comment('NULL = vigente actualmente');
            $table->text('legal_reference')->nullable()->comment('Ej: Ley 87-01, Art. 7');
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->index(['code', 'effective_from', 'effective_to']);
            $table->index('country_code');
        });

        // 2. Conceptos de nómina — tabla paramétrica, NO hardcodeada
        Schema::create('payroll_concepts', function (Blueprint $table) {
            $table->id();
            $table->string('code')->unique()->comment('Ej: SAL_BASE, TSS_SFS_EMP, ISR, HE_DIURNA');
            $table->string('name');
            $table->enum('type', ['ingreso', 'deduccion', 'aporte_patronal'])
                  ->comment('ingreso = suma al bruto, deduccion = resta al neto, aporte_patronal = gasto empresa');
            $table->enum('calculation_method', ['fijo', 'porcentaje', 'formula', 'manual'])
                  ->default('manual');
            $table->decimal('default_value', 10, 4)->nullable()
                  ->comment('Porcentaje o monto base por defecto');
            $table->boolean('is_taxable_isr')->default(true)
                  ->comment('¿Este ingreso entra en la base gravable ISR?');
            $table->boolean('is_tss_applicable')->default(true)
                  ->comment('¿Este ingreso entra en el salario cotizable TSS?');
            $table->unsignedBigInteger('accounting_account_id')->nullable()
                  ->comment('FK → catalogo_cuentas');
            $table->boolean('is_system')->default(false)
                  ->comment('true = no puede eliminarse ni cambiar el code');
            $table->boolean('is_active')->default(true);
            $table->integer('sort_order')->default(0)->comment('Orden de aparición en el recibo');
            $table->timestamps();

            $table->foreign('accounting_account_id')
                  ->references('id')->on('catalogo_cuentas')
                  ->nullOnDelete();
        });

        // 3. Periodos de nómina por grupo
        Schema::create('payroll_periods', function (Blueprint $table) {
            $table->id();
            $table->foreignId('payroll_group_id')->constrained('payroll_groups');
            $table->date('start_date');
            $table->date('end_date');
            $table->date('payment_date');
            $table->smallInteger('fiscal_year');
            $table->tinyInteger('period_number')->comment('Número de periodo dentro del año');
            $table->enum('status', ['abierto', 'calculado', 'revisado', 'aprobado', 'pagado', 'cerrado'])
                  ->default('abierto');
            $table->timestamps();

            $table->unique(['payroll_group_id', 'start_date', 'end_date']);
            $table->index(['fiscal_year', 'status']);
        });

        // 4. Cabecera del proceso de nómina
        Schema::create('payrolls', function (Blueprint $table) {
            $table->id();
            $table->foreignId('payroll_period_id')->constrained('payroll_periods');
            $table->enum('status', ['borrador', 'calculado', 'revisado', 'aprobado', 'pagado', 'cerrado'])
                  ->default('borrador');

            // Totales — siempre calculados desde payroll_details
            $table->decimal('total_gross', 14, 2)->default(0)->comment('Total devengado bruto');
            $table->decimal('total_deductions', 14, 2)->default(0)->comment('Total deducciones empleado');
            $table->decimal('total_net', 14, 2)->default(0)->comment('Neto a pagar empleados');
            $table->decimal('total_employer_cost', 14, 2)->default(0)->comment('Costo total empresa (neto + aportes patronales)');
            $table->decimal('total_isr', 14, 2)->default(0);
            $table->decimal('total_tss_employee', 14, 2)->default(0);
            $table->decimal('total_tss_employer', 14, 2)->default(0);

            // Flujo de aprobación — segregación de funciones (quien calcula ≠ quien aprueba)
            $table->unsignedBigInteger('processed_by')->nullable()->comment('FK → users: quien calculó');
            $table->unsignedBigInteger('reviewed_by')->nullable()->comment('FK → users: RRHH');
            $table->unsignedBigInteger('approved_by')->nullable()->comment('FK → users: Finanzas');
            $table->unsignedBigInteger('paid_by')->nullable()->comment('FK → users: quien registró el pago');

            $table->timestamp('processed_at')->nullable();
            $table->timestamp('reviewed_at')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->timestamp('paid_at')->nullable();
            $table->timestamp('closed_at')->nullable();

            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['payroll_period_id', 'status']);
        });

        // 5. Detalle de nómina por empleado y concepto — NUNCA solo guardar totales
        Schema::create('payroll_details', function (Blueprint $table) {
            $table->id();
            $table->foreignId('payroll_id')->constrained('payrolls')->cascadeOnDelete();
            $table->foreignId('employee_id')->constrained('employees');
            $table->foreignId('payroll_concept_id')->constrained('payroll_concepts');
            $table->enum('type', ['ingreso', 'deduccion', 'aporte_patronal']);
            $table->decimal('amount', 12, 2);
            $table->decimal('quantity', 8, 4)->default(1)->comment('Unidades/horas si aplica');
            $table->decimal('rate', 10, 4)->nullable()->comment('Tarifa unitaria si aplica');
            $table->text('notes')->nullable();
            $table->boolean('is_manual_override')->default(false)->comment('true = editado manualmente, no recalcular auto');
            $table->timestamps();

            $table->index(['payroll_id', 'employee_id']);
            $table->index(['employee_id', 'payroll_concept_id']);
        });

        // 6. Préstamos y adelantos de nómina con tabla de amortización
        Schema::create('payroll_loans', function (Blueprint $table) {
            $table->id();
            $table->foreignId('employee_id')->constrained('employees');
            $table->string('reference_code')->nullable()->comment('Código interno del préstamo');
            $table->enum('loan_type', ['prestamo', 'adelanto', 'embargo_judicial', 'cuota_sindical', 'otro'])
                  ->default('prestamo');
            $table->decimal('original_amount', 12, 2)->comment('Monto original del préstamo');
            $table->decimal('outstanding_balance', 12, 2)->comment('Saldo pendiente actual');
            $table->decimal('monthly_installment', 12, 2)->comment('Cuota por periodo');
            $table->integer('total_installments')->nullable()->comment('Número total de cuotas');
            $table->integer('remaining_installments')->nullable()->comment('Cuotas restantes');
            $table->date('start_date');
            $table->date('expected_end_date')->nullable();
            $table->enum('status', ['activo', 'pagado', 'cancelado'])->default('activo');
            $table->text('description')->nullable();
            $table->unsignedBigInteger('approved_by')->nullable()->comment('FK → users');
            $table->timestamp('approved_at')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['employee_id', 'status']);
        });

        // 7. Recibos de pago generados (payslips)
        Schema::create('payslips', function (Blueprint $table) {
            $table->id();
            $table->foreignId('payroll_id')->constrained('payrolls')->cascadeOnDelete();
            $table->foreignId('employee_id')->constrained('employees');
            $table->string('pdf_path')->nullable()->comment('Ruta del PDF generado');
            $table->boolean('email_sent')->default(false);
            $table->timestamp('email_sent_at')->nullable();
            $table->timestamps();

            $table->unique(['payroll_id', 'employee_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payslips');
        Schema::dropIfExists('payroll_loans');
        Schema::dropIfExists('payroll_details');
        Schema::dropIfExists('payrolls');
        Schema::dropIfExists('payroll_periods');
        Schema::dropIfExists('payroll_concepts');
        Schema::dropIfExists('payroll_legal_parameters');
    }
};
