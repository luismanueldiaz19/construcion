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
        Schema::create('ledhouse_cxcs', function (Blueprint $table) {
            $table->id();
            $table->string('documento');
            $table->string('cliente');
            $table->decimal('monto_factura', 15, 2)->nullable();
            $table->decimal('monto_pagado', 15, 2)->default(0);
            $table->decimal('monto_pendiente', 15, 2);
            $table->date('fecha_vencimiento');
            $table->string('estado')->default('pendiente'); // pendiente, pagado, cancelado
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('ledhouse_cxcs');
    }
};
