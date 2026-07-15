<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * TAREA 02 — Migración de employees y tablas hijas
 *
 * Tablas creadas:
 *  1. employees — tabla principal (soft deletes, NUNCA eliminar físicamente)
 *  2. employee_dependents
 *  3. employee_documents
 *  4. employee_salary_history (auditoría inmutable de cambios salariales)
 *  5. employee_status_history (auditoría de cambios de estatus)
 *  6. employee_bank_accounts
 *
 * REGLA: Nunca eliminar físicamente un empleado con nómina.
 *        Solo soft delete + status = desvinculado.
 */
return new class extends Migration
{
    public function up(): void
    {
        // 1. Tabla principal de empleados
        Schema::create('employees', function (Blueprint $table) {
            $table->id();

            // Identificación
            $table->string('employee_code')->unique()->comment('EMP-0001, autogenerado');
            $table->string('first_name');
            $table->string('last_name');
            $table->enum('identification_type', ['cedula', 'pasaporte', 'rnc'])->default('cedula');
            $table->string('identification_number')->unique();
            $table->date('birth_date')->nullable();
            $table->enum('gender', ['M', 'F', 'otro'])->nullable();
            $table->enum('marital_status', ['soltero', 'casado', 'divorciado', 'viudo', 'union_libre'])->nullable();
            $table->string('nationality')->default('Dominicana');

            // Contacto
            $table->string('email')->unique()->nullable();
            $table->string('phone')->nullable();
            $table->text('address')->nullable();
            $table->string('city')->nullable();
            $table->string('province')->nullable();
            $table->string('photo_path')->nullable();

            // Información laboral
            $table->date('hire_date');
            $table->date('termination_date')->nullable();
            $table->enum('employment_status', [
                'activo', 'inactivo', 'suspendido', 'vacaciones', 'licencia', 'desvinculado'
            ])->default('activo');
            $table->enum('contract_type', [
                'indefinido', 'definido', 'por_obra', 'aprendizaje'
            ])->default('indefinido');
            $table->date('contract_end_date')->nullable()->comment('Obligatorio si contract_type = definido');

            // Referencias organizativas
            $table->foreignId('position_id')->nullable()->constrained('positions')->nullOnDelete();
            $table->foreignId('department_id')->nullable()->constrained('departments')->nullOnDelete();
            $table->foreignId('work_schedule_id')->nullable()->constrained('work_schedules')->nullOnDelete();
            $table->foreignId('payroll_group_id')->nullable()->constrained('payroll_groups')->nullOnDelete()->comment('Define frecuencia: semanal/quincenal/mensual');

            // Salario
            $table->decimal('base_salary', 12, 2)->default(0);
            $table->enum('salary_type', ['fijo', 'por_hora', 'comision', 'mixto'])->default('fijo');
            $table->enum('payment_method', ['transferencia', 'cheque', 'efectivo'])->default('transferencia');

            // Banco (principal — detalle en employee_bank_accounts)
            $table->foreignId('bank_id')->nullable()->constrained('banks')->nullOnDelete();
            $table->string('bank_account_number')->nullable();
            $table->enum('bank_account_type', ['ahorro', 'corriente'])->nullable();

            // TSS / AFP / ARS
            $table->string('tss_number')->nullable()->comment('Número de afiliación TSS');
            $table->foreignId('afp_id')->nullable()->constrained('afps')->nullOnDelete();
            $table->foreignId('ars_id')->nullable()->constrained('arss')->nullOnDelete();
            $table->boolean('is_tss_exempt')->default(false);
            $table->boolean('is_isr_exempt')->default(false);

            // Organigrama — FK autoreferencial
            $table->foreignId('supervisor_id')->nullable()->constrained('employees')->nullOnDelete();

            // Auditoría de creación/modificación
            $table->unsignedBigInteger('created_by')->nullable();
            $table->unsignedBigInteger('updated_by')->nullable();

            $table->timestamps();
            $table->softDeletes(); // NUNCA borrar físicamente
        });

        // Agregar el constraint del manager del departamento ahora que employees existe
        Schema::table('departments', function (Blueprint $table) {
            $table->foreign('manager_id')->references('id')->on('employees')->nullOnDelete();
        });

        // 2. Dependientes del empleado (afectan exenciones ISR)
        Schema::create('employee_dependents', function (Blueprint $table) {
            $table->id();
            $table->foreignId('employee_id')->constrained('employees')->cascadeOnDelete();
            $table->string('name');
            $table->enum('relationship', ['hijo', 'hija', 'conyuge', 'padre', 'madre', 'otro']);
            $table->date('birth_date')->nullable();
            $table->boolean('is_isr_dependent')->default(false)->comment('Afecta exenciones ISR');
            $table->timestamps();
        });

        // 3. Documentos del empleado
        Schema::create('employee_documents', function (Blueprint $table) {
            $table->id();
            $table->foreignId('employee_id')->constrained('employees')->cascadeOnDelete();
            $table->enum('document_type', [
                'contrato', 'cedula', 'titulo', 'certificacion', 'otro'
            ]);
            $table->string('file_path');
            $table->string('file_name')->nullable();
            $table->date('expiration_date')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
        });

        // 4. Histórico de cambios salariales — INMUTABLE (solo INSERT, nunca UPDATE/DELETE)
        Schema::create('employee_salary_history', function (Blueprint $table) {
            $table->id();
            $table->foreignId('employee_id')->constrained('employees')->cascadeOnDelete();
            $table->decimal('previous_salary', 12, 2);
            $table->decimal('new_salary', 12, 2);
            $table->date('effective_date');
            $table->string('reason')->comment('Motivo del cambio salarial obligatorio');
            $table->unsignedBigInteger('approved_by')->nullable()->comment('FK → users');
            $table->timestamps();
        });

        // 5. Histórico de estatus — ascensos, traslados, suspensiones, reingresos
        Schema::create('employee_status_history', function (Blueprint $table) {
            $table->id();
            $table->foreignId('employee_id')->constrained('employees')->cascadeOnDelete();
            $table->string('previous_status')->nullable();
            $table->string('new_status');
            $table->string('previous_department')->nullable();
            $table->string('new_department')->nullable();
            $table->string('previous_position')->nullable();
            $table->string('new_position')->nullable();
            $table->date('effective_date');
            $table->string('reason')->nullable();
            $table->unsignedBigInteger('registered_by')->nullable()->comment('FK → users');
            $table->timestamps();
        });

        // 6. Cuentas bancarias adicionales del empleado (para distribución de pago)
        Schema::create('employee_bank_accounts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('employee_id')->constrained('employees')->cascadeOnDelete();
            $table->foreignId('bank_id')->constrained('banks');
            $table->string('account_number');
            $table->enum('account_type', ['ahorro', 'corriente']);
            $table->decimal('allocation_percentage', 5, 2)->default(100)->comment('Porcentaje del neto a depositar aquí');
            $table->boolean('is_primary')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        // Primero remover el FK de departments.manager_id
        Schema::table('departments', function (Blueprint $table) {
            $table->dropForeign(['manager_id']);
        });

        Schema::dropIfExists('employee_bank_accounts');
        Schema::dropIfExists('employee_status_history');
        Schema::dropIfExists('employee_salary_history');
        Schema::dropIfExists('employee_documents');
        Schema::dropIfExists('employee_dependents');
        Schema::dropIfExists('employees');
    }
};
