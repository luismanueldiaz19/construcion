<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Proyecto;
use App\Models\Inventario;
use Illuminate\Http\Request;

class InventarioController extends Controller
{
    public function index()
    {
        // Retornar los proyectos que tienen inventario
        return Proyecto::with(['inventarios.material'])->get()->map(function($proyecto) {
            return [
                'id' => $proyecto->id,
                'nombre' => $proyecto->nombre,
                'materiales' => $proyecto->inventarios->map(function($inv) {
                    return [
                        'material_id' => $inv->material_id,
                        'material' => $inv->material->nombre,
                        'unidad' => $inv->material->unidad,
                        'cantidad_total' => $inv->stock,
                        // Calculamos inversión basada en el promedio o último precio (simplificado)
                        'inversion_total' => $inv->stock * \App\Models\CompraDetalle::where('material_id', $inv->material_id)
                            ->latest()
                            ->value('precio_unitario') ?? 0
                    ];
                })
            ];
        });
    }
}
