<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('proyectos', function (Blueprint $table) {
            $table->id();
            $table->string('nombre');
            $table->string('cliente')->nullable();
            $table->string('ubicacion')->nullable();
            $table->date('fecha_inicio')->nullable();
            $table->date('fecha_fin')->nullable();
            $table->decimal('presupuesto_estimado', 15, 2)->default(0);
            $table->decimal('itbis', 15, 2)->default(0);
            $table->decimal('transporte', 15, 2)->default(0);
            $table->decimal('otros_costos', 15, 2)->default(0);
            $table->decimal('supervision_tecnica', 15, 2)->default(0);
            $table->string('estado')->default('Cotización');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('proyectos');
    }
};
