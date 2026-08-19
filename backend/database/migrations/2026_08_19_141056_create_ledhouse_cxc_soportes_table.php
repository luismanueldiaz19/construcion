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
        Schema::create('ledhouse_cxc_soportes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ledhouse_cxc_id')->constrained('ledhouse_cxcs')->onDelete('cascade');
            $table->text('nota');
            $table->date('fecha');
            $table->date('fecha_visita')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('ledhouse_cxc_soportes');
    }
};
