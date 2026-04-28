<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
   public function up(): void {
    Schema::table('materiales', function (Blueprint $table) {
        $table->string('codigo')->unique()->nullable();
        $table->text('descripcion')->nullable();
        // Mejor relación
        $table->foreignId('categoria_id')->nullable()->constrained()->nullOnDelete();
        $table->decimal('precio_costo', 10, 2)->default(0);

        // Más flexible
        $table->boolean('estado')->default(true);
    });
}

public function down(): void {
    Schema::table('materiales', function (Blueprint $table) {
        $table->dropUnique(['codigo']);
        $table->dropColumn([
            'codigo',
            'descripcion',
            'categoria_id',
            'precio_costo',
            'estado',
        ]);
    });
}
};
