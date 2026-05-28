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
        Schema::table('proyectos', function (Blueprint $table) {
            $table->boolean('es_almacen')->default(false)->after('estado');
        });

        Schema::create('transferencias', function (Blueprint $table) {
            $table->id();
            $table->foreignId('material_id')->constrained('materiales');
            $table->foreignId('proyecto_origen_id')->constrained('proyectos');
            $table->foreignId('proyecto_destino_id')->constrained('proyectos');
            $table->decimal('cantidad', 15, 2);
            $table->date('fecha');
            $table->text('observaciones')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('transferencias');
        Schema::table('proyectos', function (Blueprint $table) {
            $table->dropColumn('es_almacen');
        });
    }
};
