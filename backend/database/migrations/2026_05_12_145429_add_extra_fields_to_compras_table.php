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
        Schema::table('compras', function (Blueprint $table) {
            $table->string('orden')->nullable()->after('proyecto_id');
            $table->string('codigo')->nullable()->after('orden');
            $table->string('comprobante')->nullable()->unique()->after('codigo');
            $table->text('nota')->nullable()->after('total');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('compras', function (Blueprint $table) {
            $table->dropColumn(['orden', 'codigo', 'comprobante', 'nota']);
        });
    }
};
