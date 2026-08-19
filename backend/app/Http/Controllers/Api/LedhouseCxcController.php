<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LedhouseCxc;
use App\Models\LedhouseCxcSoporte;
use Illuminate\Http\Request;

class LedhouseCxcController extends Controller
{
    public function index()
    {
        $cxcs = LedhouseCxc::withCount('soportes as total_intervenciones')
            ->withMax('soportes as ultima_fecha_visita', 'fecha_visita')
            ->orderBy('created_at', 'desc')
            ->get();
        return response()->json($cxcs);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'documento' => 'required|string|max:255',
            'cliente' => 'required|string|max:255',
            'monto_factura' => 'required|numeric|min:0',
            'monto_pagado' => 'nullable|numeric|min:0',
            'fecha_vencimiento' => 'required|date',
            'estado' => 'nullable|string|in:pendiente,pagado,cancelado',
        ]);

        $pagado = $validated['monto_pagado'] ?? 0;
        $pendiente = $validated['monto_factura'] - $pagado;

        $cxc = LedhouseCxc::create(array_merge($validated, [
            'monto_pagado' => $pagado,
            'monto_pendiente' => $pendiente,
            'estado' => $validated['estado'] ?? 'pendiente',
        ]));

        return response()->json($cxc, 201);
    }

    public function show(LedhouseCxc $cxc)
    {
        $cxc->load('soportes');
        return response()->json($cxc);
    }

    public function update(Request $request, LedhouseCxc $cxc)
    {
        $validated = $request->validate([
            'documento' => 'sometimes|string|max:255',
            'cliente' => 'sometimes|string|max:255',
            'monto_factura' => 'sometimes|numeric|min:0',
            'monto_pagado' => 'sometimes|numeric|min:0',
            'fecha_vencimiento' => 'sometimes|date',
            'estado' => 'sometimes|string|in:pendiente,pagado,cancelado',
        ]);

        if (isset($validated['monto_factura']) || isset($validated['monto_pagado'])) {
            $factura = $validated['monto_factura'] ?? $cxc->monto_factura;
            $pagado = $validated['monto_pagado'] ?? $cxc->monto_pagado;
            $validated['monto_pendiente'] = $factura - $pagado;
        }

        $cxc->update($validated);

        return response()->json($cxc);
    }

    public function destroy(LedhouseCxc $cxc)
    {
        $cxc->delete();
        return response()->json(null, 204);
    }

    // --- Soportes ---
    public function getSoportes(LedhouseCxc $cxc)
    {
        return response()->json($cxc->soportes()->orderBy('fecha', 'desc')->get());
    }

    public function addSoporte(Request $request, LedhouseCxc $cxc)
    {
        $validated = $request->validate([
            'nota' => 'required|string',
            'fecha' => 'required|date',
            'fecha_visita' => 'nullable|date',
        ]);

        $soporte = $cxc->soportes()->create($validated);
        return response()->json($soporte, 201);
    }
}
