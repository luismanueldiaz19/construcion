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
        Schema::create('gastos_proyecto', function (Blueprint $table) {
            $table->id();
            $table->foreignId('proyecto_id')->constrained('proyectos')->onDelete('cascade');
            $table->foreignId('subpartida_id')->nullable()->constrained('subpartidas')->onDelete('set null');
            $table->foreignId('proveedor_id')->nullable()->constrained('proveedores')->onDelete('set null');
            $table->decimal('monto', 15, 2);
            $table->string('tipo_gasto'); // Mano de Obra, Alquiler, Transporte, Otros
            $table->string('descripcion')->nullable();
            $table->date('fecha');
            $table->string('metodo_pago'); // Efectivo, Transferencia, Cheque, Crédito
            $table->string('estado')->default('Pagado'); // Pagado, Pendiente
            $table->foreignId('banco_id')->nullable()->constrained('catalogo_cuentas'); // Cuenta de donde sale el dinero
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('gastos_proyecto');
    }
};
