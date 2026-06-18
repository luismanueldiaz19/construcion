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
            'code' => 'PROV-0001',
            'type' => 'empresa',
            'name' => 'Ing. Edgar Martinez SRL',
            'rnc' => '105044031',
            'phone' => '808-586-4303',
            'city' => 'Puerto Plata',
            'classification' => 'excelente',
        ]);
        
        // Proveedor::create([
        //     'code' => 'PROV-0002',
        //     'type' => 'empresa',
        //     'name' => 'Capiteria Jose',
        //     'rnc' => '6253199-5',
        //     'phone' => '809-555-5555',
        //     'city' => 'Puerto Plata',
        //     'classification' => 'bueno',
        // ]);
        
        // Proveedor::create([
        //     'code' => 'PROV-0003',
        //     'type' => 'persona_fisica',
        //     'name' => 'Pedro (Albañil)',
        //     'rnc' => '8595',
        //     'phone' => '809-555-6352',
        //     'city' => 'Santiago',
        //     'classification' => 'bueno',
        // ]);
        
        // Proveedor::create([
        //     'code' => 'PROV-0004',
        //     'type' => 'empresa',
        //     'name' => 'IMCA Cat Rentals',
        //     'rnc' => '5888859-9',
        //     'phone' => '809-560-4622',
        //     'address' => 'Autopista Duarte KM 11 ½, Villa Peravia',
        //     'city' => 'Santo Domingo',
        //     'country' => 'Rep. Dom',
        //     'classification' => 'excelente',
        // ]);
    }
}
