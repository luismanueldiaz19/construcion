<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use App\Models\Proveedor;


class ProveedorSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
Proveedor::create([
    'nombre' => 'Ing. Edgar Martinez SRL',
    'rnc' => '105044031',
    'telefono' => '808-586-4303',
    'direccion' => 'Puerto plata',
]);
Proveedor::create([
    'nombre' => 'Capiteria Jose',
    'rnc' => '6253199-5',
    'telefono' => '809-555-5555',
    'direccion' => 'Puerto plata',
]);

Proveedor::create([
    'nombre' => 'Pedro (Albañir)',
    'rnc' => '8595',
    'telefono' => '809-555-6352',
    'direccion' => 'Santiago',
]);

Proveedor::create([
    'nombre' => 'IMCA Cat Rentals',
    'rnc' => '5888859-9',
    'telefono' => '809-560-4622',
    'direccion' => 'Autopista Duarte KM 11 ½, Villa Peravia, Santo Domingo, Rep. Dom',
]);
    }
}
