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
        Schema::table('gastos_proyecto', function (Blueprint $table) {
            $table->foreignId('cuenta_costo_id')->nullable()->after('proveedor_id')->constrained('catalogo_cuentas');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('gastos_proyecto', function (Blueprint $table) {
            $table->dropForeign(['cuenta_costo_id']);
            $table->dropColumn('cuenta_costo_id');
        });
    }
};
