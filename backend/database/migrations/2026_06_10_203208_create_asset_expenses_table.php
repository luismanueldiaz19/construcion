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
        Schema::create('asset_expenses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('asset_id')->constrained('assets')->onDelete('cascade');
            $table->foreignId('proyecto_id')->nullable()->constrained('proyectos')->onDelete('set null');
            $table->string('expense_type'); // Combustible, Mantenimiento, Reparacion, Repuesto
            $table->decimal('amount', 15, 2);
            $table->date('date');
            $table->string('description')->nullable();
            $table->integer('mileage')->nullable(); // Kilometraje para vehiculos
            $table->decimal('gallons', 8, 2)->nullable(); // Galones/Litros para combustible
            $table->foreignId('proveedor_id')->nullable()->constrained('proveedores')->onDelete('set null');
            $table->string('payment_method')->nullable();
            $table->foreignId('banco_id')->nullable()->constrained('catalogo_cuentas')->onDelete('set null');
            $table->foreignId('asiento_contable_id')->nullable()->constrained('asientos_contables')->onDelete('set null');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('asset_expenses');
    }
};
