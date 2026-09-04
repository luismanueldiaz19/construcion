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
            $table->date('fecha_factura')->nullable()->after('monto_pendiente');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('ledhouse_cxcs', function (Blueprint $table) {
            $table->dropColumn('fecha_factura');
        });
    }
};
