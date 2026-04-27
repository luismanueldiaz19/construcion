<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Material;
use Illuminate\Http\Request;

class MaterialController extends Controller
{
    public function index()
    {
        return Material::all();
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'nombre' => 'required|string',
            'unidad' => 'required|string',
        ]);
        return Material::create($validated);
    }

    public function inventarioPorProyecto()
    {
        return \App\Models\Proyecto::with(['compraDetalles.material'])
            ->get()
            ->map(function ($proyecto) {
                $materiales = $proyecto->compraDetalles->groupBy('material_id')->map(function ($items) {
                    return [
                        'material' => $items->first()->material->nombre,
                        'unidad' => $items->first()->material->unidad,
                        'cantidad_total' => $items->sum('cantidad'),
                        'inversion_total' => $items->sum('subtotal'),
                    ];
                })->values();

                return [
                    'id' => $proyecto->id,
                    'nombre' => $proyecto->nombre,
                    'materiales' => $materiales
                ];
            });
    }
}
