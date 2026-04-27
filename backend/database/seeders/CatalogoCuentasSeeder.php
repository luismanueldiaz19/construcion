<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class CatalogoCuentasSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $cuentas = [
            ['codigo' => '1', 'nombre' => 'ACTIVOS', 'tipo' => 'Activo', 'nivel' => 1, 'es_detalle' => false],
            ['codigo' => '1.1', 'nombre' => 'ACTIVOS CORRIENTES', 'tipo' => 'Activo', 'nivel' => 2, 'padre_codigo' => '1', 'es_detalle' => false],
            ['codigo' => '1.1.01', 'nombre' => 'EFECTIVO EN CAJA Y BANCOS', 'tipo' => 'Activo', 'nivel' => 3, 'padre_codigo' => '1.1', 'es_detalle' => false],
            ['codigo' => '1.1.01.01', 'nombre' => 'Caja General', 'tipo' => 'Activo', 'nivel' => 4, 'padre_codigo' => '1.1.01', 'es_detalle' => true],
            ['codigo' => '1.1.01.02', 'nombre' => 'Banco Popular', 'tipo' => 'Activo', 'nivel' => 4, 'padre_codigo' => '1.1.01', 'es_detalle' => true],
            ['codigo' => '1.1.02', 'nombre' => 'INVENTARIOS', 'tipo' => 'Activo', 'nivel' => 3, 'padre_codigo' => '1.1', 'es_detalle' => true],
            ['codigo' => '1.1.03', 'nombre' => 'ITBIS PAGADO (CRÉDITO FISCAL)', 'tipo' => 'Activo', 'nivel' => 3, 'padre_codigo' => '1.1', 'es_detalle' => true],
            
            ['codigo' => '2', 'nombre' => 'PASIVOS', 'tipo' => 'Pasivo', 'nivel' => 1, 'es_detalle' => false],
            ['codigo' => '2.1', 'nombre' => 'PASIVOS CORRIENTES', 'tipo' => 'Pasivo', 'nivel' => 2, 'padre_codigo' => '2', 'es_detalle' => false],
            ['codigo' => '2.1.01', 'nombre' => 'CUENTAS POR PAGAR PROVEEDORES', 'tipo' => 'Pasivo', 'nivel' => 3, 'padre_codigo' => '2.1', 'es_detalle' => true],
            ['codigo' => '2.1.03', 'nombre' => 'ITBIS POR PAGAR', 'tipo' => 'Pasivo', 'nivel' => 3, 'padre_codigo' => '2.1', 'es_detalle' => true],
            
            ['codigo' => '4', 'nombre' => 'INGRESOS', 'tipo' => 'Ingreso', 'nivel' => 1, 'es_detalle' => false],
            ['codigo' => '4.1', 'nombre' => 'INGRESOS POR CONSTRUCCIÓN', 'tipo' => 'Ingreso', 'nivel' => 2, 'padre_codigo' => '4', 'es_detalle' => false],
            ['codigo' => '4.1.01', 'nombre' => 'Ingresos por Proyectos', 'tipo' => 'Ingreso', 'nivel' => 3, 'padre_codigo' => '4.1', 'es_detalle' => true],

            ['codigo' => '5', 'nombre' => 'COSTOS', 'tipo' => 'Costo', 'nivel' => 1, 'es_detalle' => false],
            ['codigo' => '5.1', 'nombre' => 'COSTOS DE CONSTRUCCIÓN', 'tipo' => 'Costo', 'nivel' => 2, 'padre_codigo' => '5', 'es_detalle' => false],
            ['codigo' => '5.1.01', 'nombre' => 'Materiales', 'tipo' => 'Costo', 'nivel' => 3, 'padre_codigo' => '5.1', 'es_detalle' => true],
            ['codigo' => '5.1.02', 'nombre' => 'Mano de Obra', 'tipo' => 'Costo', 'nivel' => 3, 'padre_codigo' => '5.1', 'es_detalle' => true],
            ['codigo' => '5.1.03', 'nombre' => 'Alquiler de Equipos y Herramientas', 'tipo' => 'Costo', 'nivel' => 3, 'padre_codigo' => '5.1', 'es_detalle' => true],
            ['codigo' => '5.1.04', 'nombre' => 'Servicios de Terceros (Sub-contratos)', 'tipo' => 'Costo', 'nivel' => 3, 'padre_codigo' => '5.1', 'es_detalle' => true],
            ['codigo' => '5.1.05', 'nombre' => 'Gastos Indirectos (Supervisión y Otros)', 'tipo' => 'Costo', 'nivel' => 3, 'padre_codigo' => '5.1', 'es_detalle' => true],
            ['codigo' => '5.1.06', 'nombre' => 'Transporte y Acarreo', 'tipo' => 'Costo', 'nivel' => 3, 'padre_codigo' => '5.1', 'es_detalle' => true],
            ['codigo' => '5.1.07', 'nombre' => 'Seguros y Otros Costos de Obra', 'tipo' => 'Costo', 'nivel' => 3, 'padre_codigo' => '5.1', 'es_detalle' => true],
        ];

        foreach ($cuentas as $c) {
            $padreId = null;    
            if (isset($c['padre_codigo'])) {
                $padreId = \App\Models\CatalogoCuenta::where('codigo', $c['padre_codigo'])->first()->id;
            }
            \App\Models\CatalogoCuenta::updateOrCreate(
                ['codigo' => $c['codigo']],
                [
                    'nombre' => $c['nombre'],
                    'tipo' => $c['tipo'],
                    'nivel' => $c['nivel'],
                    'padre_id' => $padreId,
                    'es_detalle' => $c['es_detalle'],
                ]
            );
        }
    }
}
