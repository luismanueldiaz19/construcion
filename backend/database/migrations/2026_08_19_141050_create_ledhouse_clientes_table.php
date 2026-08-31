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
        Schema::create('ledhouse_clientes', function (Blueprint $table) {
            $table->id();
            $table->string('nombre');
            $table->string('whatsapp');
            $table->string('direccion')->nullable();
            $table->decimal('limite_credito', 10, 2)->nullable()->default(0);
            $table->integer('dias_credito')->nullable()->default(0);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('ledhouse_clientes');
    }
};
