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
        Schema::table('ledhouse_estado_resultado', function (Blueprint $table) {
            $table->dropColumn(['modulo', 'descripcion_de_cuenta']);
            $table->foreign('codigo_cuenta')
                  ->references('codigo')
                  ->on('cuenta_catalogo_ledhouse')
                  ->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('ledhouse_estado_resultado', function (Blueprint $table) {
            $table->dropForeign(['codigo_cuenta']);
            $table->string('modulo');
            $table->string('descripcion_de_cuenta');
        });
    }
};
