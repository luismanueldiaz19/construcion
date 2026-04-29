<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Proyecto;
use App\Models\Partida;
use App\Models\Subpartida;

class ProyectoSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Crear el Proyecto Principal
        $proyecto = Proyecto::create([
            'nombre' => 'REMODELACION CASA',
            'cliente' => 'EMILIA ALBANIA MARIA RODRIGUEZ',
            'ubicacion' => 'VISTA BELLA, LOS MAESTROS, PUERTO PLATA',
            'fecha_inicio' => '2025-02-28',
            'presupuesto_estimado' => 7850076.21,
            'supervision_tecnica' => 677899.50,
            'itbis' => 122021.91,
            'transporte' => 271159.80,
            'otros_costos' => 0,
            'estado' => 'Cotización', // Lo creamos activo para pruebas
            // 'estado' => 'Activo', // Lo creamos activo para pruebas
        ]);

        // 2. Definir Estructura de Partidas y Subpartidas
        $data = [
            '1.00 PRELIMINARES' => [
                ['desc' => 'Demolición en general', 'und' => 'M2', 'cant' => 320, 'precio' => 500],
                ['desc' => 'Demolición piso interior 2 niveles', 'und' => 'M2', 'cant' => 171.29, 'precio' => 500],
                ['desc' => 'Bote general', 'und' => 'PA', 'cant' => 1, 'precio' => 40000],
            ],
            '2.00 PISO' => [
                ['desc' => 'Suministro y colocación de cerámica en piso interior', 'und' => 'M2', 'cant' => 280, 'precio' => 1750],
            ],
            '3.00 VENTANAS, PUERTAS CORREDIZAS Y PASAMANOS' => [
                ['desc' => 'Suministro y colocación de ventanas material P65 y puertas corredizas', 'und' => 'PA', 'cant' => 1, 'precio' => 301000],
                ['desc' => 'Suministro y colocación de puertas interiores, habitaciones y baños', 'und' => 'UND', 'cant' => 9, 'precio' => 33000],
                ['desc' => 'Suministro y colocación de puerta principal', 'und' => 'UND', 'cant' => 1, 'precio' => 42000],
                ['desc' => 'Suministro y colocación de pasamanos en escalera 1er y 2do nivel', 'und' => 'PL', 'cant' => 45, 'precio' => 2800],
            ],
            '4.00 TECHO' => [
                ['desc' => 'Acondicionamiento de todos los techos según nueva fachada', 'und' => 'PA', 'cant' => 1, 'precio' => 983000],
                ['desc' => 'Selladores', 'und' => 'M2', 'cant' => 140, 'precio' => 1100],
            ],
            '5.00 HABITACIÓN+ WIC + BAÑO' => [
                ['desc' => 'Construcción de espacios nuevos', 'und' => 'M2', 'cant' => 35, 'precio' => 54000],
            ],
            '6.00 COCINA' => [
                ['desc' => 'Remodelación de cocina y desayunador', 'und' => 'PA', 'cant' => 1, 'precio' => 720350],
            ],
            '8.00 PINTURA' => [
                ['desc' => 'Pañete y preparación de paredes según requerimiento', 'und' => 'PA', 'cant' => 1, 'precio' => 120000],
                ['desc' => 'Pintura general interior, exterior', 'und' => 'PA', 'cant' => 1, 'precio' => 245000],
            ],
            '9.00 MISCELÁNEO' => [
                ['desc' => 'Adecuaciones en general según nueva fachada', 'und' => 'PA', 'cant' => 1, 'precio' => 1100000],
                ['desc' => 'Limpieza general', 'und' => 'PA', 'cant' => 1, 'precio' => 25000],
            ],
        ];

        foreach ($data as $partidaNombre => $subpartidas) {
            $partida = Partida::create([
                'proyecto_id' => $proyecto->id,
                'descripcion' => $partidaNombre,
            ]);

            foreach ($subpartidas as $s) {
                Subpartida::create([
                    'partida_id' => $partida->id,
                    'descripcion' => $s['desc'],
                    'unidad' => $s['und'],
                    'cantidad' => $s['cant'],
                    'costo_unitario' => $s['precio'],
                    'total_presupuestado' => $s['cant'] * $s['precio'],
                ]);
            }
        }

        // 3. Crear Proyectos Pequeños de Prueba
        $p1 = Proyecto::create([
            'nombre' => 'Reparación de Verja',
            'cliente' => 'Juan Perez',
            'ubicacion' => 'Moca, RD',
            'fecha_inicio' => '2025-05-01',
            'presupuesto_estimado' => 59400,
            'itbis' => 8100, // 18%
            'transporte' => 1800, // 4%
            'supervision_tecnica' => 4500, // 10%
            'estado' => 'Activo',
        ]);
        $par1 = Partida::create(['proyecto_id' => $p1->id, 'descripcion' => 'Metalurgia']);
        Subpartida::create([
            'partida_id' => $par1->id,
            'descripcion' => 'Soldadura y Pintura de Verja',
            'unidad' => 'PA', 'cantidad' => 1, 'costo_unitario' => 45000, 'total_presupuestado' => 45000
        ]);

        // $p2 = Proyecto::create([
        //     'nombre' => 'Pintura de Habitación',
        //     'cliente' => 'Maria Marte',
        //     'ubicacion' => 'Santiago, RD',
        //     'fecha_inicio' => '2025-06-01',
        //     'presupuesto_estimado' => 12000,
        //     'itbis' => 2160,
        //     'transporte' => 480,
        //     'supervision_tecnica' => 1200,
        //     'estado' => 'Cotización',
        // ]);
        // $par2 = Partida::create(['proyecto_id' => $p2->id, 'descripcion' => 'Terminaciones']);
        // Subpartida::create([
        //     'partida_id' => $par2->id,
        //     'descripcion' => 'Pintura Paredes y Techo',
        //     'unidad' => 'PA', 'cantidad' => 1, 'costo_unitario' => 12000, 'total_presupuestado' => 12000
        // ]);
    }
}
