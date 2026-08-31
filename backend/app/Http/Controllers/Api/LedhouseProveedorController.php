<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\LedhouseProveedor;
use Illuminate\Support\Facades\Validator;

class LedhouseProveedorController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $proveedores = LedhouseProveedor::orderBy('nombre')->get();
        return response()->json($proveedores);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'nombre' => 'required|string|max:255',
            'empresa' => 'nullable|string|max:255',
            'rnc_cedula' => 'nullable|string|max:50',
            'whatsapp' => 'nullable|string|max:50',
            'correo' => 'nullable|email|max:255',
            'direccion' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $proveedor = LedhouseProveedor::create($request->all());

        return response()->json([
            'success' => true,
            'message' => 'Proveedor creado con éxito',
            'data' => $proveedor
        ], 201);
    }

    /**
     * Display the specified resource.
     */
    public function show($id)
    {
        $proveedor = LedhouseProveedor::find($id);
        
        if (!$proveedor) {
            return response()->json([
                'success' => false,
                'message' => 'Proveedor no encontrado'
            ], 404);
        }

        return response()->json($proveedor);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, $id)
    {
        $proveedor = LedhouseProveedor::find($id);

        if (!$proveedor) {
            return response()->json([
                'success' => false,
                'message' => 'Proveedor no encontrado'
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'nombre' => 'required|string|max:255',
            'empresa' => 'nullable|string|max:255',
            'rnc_cedula' => 'nullable|string|max:50',
            'whatsapp' => 'nullable|string|max:50',
            'correo' => 'nullable|email|max:255',
            'direccion' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $proveedor->update($request->all());

        return response()->json([
            'success' => true,
            'message' => 'Proveedor actualizado con éxito',
            'data' => $proveedor
        ]);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy($id)
    {
        $proveedor = LedhouseProveedor::find($id);

        if (!$proveedor) {
            return response()->json([
                'success' => false,
                'message' => 'Proveedor no encontrado'
            ], 404);
        }

        // Aquí podríamos validar si tiene cuentas por pagar asociadas antes de eliminar
        // pero por ahora seguimos el estándar básico
        $proveedor->delete();

        return response()->json([
            'success' => true,
            'message' => 'Proveedor eliminado con éxito'
        ]);
    }
}
