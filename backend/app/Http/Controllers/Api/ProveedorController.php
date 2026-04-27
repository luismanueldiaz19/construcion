<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Proveedor;
use Illuminate\Http\Request;

class ProveedorController extends Controller
{
    public function index()
    {
        return Proveedor::all();
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'nombre' => 'required|string',
            'rnc' => 'nullable|string|unique:proveedores',
            'telefono' => 'nullable|string',
            'direccion' => 'nullable|string',
        ]);

        return Proveedor::create($validated);
    }
}
