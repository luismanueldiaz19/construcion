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
        Schema::create('conciliaciones_bancarias', function (Blueprint $table) {
            $table->id();
            $table->foreignId('banco_id')->constrained('catalogo_cuentas'); // Solo cuentas tipo Banco
            $table->integer('anio');
            $table->integer('mes');
            $table->decimal('saldo_banco', 15, 2)->default(0);
            $table->decimal('saldo_sistema', 15, 2)->default(0);
            $table->decimal('diferencia', 15, 2)->default(0);
            $table->enum('estado', ['borrador', 'conciliado'])->default('borrador');
            $table->foreignId('conciliado_por')->nullable()->constrained('users')->onDelete('set null');
            
            $table->unique(['banco_id', 'anio', 'mes'], 'conciliacion_banco_periodo_unique');
            $table->timestamps();
        });

        Schema::create('conciliacion_detalles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('conciliacion_id')->constrained('conciliaciones_bancarias')->onDelete('cascade');
            $table->foreignId('asiento_detalle_id')->constrained('asiento_detalles');
            $table->enum('estado', ['pendiente', 'conciliado'])->default('conciliado');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('conciliacion_detalles');
        Schema::dropIfExists('conciliaciones_bancarias');
    }
};
