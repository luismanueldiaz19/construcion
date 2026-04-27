<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class MaterialSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $materiales = [
            ['nombre' => 'Cemento Gris', 'unidad' => 'Funda'],
            ['nombre' => 'Arena Itabo', 'unidad' => 'M3'],
            ['nombre' => 'Grava 3/4', 'unidad' => 'M3'],
            ['nombre' => 'Varilla 3/8', 'unidad' => 'Quintal'],
            ['nombre' => 'Block 6"', 'unidad' => 'Unidad'],
        ];

        foreach ($materiales as $m) {
            \App\Models\Material::create($m);
        }
    }
}
