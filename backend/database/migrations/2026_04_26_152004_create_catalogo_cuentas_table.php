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
        Schema::create('catalogo_cuentas', function (Blueprint $table) {
            $table->id();
            $table->string('codigo')->unique();
            $table->string('nombre');
            $table->enum('tipo', ['Activo', 'Pasivo', 'Capital', 'Ingreso', 'Costo', 'Gasto']);
            $table->integer('nivel')->default(1);
            $table->foreignId('padre_id')->nullable()->constrained('catalogo_cuentas')->onDelete('cascade');
            $table->boolean('es_detalle')->default(false);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('catalogo_cuentas');
    }
};
