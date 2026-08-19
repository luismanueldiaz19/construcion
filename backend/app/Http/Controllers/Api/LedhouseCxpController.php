<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LedhouseCxp;
use Illuminate\Http\Request;

class LedhouseCxpController extends Controller
{
    public function index()
    {
        return response()->json(LedhouseCxp::orderBy('created_at', 'desc')->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'documento' => 'required|string|max:255',
            'proveedor' => 'required|string|max:255',
            'monto_factura' => 'required|numeric|min:0',
            'monto_pagado' => 'nullable|numeric|min:0',
            'fecha_vencimiento' => 'required|date',
            'estado' => 'nullable|string|in:pendiente,pagado,cancelado',
        ]);

        $pagado = $validated['monto_pagado'] ?? 0;
        $pendiente = $validated['monto_factura'] - $pagado;

        $cxp = LedhouseCxp::create(array_merge($validated, [
            'monto_pagado' => $pagado,
            'monto_pendiente' => $pendiente,
            'estado' => $validated['estado'] ?? 'pendiente',
        ]));

        return response()->json($cxp, 201);
    }

    public function show(LedhouseCxp $cxp)
    {
        return response()->json($cxp);
    }

    public function update(Request $request, LedhouseCxp $cxp)
    {
        $validated = $request->validate([
            'documento' => 'sometimes|string|max:255',
            'proveedor' => 'sometimes|string|max:255',
            'monto_factura' => 'sometimes|numeric|min:0',
            'monto_pagado' => 'sometimes|numeric|min:0',
            'fecha_vencimiento' => 'sometimes|date',
            'estado' => 'sometimes|string|in:pendiente,pagado,cancelado',
        ]);

        if (isset($validated['monto_factura']) || isset($validated['monto_pagado'])) {
            $factura = $validated['monto_factura'] ?? $cxp->monto_factura;
            $pagado = $validated['monto_pagado'] ?? $cxp->monto_pagado;
            $validated['monto_pendiente'] = $factura - $pagado;
        }

        $cxp->update($validated);

        return response()->json($cxp);
    }

    public function destroy(LedhouseCxp $cxp)
    {
        $cxp->delete();
        return response()->json(null, 204);
    }
}
