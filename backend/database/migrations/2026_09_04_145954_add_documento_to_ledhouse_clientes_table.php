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
        Schema::table('ledhouse_clientes', function (Blueprint $table) {
            $table->string('tipo_documento')->nullable()->after('whatsapp')->comment('Cédula o RNC');
            $table->string('documento')->nullable()->after('tipo_documento');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('ledhouse_clientes', function (Blueprint $table) {
            $table->dropColumn(['tipo_documento', 'documento']);
        });
    }
};
