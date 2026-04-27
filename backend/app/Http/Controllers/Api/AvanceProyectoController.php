<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AvanceProyecto;
use App\Models\Subpartida;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AvanceProyectoController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'subpartida_id' => 'required|exists:subpartidas,id',
            'fecha' => 'required|date',
            'porcentaje' => 'required|numeric|min:0|max:100',
            'valor_ejecutado' => 'required|numeric',
            'evidencias_url' => 'nullable|string',
        ]);

        return DB::transaction(function () use ($validated) {
            $avance = AvanceProyecto::create($validated);
            
            // Aquí se podría actualizar el estado de la subpartida si fuera necesario
            
            return $avance;
        });
    }

    public function history($subpartidaId)
    {
        return AvanceProyecto::where('subpartida_id', $subpartidaId)->latest()->get();
    }
}
