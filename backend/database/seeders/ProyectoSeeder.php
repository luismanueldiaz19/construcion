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
        // El presupuesto_estimado debe ser el subtotal (suma de las subpartidas)
        // ya que los globales (ITBIS, Transporte, etc.) se suman en los accessors
        $proyecto = Proyecto::create([
            'nombre' => 'REMODELACION CASA',
            'cliente' => 'EMILIA ALBANIA MARIA RODRIGUEZ',
            'ubicacion' => 'VISTA BELLA, LOS MAESTROS, PUERTO PLATA',
            'fecha_inicio' => '2025-02-28',
            'presupuesto_estimado' => 6778995.00, // Subtotal real de las partidas
            'supervision_tecnica' => 677899.50,   // 10% del subtotal
            'itbis' => 122021.91,                 // 18% de la supervisión técnica
            'transporte' => 271159.80,            // 4% del subtotal
            'otros_costos' => 0,
            'estado' => 'Cotización',
            'notas' => 'El monto de este presupuesto es valido por 30 dias luego de ser entregado al cliente',
        ]);

        // 2. Definir Estructura de Partidas y Subpartidas (Data Fiel a la Imagen)
        $data = [
            '1,00 PRELIMINARES' => [
                ['desc' => 'Demolicion en general', 'und' => 'M2', 'cant' => 320, 'precio' => 500],
                ['desc' => 'Demolicion piso interior 2 niveles', 'und' => 'M2', 'cant' => 171.29, 'precio' => 500],
                ['desc' => 'Bote general', 'und' => 'PA', 'cant' => 1, 'precio' => 40000],
            ],
            '2,00 PISO' => [
                ['desc' => 'Suministro y colocacion de ceramica en piso interior', 'und' => 'M2', 'cant' => 280, 'precio' => 1750],
            ],
            '3,00 VENTANAS, PUERTAS CORREDIZAS Y PASAMANOS' => [
                ['desc' => 'Suministro y colocacion de ventanas en material P65 y puertas corredizas, y puerta de polimetal area de lavado', 'und' => 'PA', 'cant' => 1, 'precio' => 301000],
                ['desc' => 'Suministro y colocacion de puertas interiores, habitaciones y baños', 'und' => 'UND', 'cant' => 9, 'precio' => 33000],
                ['desc' => 'Suministro y colocacion de puerta principal', 'und' => 'UND', 'cant' => 1, 'precio' => 42000],
                ['desc' => 'Suministro y colocacion d pasamanos en escalera 1er y 2do nivel;', 'und' => 'pl', 'cant' => 45, 'precio' => 2800],
            ],
            '4,00 TECHO' => [
                ['desc' => 'Acondicionamiento de todos los techos según nueva fachada', 'und' => 'pa', 'cant' => 1, 'precio' => 983000],
                ['desc' => 'Selladores', 'und' => 'M2', 'cant' => 140, 'precio' => 1100],
            ],
            '5,00 HABITACION+ W/C + BAÑO' => [
                ['desc' => 'Construccion de espacios nuebos', 'und' => 'M2', 'cant' => 35, 'precio' => 54000],
            ],
            '6,00 COCINA' => [
                ['desc' => 'Remodelacion de cocina y desayunador, incluye redistribucion de fregadero y estufa, espacio para horno zafacon de basura, microonas y estractor de grasa, cierre de ventana, muebles en madera preciosa y tope en granito, desayunador con isla y gabinetes.', 'und' => 'PA', 'cant' => 1, 'precio' => 720350],
            ],
            '8,00 PINTURA' => [
                ['desc' => 'Pañete y preparacion de paredes según requerimiento', 'und' => 'PA', 'cant' => 1, 'precio' => 120000],
                ['desc' => 'Pintura general interior, exterior,', 'und' => 'PA', 'cant' => 1, 'precio' => 245000],
            ],
            '9,00 MISCELANEO' => [
                ['desc' => 'Adecuaciones en general según nueva fachada', 'und' => 'PA', 'cant' => 1, 'precio' => 1100000],
                ['desc' => 'Limpieza general', 'und' => 'PA', 'cant' => 1, 'precio' => 25000],
            ],
        ];

        foreach ($data as $partidaNombre => $subpartidas) {
            $partida = $proyecto->partidas()->create([
                'descripcion' => $partidaNombre,
            ]);

            foreach ($subpartidas as $s) {
                $partida->subpartidas()->create([
                    'descripcion' => $s['desc'],
                    'unidad' => $s['und'],
                    'cantidad' => $s['cant'],
                    'costo_unitario' => $s['precio'],
                    'total_presupuestado' => $s['cant'] * $s['precio'],
                ]);
            }
        }
    }
}
