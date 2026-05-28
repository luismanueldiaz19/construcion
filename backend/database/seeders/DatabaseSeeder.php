<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call([
            CatalogoCuentasSeeder::class,
            ProyectoSeeder::class,
            CategoriaMaterialSeeder::class,
            ProveedorSeeder::class, 
        ]);

        // Asegurar que existe el Almacén General
        \App\Models\Proyecto::firstOrCreate(
            ['es_almacen' => true],
            [
                'nombre' => 'ALMACÉN GENERAL',
                'cliente' => 'NEO PROJECT S.R.L',
                'ubicacion' => 'OFICINA CENTRAL / ALMACÉN',
                'fecha_inicio' => now()->toDateString(),
                'presupuesto_estimado' => 0.00,
                'estado' => 'Activo',
            ]
        );
    }
}
