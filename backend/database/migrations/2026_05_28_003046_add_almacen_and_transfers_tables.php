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
        Schema::create('inventarios_locales', function (Blueprint $table) {
            $table->id();
            $table->string('name_inventario');
            $table->string('location');
            $table->timestamps();
        });

        Schema::create('inventarios_locales_stock', function (Blueprint $table) {
            $table->id();
            $table->foreignId('inventario_local_id')->constrained('inventarios_locales')->onDelete('cascade');
            $table->foreignId('material_id')->constrained('materiales')->onDelete('cascade');
            $table->decimal('stock', 15, 2)->default(0);
            $table->timestamps();
            $table->unique(['inventario_local_id', 'material_id']);
        });

        Schema::create('transferencias', function (Blueprint $table) {
            $table->id();
            $table->foreignId('material_id')->constrained('materiales')->onDelete('cascade');
            
            $table->foreignId('proyecto_origen_id')->nullable()->constrained('proyectos')->onDelete('cascade');
            $table->foreignId('proyecto_destino_id')->nullable()->constrained('proyectos')->onDelete('cascade');
            
            $table->foreignId('inventario_local_origen_id')->nullable()->constrained('inventarios_locales')->onDelete('cascade');
            $table->foreignId('inventario_local_destino_id')->nullable()->constrained('inventarios_locales')->onDelete('cascade');
            
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
        Schema::dropIfExists('inventarios_locales_stock');
        Schema::dropIfExists('inventarios_locales');
    }
};
