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
        Schema::create('avances_proyecto', function (Blueprint $table) {
            $table->id();
            $table->foreignId('subpartida_id')->constrained('subpartidas')->onDelete('cascade');
            $table->date('fecha');
            $table->decimal('porcentaje', 5, 2);
            $table->decimal('valor_ejecutado', 15, 2);
            $table->string('evidencias_url')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('avances_proyecto');
    }
};
