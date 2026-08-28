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
        Schema::create('ledhouse_estado_resultado', function (Blueprint $table) {
            $table->id();
            $table->string('codigo_cuenta');
            
            // Relación con el catálogo
            $table->foreign('codigo_cuenta')
                  ->references('codigo')
                  ->on('cuenta_catalogo_ledhouse')
                  ->onDelete('cascade');

            $table->decimal('monto', 15, 2);
            $table->date('fecha');
            $table->string('registed_by')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('ledhouse_estado_resultado');
    }
};
