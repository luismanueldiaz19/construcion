<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\AssetCategory;

class AssetCategorySeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $categories = [
            ['name' => 'Vehículos', 'description' => 'Camionetas, camiones, autos asignados a proyectos o empleados.'],
            ['name' => 'Computadoras', 'description' => 'Equipos de escritorio (Desktop).'],
            ['name' => 'Laptops', 'description' => 'Equipos portátiles asignados a empleados.'],
            ['name' => 'Mesas de Oficina', 'description' => 'Mobiliario de oficina, escritorios, sillas.'],
            ['name' => 'Equipos Pesados', 'description' => 'Maquinaria de construcción de larga duración.'],
            ['name' => 'Herramientas Menores', 'description' => 'Taladros, sierras, equipos que no son maquinaria pesada pero duran mucho.'],
        ];

        foreach ($categories as $category) {
            AssetCategory::firstOrCreate(['name' => $category['name']], $category);
        }
    }
}
