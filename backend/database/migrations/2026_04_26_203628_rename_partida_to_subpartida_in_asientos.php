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
        Schema::table('asiento_detalles', function (Blueprint $table) {
            $table->dropForeign(['partida_id']);
            $table->dropColumn('partida_id');
            $table->foreignId('subpartida_id')->nullable()->constrained('subpartidas');
        });

        Schema::table('consumos', function (Blueprint $table) {
            $table->dropForeign(['partida_id']);
            $table->renameColumn('partida_id', 'subpartida_id');
            $table->foreign('subpartida_id')->references('id')->on('subpartidas');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('asiento_detalles', function (Blueprint $table) {
            $table->dropColumn('subpartida_id');
        });
    }
};
