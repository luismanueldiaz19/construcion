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
    'nombre' => 'Bellon',
    'rnc' => '0-5959985-5',
    'telefono' => '809-555-5555',
    'direccion' => 'Santiago',
]);

Proveedor::create([
    'nombre' => 'Ochoa',
    'rnc' => '0-58262-5',
    'telefono' => '809-555-6352',
    'direccion' => 'Santiago',
]);

Proveedor::create([
    'nombre' => 'Ferreteria Papo',
    'rnc' => '0-8965-5',
    'telefono' => '809-555-6352',
    'direccion' => 'Santiago',
]);
    }
}
