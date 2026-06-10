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
        Schema::create('proveedores', function (Blueprint $table) {
            $table->id();
            $table->string('code')->unique();
            $table->enum('type', ['empresa', 'persona_fisica', 'subcontratista']);
            $table->string('name');
            $table->string('commercial_name')->nullable();
            $table->string('rnc')->nullable();
            $table->string('contact_name')->nullable();
            $table->string('contact_position')->nullable();
            $table->string('phone')->nullable();
            $table->string('mobile')->nullable();
            $table->string('whatsapp')->nullable();
            $table->string('email')->nullable();
            $table->string('country')->nullable();
            $table->string('province')->nullable();
            $table->string('city')->nullable();
            $table->string('sector')->nullable();
            $table->text('address')->nullable();
            $table->boolean('allow_credit')->default(true);
            $table->integer('credit_days')->default(30);
            $table->decimal('credit_limit',15,2)->default(0);
            $table->string('bank_name')->nullable();
            $table->string('account_number')->nullable();
            $table->string('account_type')->nullable();
            $table->enum('classification',['excelente', 'bueno', 'regular', 'riesgoso'])->default('bueno');
            $table->boolean('active')->default(true);
            $table->text('notes')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('compras', function (Blueprint $table) {
            $table->id();
            $table->foreignId('proveedor_id')->constrained('proveedores');
            $table->foreignId('proyecto_id')->constrained('proyectos');
            $table->date('fecha');
            $table->date('fecha_vencimiento')->nullable();
            $table->enum('tipo_compra', ['Contado', 'Crédito']);
            $table->decimal('subtotal', 15, 2);
            $table->decimal('itbis', 15, 2);
            $table->decimal('total', 15, 2);
            $table->enum('estado', ['Pendiente', 'Recibido', 'Pagado', 'Parcial'])->default('Pendiente');
            $table->timestamps();
        });

        Schema::create('compra_detalles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('compra_id')->constrained('compras')->onDelete('cascade');
            $table->foreignId('material_id')->constrained('materiales');
            $table->decimal('cantidad', 15, 2);
            $table->decimal('precio_unitario', 15, 2);
            $table->decimal('subtotal', 15, 2);
            $table->timestamps();
        });

        Schema::create('inventarios', function (Blueprint $table) {
            $table->id();
            $table->foreignId('proyecto_id')->constrained('proyectos');
            $table->foreignId('material_id')->constrained('materiales');
            $table->decimal('stock', 15, 2)->default(0);
            $table->timestamps();
            $table->unique(['proyecto_id', 'material_id']);
        });

        Schema::create('recepciones', function (Blueprint $table) {
            $table->id();
            $table->foreignId('compra_id')->constrained('compras');
            $table->date('fecha');
            $table->string('recibido_por')->nullable();
            $table->text('observaciones')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('recepciones');
        Schema::dropIfExists('inventarios');
        Schema::dropIfExists('compra_detalles');
        Schema::dropIfExists('compras');
        Schema::dropIfExists('proveedores');
    }
};
