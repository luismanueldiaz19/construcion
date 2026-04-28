<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Material;
use Illuminate\Http\Request;

class MaterialController extends Controller
{
    public function index()
    {
        return Material::with('categoria')->orderBy('nombre')->get();
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'codigo' => 'required|string|unique:materiales',
            'nombre' => 'required|string',
            'descripcion' => 'nullable|string',
            'categoria_id' => 'nullable|exists:categorias,id',
            'unidad' => 'required|string',
            'precio_costo' => 'numeric',
        ]);
        return Material::create($validated);
    }

    public function update(Request $request, $id) {
        $material = Material::findOrFail($id);
        $validated = $request->validate([
            'codigo' => 'required|string|unique:materiales,codigo,' . $material->id,
            'nombre' => 'required|string',
            'descripcion' => 'nullable|string',
            'categoria_id' => 'nullable|exists:categorias,id',
            'unidad' => 'required|string',
            'precio_costo' => 'numeric',
        ]);
        
        $material->update($validated);
        return $material;
    }

    public function toggleEstado($id)
    {
        $material = Material::findOrFail($id);
        $material->estado = !$material->estado;
        $material->save();
        return response()->json([
            'message' => 'Estado actualizado',
            'nuevo_estado' => $material->estado
        ]);
    }

    public function inventarioPorProyecto()
    {
        return \App\Models\Proyecto::with(['compraDetalles.material'])
            ->get()
            ->map(function ($proyecto) {
                $materiales = $proyecto->compraDetalles->groupBy('material_id')->map(function ($items) {
                    $first = $items->first();
                    if (!$first || !$first->material) return null;
                    return [
                        'material' => $first->material->nombre,
                        'unidad' => $first->material->unidad,
                        'cantidad_total' => $items->sum('cantidad'),
                        'inversion_total' => $items->sum('subtotal'),
                    ];
                })->filter()->values();

                return [
                    'id' => $proyecto->id,
                    'nombre' => $proyecto->nombre,
                    'materiales' => $materiales
                ];
            });
    }
}
