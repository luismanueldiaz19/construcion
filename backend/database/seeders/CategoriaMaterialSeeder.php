<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Categoria;
use App\Models\Material;

class CategoriaMaterialSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Crear Categorías
        $catObraGris = Categoria::create([
            'nombre' => 'Obra Gris',
            'descripcion' => 'Materiales base para construcción estructural',
        ]);

        $catTerminaciones = Categoria::create([
            'nombre' => 'Terminaciones',
            'descripcion' => 'Pinturas, cerámicas y acabados',
        ]);

        $catElectrico = Categoria::create([
            'nombre' => 'Electricidad',
            'descripcion' => 'Cables, tuberías y accesorios eléctricos',
        ]);

        // 2. Crear Productos (Materiales) de ejemplo
        Material::create([
            'codigo' => 'MAT-001',
            'nombre' => 'Cemento Portland Gris',
            'descripcion' => 'Funda de cemento de alta resistencia 42.5kg',
            'categoria_id' => $catObraGris->id,
            'unidad' => 'FUNDA',
            'precio_costo' => 550.00,
            'estado' => true,
        ]);

        Material::create([
            'codigo' => 'MAT-002',
            'nombre' => 'Varilla Corrugada 3/8',
            'descripcion' => 'Varilla de acero para refuerzo de concreto',
            'categoria_id' => $catObraGris->id,
            'unidad' => 'QUINTAL',
            'precio_costo' => 3200.00,
            'estado' => true,
        ]);

        Material::create([
            'codigo' => 'MAT-003',
            'nombre' => 'Pintura Acrílica Blanca',
            'descripcion' => 'Cubeta de pintura premium para interiores',
            'categoria_id' => $catTerminaciones->id,
            'unidad' => 'CUBETA',
            'precio_costo' => 4500.00,
            'estado' => true,
        ]);

        Material::create([
            'codigo' => 'MAT-004',
            'nombre' => 'Cable THHN #12',
            'descripcion' => 'Rollo de cable eléctrico 100 metros',
            'categoria_id' => $catElectrico->id,
            'unidad' => 'ROLLO',
            'precio_costo' => 2800.00,
            'estado' => true,
        ]);
    }
}
