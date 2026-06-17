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
            // ProyectoSeeder::class,
            CategoriaMaterialSeeder::class,
            ProveedorSeeder::class, 
            AssetCategorySeeder::class,
        ]);

        // Crear usuario admin por defecto si no existe
        \App\Models\User::firstOrCreate(
            ['username' => 'ludeveloper'],
            [
                'name' => 'Lwader Soft S.R.L',
                'email' => 'lwadersoft@gmail.com',
                'password' => \Illuminate\Support\Facades\Hash::make('199512'),
            ]
        );

        // Asegurar que existe el Inventario Local General (Almacén Central)
        \App\Models\InventarioLocal::firstOrCreate(
            ['name_inventario' => 'ALMACÉN GENERAL'],
            [
                'location' => 'OFICINA CENTRAL / ALMACÉN',
            ]
        );
    }
}
