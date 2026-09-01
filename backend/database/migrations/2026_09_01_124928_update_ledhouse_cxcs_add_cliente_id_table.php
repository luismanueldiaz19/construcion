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
        Schema::table('ledhouse_cxcs', function (Blueprint $table) {
            $table->foreignId('cliente_id')->nullable()->constrained('ledhouse_clientes')->onDelete('cascade');
            // Si existía la columna anterior con el nombre, la eliminamos
            if (Schema::hasColumn('ledhouse_cxcs', 'cliente')) {
                $table->dropColumn('cliente');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('ledhouse_cxcs', function (Blueprint $table) {
            $table->dropForeign(['cliente_id']);
            $table->dropColumn('cliente_id');
            $table->string('cliente')->nullable();
        });
    }
};
