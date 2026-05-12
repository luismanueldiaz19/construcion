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
            ['nombre' => 'Logística', 'descripcion' => 'Fletes y transporte de materiales.'],
        ];

        $catModels = [];
        foreach ($categorias as $cat) {
            $catModels[$cat['nombre']] = Categoria::firstOrCreate(
                ['nombre' => $cat['nombre']],
                ['descripcion' => $cat['descripcion']]
            );
        }

        // 2. Crear Catálogo de Materiales de Referencia
        $materiales = [
            // // OBRA GRIS
            // [
            //     'codigo' => 'OG-001',
            //     'nombre' => 'Cemento Portland Gris',
            //     'descripcion' => 'Funda de 42.5kg de alta resistencia',
            //     'cat' => 'Gris',
            //     'unidad' => 'FUNDA',
            //     'precio' => 525.00
            // ],
            // [
            //     'codigo' => 'OG-002',
            //     'nombre' => 'Varilla 3/8"',
            //     'descripcion' => 'Varilla de acero corrugada grado 60',
            //     'cat' => 'Gris',
            //     'unidad' => 'QUINTAL',
            //     'precio' => 4850.00
            // ],
            // [
            //     'codigo' => 'OG-003',
            //     'nombre' => 'Block de 6"',
            //     'descripcion' => 'Block de hormigón vibrado estándar',
            //     'cat' => 'Gris',
            //     'unidad' => 'UNIDAD',
            //     'precio' => 45.00
            // ],
            // [
            //     'codigo' => 'OG-004',
            //     'nombre' => 'Arena ITBIS Incluida',
            //     'descripcion' => 'Arena lavada de río para pañete',
            //     'cat' => 'Gris',
            //     'unidad' => 'M3',
            //     'precio' => 1200.00
            // ],

            // // TERMINACIONES
            // [
            //     'codigo' => 'TR-001',
            //     'nombre' => 'Porcelanato Español 60x60',
            //     'descripcion' => 'Color crema pulido de alto tráfico',
            //     'cat' => 'Terminaciones',
            //     'unidad' => 'M2',
            //     'precio' => 1150.00
            // ],
            // [
            //     'codigo' => 'TR-002',
            //     'nombre' => 'Pegante Cerámica Premium',
            //     'descripcion' => 'Saco de 20kg para porcelanato',
            //     'cat' => 'Terminaciones',
            //     'unidad' => 'SACO',
            //     'precio' => 480.00
            // ],

            // // ELECTRICIDAD
            // [
            //     'codigo' => 'EL-001',
            //     'nombre' => 'Cable THHN #12 Negro',
            //     'decoration' => 'Rollo de 500 pies',
            //     'cat' => 'Electricidad',
            //     'unidad' => 'ROLLO',
            //     'precio' => 6500.00
            // ],
            // [
            //     'codigo' => 'EL-002',
            //     'nombre' => 'Panel de Breakers 12 Espacios',
            //     'descripcion' => 'Caja de distribución principal',
            //     'cat' => 'Electricidad',
            //     'unidad' => 'UNIDAD',
            //     'precio' => 2800.00
            // ],

            // // PLOMERIA
            // [
            //     'codigo' => 'PL-001',
            //     'nombre' => 'Inodoro Blanco Confort',
            //     'descripcion' => 'Inodoro de una pieza de alta eficiencia',
            //     'cat' => 'Plomería',
            //     'unidad' => 'UNIDAD',
            //     'precio' => 8500.00
            // ],
            // [
            //     'codigo' => 'PL-002',
            //     'nombre' => 'Tubería PVC 1/2" SDR-21',
            //     'descripcion' => 'Tubo de 20 pies para agua potable',
            //     'cat' => 'Plomería',
            //     'unidad' => 'TUBO',
            //     'precio' => 320.00
            // ],

            // // PINTURA
            // [
            //     'codigo' => 'PN-001',
            //     'nombre' => 'Pintura Acrílica Superior Blanca',
            //     'descripcion' => 'Cubeta de 5 galones premium',
            //     'cat' => 'Pintura',
            //     'unidad' => 'CUBETA',
            //     'precio' => 4200.00
            // ],
            // NUEVOS PRODUCTOS AGREGADOS
            [
                'codigo' => 'OG-005',
                'nombre' => 'VARILLA CONST. 1/2×20 QQ.7',
                'descripcion' => 'Varilla de construcción 1/2 x 20 quintales',
                'cat' => 'Gris',
                'unidad' => 'QUINTAL',
                'precio' => 3046.01
            ],
            [
                'codigo' => 'OG-006',
                'nombre' => 'VARILLA CONST. 3/8×20 QQ.13',
                'descripcion' => 'Varilla de construcción 3/8 x 20 quintales',
                'cat' => 'Gris',
                'unidad' => 'QUINTAL',
                'precio' => 3046.01
            ],
            [
                'codigo' => 'OG-007',
                'nombre' => 'ARENA GRUESA LAVADA MT3',
                'descripcion' => 'Arena gruesa lavada por metro cúbico',
                'cat' => 'Gris',
                'unidad' => 'M3',
                'precio' => 2005.00
            ],
            [
                'codigo' => 'OG-008',
                'nombre' => 'CEMENTO GRIS DOMICEM NORMAL FDA',
                'descripcion' => 'Cemento gris Domicem normal por funda',
                'cat' => 'Gris',
                'unidad' => 'FUNDA',
                'precio' => 505.00
            ],
            [
                'codigo' => 'OG-009',
                'nombre' => 'GRAVA 1/2–3/4" LAVADA MT3',
                'descripcion' => 'Grava lavada 1/2-3/4 por metro cúbico',
                'cat' => 'Gris',
                'unidad' => 'M3',
                'precio' => 1525.00
            ],
            [
                'codigo' => 'OG-010',
                'nombre' => 'BLOCK EDGAR 6" 2 HOYOS',
                'descripcion' => 'Block Edgar de 6 pulgadas y 2 hoyos',
                'cat' => 'Gris',
                'unidad' => 'UNIDAD',
                'precio' => 42.90
            ],
            [
                'codigo' => 'OG-011',
                'nombre' => 'ALAMBRE GALVANIZ CORTAD/PICAD #16 LB',
                'descripcion' => 'Alambre galvanizado cortado/picado #16 por libra',
                'cat' => 'Gris',
                'unidad' => 'LIBRA',
                'precio' => 54.00
            ],
            [
                'codigo' => 'OG-012',
                'nombre' => 'CLAVO 2" X 11 CORRIENTE LIBRA',
                'descripcion' => 'Clavo 2 x 11 corriente por libra',
                'cat' => 'Gris',
                'unidad' => 'LIBRA',
                'precio' => 52.00
            ],
            [
                'codigo' => 'OG-013',
                'nombre' => 'CLAVO ACERO ESTRIADO 2" LIBRA',
                'descripcion' => 'Clavo de acero estriado 2 pulgadas por libra',
                'cat' => 'Gris',
                'unidad' => 'LIBRA',
                'precio' => 62.00
            ],
            [
                'codigo' => 'OG-014',
                'nombre' => 'NYLON TEJER BLANCO #9',
                'descripcion' => 'Nylon para tejer blanco #9',
                'cat' => 'Gris',
                'unidad' => 'UNIDAD',
                'precio' => 156.00
            ],
            [
                'codigo' => 'LG-001',
                'nombre' => 'FLETE DAIHATSU/ISUZU PTO PTA CIUDAD',
                'descripcion' => 'Flete en camión Daihatsu/Isuzu puerta a puerta ciudad',
                'cat' => 'Logística',
                'unidad' => 'VIAJE',
                'precio' => 475.00
            ],
            [
                'codigo' => 'LG-002',
                'nombre' => 'FLETE TOYOTA/NISSAN PTO PTA CIUDAD',
                'descripcion' => 'Flete en camioneta Toyota/Nissan puerta a puerta ciudad',
                'cat' => 'Logística',
                'unidad' => 'VIAJE',
                'precio' => 925.00
            ],
            [
                'codigo' => 'LG-003',
                'nombre' => 'FLETE MACK AMARILLO PTO PTA CIUDAD',
                'descripcion' => 'Flete en camión Mack amarillo puerta a puerta ciudad',
                'cat' => 'Logística',
                'unidad' => 'VIAJE',
                'precio' => 1800.00
            ],
            [
                'codigo' => 'PL-003',
                'nombre' => 'COUPLING PVC 3/4" PRESION SCH-40',
                'descripcion' => 'Coupling PVC 3/4 pulgadas presión SCH-40',
                'cat' => 'Plomería',
                'unidad' => 'UNIDAD',
                'precio' => 5.22
            ],
            [
                'codigo' => 'PL-004',
                'nombre' => 'TUBO PVC PRESION 3/4" X 19\' SCH-40',
                'descripcion' => 'Tubo PVC presión 3/4 pulgadas x 19 pies SCH-40',
                'cat' => 'Plomería',
                'unidad' => 'TUBO',
                'precio' => 240.00
            ],
            [
                'codigo' => 'PL-005',
                'nombre' => 'CODO PVC 3/4"X 90 USA PRESION SCH-40',
                'descripcion' => 'Codo PVC 3/4 x 90 grados USA presión SCH-40',
                'cat' => 'Plomería',
                'unidad' => 'UNIDAD',
                'precio' => 7.50
            ],
            [
                'codigo' => 'PL-006',
                'nombre' => 'LLAVE BOLA PVC M/AZU FOSE/EZ FLO 3/4"',
                'descripcion' => 'Llave de bola PVC mango azul 3/4 pulgadas',
                'cat' => 'Plomería',
                'unidad' => 'UNIDAD',
                'precio' => 86.00
            ],
            [
                'codigo' => 'PL-007',
                'nombre' => 'CEMENT PVC SM-248-8 LANCO WET-DRY 4 OZ',
                'descripcion' => 'Pegamento PVC Lanco Wet-Dry 4 onzas',
                'cat' => 'Plomería',
                'unidad' => 'UNIDAD',
                'precio' => 255.00
            ],
            [
                'codigo' => 'PL-008',
                'nombre' => 'CODO PVC 4" X 45 GRADOS DRENAJE',
                'descripcion' => 'Codo PVC 4 pulgadas x 45 grados drenaje',
                'cat' => 'Plomería',
                'unidad' => 'UNIDAD',
                'precio' => 78.73
            ],
            [
                'codigo' => 'TR-003',
                'nombre' => 'PEGAMENTO CERAMI PEGAFORTE GRIS 50LB',
                'descripcion' => 'Pegamento cerámico Pegaforte gris 50 libras',
                'cat' => 'Terminaciones',
                'unidad' => 'SACO',
                'precio' => 315.00
            ],
            [
                'codigo' => 'MC-001',
                'nombre' => 'MADERA 1×4×12 USA BRUTA',
                'descripcion' => 'Madera 1x4x12 USA bruta',
                'cat' => 'Maderas y Carpintería',
                'unidad' => 'UNIDAD',
                'precio' => 75.88
            ],
        ];

        foreach ($materiales as $mat) {
            Material::updateOrCreate(
                ['codigo' => $mat['codigo']],
                [
                    'nombre' => $mat['nombre'],
                    'descripcion' => $mat['descripcion'] ?? $mat['nombre'],
                    'categoria_id' => $catModels[$mat['cat']]->id,
                    'unidad' => $mat['unidad'],
                    'precio_costo' => $mat['precio'],
                    'estado' => true,
                ]
            );
        }
    }
}
