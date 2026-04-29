<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Categoria;
use App\Models\Material;

class CategoriaMaterialSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // 1. Crear Categorías Principales
        $categorias = [
            ['nombre' => 'Gris', 'descripcion' => 'Materiales base: Cemento, arena, varilla, blocks.'],
            ['nombre' => 'Terminaciones', 'descripcion' => 'Pisos, revestimientos, cerámicas y mármol.'],
            ['nombre' => 'Electricidad', 'descripcion' => 'Cables, paneles, tubería PVC eléctrica y breakers.'],
            ['nombre' => 'Plomería', 'descripcion' => 'Tuberías de agua, drenajes, piezas sanitarias.'],
            ['nombre' => 'Maderas y Carpintería', 'descripcion' => 'Plywood, pino, caoba y herrajes.'],
            ['nombre' => 'Pintura', 'descripcion' => 'Cubetas de pintura, selladores y brochas.'],
            ['nombre' => 'Climatización', 'descripcion' => 'Aires acondicionados y ductería.'],
            ['nombre' => 'Seguridad y Tecnología', 'descripcion' => 'Cámaras, alarmas y cableado de red.'],
            ['nombre' => 'Jardinería y Exteriores', 'descripcion' => 'Tierra, grama y decoración exterior.'],
        ];

        $catModels = [];
        foreach ($categorias as $cat) {
            $catModels[$cat['nombre']] = Categoria::create($cat);
        }

        // 2. Crear Catálogo de Materiales de Referencia
        $materiales = [
            // OBRA GRIS
            [
                'codigo' => 'OG-001',
                'nombre' => 'Cemento Portland Gris',
                'descripcion' => 'Funda de 42.5kg de alta resistencia',
                'cat' => 'Gris',
                'unidad' => 'FUNDA',
                'precio' => 525.00
            ],
            [
                'codigo' => 'OG-002',
                'nombre' => 'Varilla 3/8"',
                'descripcion' => 'Varilla de acero corrugada grado 60',
                'cat' => 'Gris',
                'unidad' => 'QUINTAL',
                'precio' => 4850.00
            ],
            [
                'codigo' => 'OG-003',
                'nombre' => 'Block de 6"',
                'descripcion' => 'Block de hormigón vibrado estándar',
                'cat' => 'Gris',
                'unidad' => 'UNIDAD',
                'precio' => 45.00
            ],
            [
                'codigo' => 'OG-004',
                'nombre' => 'Arena ITBIS Incluida',
                'descripcion' => 'Arena lavada de río para pañete',
                'cat' => 'Gris',
                'unidad' => 'M3',
                'precio' => 1200.00
            ],

            // TERMINACIONES
            [
                'codigo' => 'TR-001',
                'nombre' => 'Porcelanato Español 60x60',
                'descripcion' => 'Color crema pulido de alto tráfico',
                'cat' => 'Terminaciones',
                'unidad' => 'M2',
                'precio' => 1150.00
            ],
            [
                'codigo' => 'TR-002',
                'nombre' => 'Pegante Cerámica Premium',
                'descripcion' => 'Saco de 20kg para porcelanato',
                'cat' => 'Terminaciones',
                'unidad' => 'SACO',
                'precio' => 480.00
            ],

            // ELECTRICIDAD
            [
                'codigo' => 'EL-001',
                'nombre' => 'Cable THHN #12 Negro',
                'decoration' => 'Rollo de 500 pies',
                'cat' => 'Electricidad',
                'unidad' => 'ROLLO',
                'precio' => 6500.00
            ],
            [
                'codigo' => 'EL-002',
                'nombre' => 'Panel de Breakers 12 Espacios',
                'descripcion' => 'Caja de distribución principal',
                'cat' => 'Electricidad',
                'unidad' => 'UNIDAD',
                'precio' => 2800.00
            ],

            // PLOMERIA
            [
                'codigo' => 'PL-001',
                'nombre' => 'Inodoro Blanco Confort',
                'descripcion' => 'Inodoro de una pieza de alta eficiencia',
                'cat' => 'Plomería',
                'unidad' => 'UNIDAD',
                'precio' => 8500.00
            ],
            [
                'codigo' => 'PL-002',
                'nombre' => 'Tubería PVC 1/2" SDR-21',
                'descripcion' => 'Tubo de 20 pies para agua potable',
                'cat' => 'Plomería',
                'unidad' => 'TUBO',
                'precio' => 320.00
            ],

            // PINTURA
            [
                'codigo' => 'PN-001',
                'nombre' => 'Pintura Acrílica Superior Blanca',
                'descripcion' => 'Cubeta de 5 galones premium',
                'cat' => 'Pintura',
                'unidad' => 'CUBETA',
                'precio' => 4200.00
            ],
        ];

        foreach ($materiales as $mat) {
            Material::create([
                'codigo' => $mat['codigo'],
                'nombre' => $mat['nombre'],
                'descripcion' => $mat['descripcion'] ?? $mat['nombre'],
                'categoria_id' => $catModels[$mat['cat']]->id,
                'unidad' => $mat['unidad'],
                'precio_costo' => $mat['precio'],
                'estado' => true,
            ]);
        }
    }
}
