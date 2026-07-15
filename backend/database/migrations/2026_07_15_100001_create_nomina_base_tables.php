<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * TAREA 01 — Migraciones Tablas Base del Módulo de Nómina
 * Tablas sin FK hacia employees (deben existir antes que employees)
 * 
 * Tablas creadas:
 *  1. departments
 *  2. positions
 *  3. work_schedules
 *  4. payroll_groups
 *  5. afps
 *  6. arss
 *  7. banks
 */
return new class extends Migration
{
    public function up(): void
    {
        // 1. Departamentos — centros de costo organizativos
        Schema::create('departments', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('cost_center_code')->nullable()->comment('Código de centro de costo contable');
            $table->unsignedBigInteger('manager_id')->nullable()->comment('FK → employees (se agrega constraint después)');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();
        });

        // 2. Posiciones / Cargos
        Schema::create('positions', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->foreignId('department_id')->nullable()->constrained('departments')->nullOnDelete();
            $table->decimal('salary_min', 12, 2)->nullable();
            $table->decimal('salary_max', 12, 2)->nullable();
            $table->text('job_description')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();
        });

        // 3. Horarios de trabajo
        Schema::create('work_schedules', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->tinyInteger('days_per_week')->default(5);
            $table->decimal('hours_per_day', 4, 2)->default(8.00);
            $table->time('entry_time')->nullable();
            $table->time('exit_time')->nullable();
            $table->boolean('is_night_shift')->default(false)->comment('Para cálculo de recargo nocturno');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // 4. Grupos de nómina (semanal, quincenal, mensual)
        Schema::create('payroll_groups', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->enum('frequency', ['weekly', 'biweekly', 'monthly'])->comment('Frecuencia de pago');
            $table->tinyInteger('cutoff_day')->nullable()->comment('Día de corte del periodo');
            $table->tinyInteger('payment_day')->nullable()->comment('Día de pago');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // 5. AFPs — Administradoras de Fondos de Pensiones (RD: Siembra, Popular, Reservas, Scotia, Romana)
        Schema::create('afps', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('code')->unique()->nullable()->comment('Código oficial TSS');
            $table->string('phone')->nullable();
            $table->string('website')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // 6. ARSs — Administradoras de Riesgos de Salud (RD: ARS Senasa, Humano, ARS Reservas, etc.)
        Schema::create('arss', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('code')->unique()->nullable()->comment('Código oficial TSS');
            $table->string('phone')->nullable();
            $table->string('website')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // 7. Bancos (para datos bancarios del empleado)
        Schema::create('banks', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('code')->unique()->nullable()->comment('Código SIBOIF/BCRD');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        // Orden inverso para respetar FK constraints
        Schema::dropIfExists('banks');
        Schema::dropIfExists('arss');
        Schema::dropIfExists('afps');
        Schema::dropIfExists('payroll_groups');
        Schema::dropIfExists('work_schedules');
        Schema::dropIfExists('positions');
        Schema::dropIfExists('departments');
    }
};
