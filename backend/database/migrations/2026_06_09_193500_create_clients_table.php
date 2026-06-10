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
        Schema::create('clients', function (Blueprint $table) {
            $table->id();

            // Identificación
            $table->string('code')->unique();
            $table->enum('type', [
                'persona_fisica',
                'empresa',
                'gobierno',
                'institucion'
            ]);

            // Datos principales
            $table->string('name');
            $table->string('commercial_name')->nullable();
            $table->string('document_number')->nullable(); // Cédula o RNC

            // Contacto principal
            $table->string('contact_name')->nullable();
            $table->string('contact_position')->nullable();
            $table->string('phone')->nullable();
            $table->string('mobile')->nullable();
            $table->string('whatsapp')->nullable();
            $table->string('email')->nullable();

            // Dirección
            $table->string('country')->nullable();
            $table->string('province')->nullable();
            $table->string('city')->nullable();
            $table->string('sector')->nullable();
            $table->text('address')->nullable();

            // Información comercial
            $table->decimal('credit_limit', 15, 2)->default(0);
            $table->integer('credit_days')->default(0);

            // Clasificación
            $table->enum('classification', [
                'excelente',
                'bueno',
                'regular',
                'riesgoso'
            ])->default('bueno');

            // Estado
            $table->boolean('active')->default(true);

            // Observaciones
            $table->text('notes')->nullable();

            $table->timestamps();
            $table->softDeletes();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('clients');
    }
};
