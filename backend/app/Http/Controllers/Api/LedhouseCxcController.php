<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LedhouseCxc;
use App\Models\LedhouseCxcSoporte;
use App\Models\LedhouseCliente;
use Illuminate\Http\Request;
use Barryvdh\DomPDF\Facade\Pdf;

class LedhouseCxcController extends Controller
{
    public function index()
    {
        $cxcs = LedhouseCxc::with('cliente')
            ->withCount('soportes as total_intervenciones')
            ->withMax('soportes as ultima_fecha_visita', 'fecha_visita')
            ->orderBy('created_at', 'desc')
            ->get();
        return response()->json($cxcs);
    }

    public function groupedByCliente()
    {
        $clientes = \App\Models\LedhouseCliente::withSum('cxcs as total_facturado', 'monto_factura')
            ->withSum('cxcs as total_pendiente', 'monto_pendiente')
            ->get();
        return response()->json($clientes);
    }

    public function reportePdf($cliente_id)
    {
        $cliente = LedhouseCliente::findOrFail($cliente_id);
        $cxcs = LedhouseCxc::where('cliente_id', $cliente_id)->get();

        $pdf = Pdf::loadView('pdf.example_temp_url', [
            'cliente' => $cliente,
            'cxcs' => $cxcs,
            'imageUrl' => null // Placeholder
        ]);

        return $pdf->stream("Reporte_CXC_{$cliente->nombre}.pdf");
    }

    public function reporteGeneralPdf()
    {
        $cxcs = LedhouseCxc::with('cliente')->orderBy('fecha_vencimiento', 'asc')->get();

        $pdf = Pdf::loadView('pdf.cxc_general', [
            'cxcs' => $cxcs,
        ]);

        return $pdf->stream("Reporte_General_CXC.pdf");
    }

    public function reporteAgrupadoPdf()
    {
        $clientes = LedhouseCliente::withSum('cxcs as total_facturado', 'monto_factura')
            ->withSum('cxcs as total_pendiente', 'monto_pendiente')
            ->get()
            ->filter(function ($cliente) {
                return $cliente->total_pendiente > 0;
            });

        $pdf = Pdf::loadView('pdf.cxc_agrupado', [
            'clientes' => $clientes,
        ]);

        return $pdf->stream("Reporte_Agrupado_CXC.pdf");
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'documento' => 'required|string|max:255',
            'cliente_id' => 'required|exists:ledhouse_clientes,id',
            'monto_factura' => 'nullable|numeric|min:0',
            'monto_pagado' => 'nullable|numeric|min:0',
            'fecha_factura' => 'nullable|date',
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
            'cliente_id' => 'sometimes|exists:ledhouse_clientes,id',
            'monto_factura' => 'nullable|numeric|min:0',
            'monto_pagado' => 'sometimes|numeric|min:0',
            'fecha_factura' => 'sometimes|nullable|date',
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

    public function importByCliente(Request $request, $cliente_id)
    {
        $request->validate([
            'file' => 'required|file|mimes:xlsx,xls,csv'
        ]);

        $file = $request->file('file');
        
        try {
            $spreadsheet = \PhpOffice\PhpSpreadsheet\IOFactory::load($file->getPathname());
            $worksheet = $spreadsheet->getActiveSheet();
            $rows = $worksheet->toArray();
            
            // Ignore header
            array_shift($rows);
            
            $importedCount = 0;
            
            $cliente = LedhouseCliente::find($cliente_id);
            $dias_credito = $cliente ? ($cliente->dias_credito ?? 0) : 0;

            foreach ($rows as $row) {
                $documento = isset($row[0]) ? trim((string)$row[0]) : null;
                $monto = isset($row[1]) ? trim((string)$row[1]) : null;
                $fecha_factura = isset($row[2]) ? trim((string)$row[2]) : null;
                $monto_factura = isset($row[3]) ? trim((string)$row[3]) : null;

                if ($documento && $monto !== null && $fecha_factura) {
                    $monto = (float)$monto;
                    $monto_factura = ($monto_factura !== '' && is_numeric($monto_factura)) ? (float)$monto_factura : null;
                    $estado = $monto <= 0 ? 'pagado' : 'pendiente';
                    
                    try {
                        $fechaObj = \Carbon\Carbon::parse($fecha_factura);
                        $fecha_factura_db = $fechaObj->format('Y-m-d');
                        $fecha_vencimiento_db = $fechaObj->copy()->addDays($dias_credito)->format('Y-m-d');
                    } catch (\Exception $e) {
                        $fecha_factura_db = $fecha_factura;
                        $fecha_vencimiento_db = $fecha_factura;
                    }

                    // Si ya existe el documento, actualizamos. Si no, lo creamos.
                    LedhouseCxc::updateOrCreate(
                        [
                            'documento' => $documento,
                            'cliente_id' => $cliente_id,
                        ],
                        [
                            'monto_pendiente' => $monto,
                            'monto_factura' => $monto_factura,
                            'fecha_factura' => $fecha_factura_db,
                            'fecha_vencimiento' => $fecha_vencimiento_db,
                            'estado' => $estado,
                            // Si está pagado completamente, asumo monto_pagado = monto_factura
                            'monto_pagado' => $estado === 'pagado' ? ($monto_factura ?? 0) : 0, 
                        ]
                    );
                    $importedCount++;
                }
            }
            
            return response()->json(['message' => "Importado exitosamente. $importedCount registros procesados."]);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Error al importar: ' . $e->getMessage()], 500);
        }
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
