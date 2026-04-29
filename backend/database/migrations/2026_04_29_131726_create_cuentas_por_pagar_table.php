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
        Schema::create('cuentas_por_pagar', function (Blueprint $table) {
            $table->id();
            $table->foreignId('compra_id')->constrained('compras')->onDelete('cascade');
            $table->foreignId('proveedor_id')->constrained('proveedores');
            $table->decimal('monto_total', 15, 2);
            $table->decimal('monto_pagado', 15, 2)->default(0);
            $table->decimal('saldo', 15, 2);
            $table->date('fecha_vencimiento')->nullable();
            $table->enum('estado', ['Pendiente', 'Parcial', 'Pagado'])->default('Pendiente');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('cuentas_por_pagar');
    }
};
