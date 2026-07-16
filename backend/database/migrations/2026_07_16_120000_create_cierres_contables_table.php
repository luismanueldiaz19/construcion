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
        Schema::create('cierres_contables', function (Blueprint $table) {
            $table->id();
            $table->integer('anio');
            $table->integer('mes');
            $table->enum('estado', ['abierto', 'cerrado'])->default('abierto');
            $table->foreignId('cerrado_por')->nullable()->constrained('users')->onDelete('set null');
            $table->timestamp('cerrado_el')->nullable();
            
            // Índices para búsquedas rápidas
            $table->unique(['anio', 'mes']);
            
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('cierres_contables');
    }
};
