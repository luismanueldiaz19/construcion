<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\LedhouseCliente;

class LedhouseClienteController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $query = LedhouseCliente::query();

        if ($request->has('search') && trim($request->input('search')) !== '') {
            $search = strtolower(trim($request->input('search')));
            $query->where(function ($q) use ($search) {
                $q->whereRaw('LOWER(nombre) LIKE ?', ["%{$search}%"])
                  ->orWhereRaw('LOWER(whatsapp) LIKE ?', ["%{$search}%"]);
            });
        }

        return response()->json($query->orderBy('id', 'desc')->get());
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'nombre' => 'required|string',
            'whatsapp' => 'nullable|string',
            'direccion' => 'nullable|string',
            'tipo_documento' => 'nullable|string|in:Cédula,RNC',
            'documento' => 'nullable|string',
            'limite_credito' => 'nullable|numeric',
            'dias_credito' => 'nullable|integer',
        ]);

        $cliente = LedhouseCliente::create($validated);

        return response()->json($cliente, 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $cliente = LedhouseCliente::findOrFail($id);
        return response()->json($cliente);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        $cliente = LedhouseCliente::findOrFail($id);

        $validated = $request->validate([
            'nombre' => 'required|string',
            'whatsapp' => 'nullable|string',
            'direccion' => 'nullable|string',
            'tipo_documento' => 'nullable|string|in:Cédula,RNC',
            'documento' => 'nullable|string',
            'limite_credito' => 'nullable|numeric',
            'dias_credito' => 'nullable|integer',
        ]);

        $cliente->update($validated);

        return response()->json($cliente);
    }

    /**
     * Import records from Excel
     */
    public function import(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:xlsx,xls,csv'
        ]);

        $file = $request->file('file');
        
        try {
            $spreadsheet = \PhpOffice\PhpSpreadsheet\IOFactory::load($file->getPathname());
            $worksheet = $spreadsheet->getActiveSheet();
            $rows = $worksheet->toArray();
            
            // Assuming first row is header
            $header = array_shift($rows);
            
            $importedCount = 0;

            foreach ($rows as $row) {
                $nombre   = isset($row[0]) ? trim((string)$row[0]) : null;
                $whatsapp = isset($row[1]) ? trim((string)$row[1]) : null;
                $direccion = isset($row[2]) ? trim((string)$row[2]) : null;
                $limite_credito = isset($row[3]) ? trim((string)$row[3]) : null;
                $dias_credito = isset($row[4]) ? trim((string)$row[4]) : null;
                $tipo_documento = isset($row[5]) ? trim((string)$row[5]) : null;
                $documento = isset($row[6]) ? trim((string)$row[6]) : null;

                // Whatsapp can be empty, only nombre is required
                $whatsapp = $whatsapp !== '' ? $whatsapp : null;
                $direccion = $direccion !== '' ? $direccion : null;
                $documento = $documento !== '' ? $documento : null;

                if ($tipo_documento !== '') {
                    $lower_tipo = strtolower($tipo_documento);
                    if ($lower_tipo === 'cedula' || $lower_tipo === 'cédula') {
                        $tipo_documento = 'Cédula';
                    } elseif ($lower_tipo === 'rnc') {
                        $tipo_documento = 'RNC';
                    } else {
                        $tipo_documento = null;
                    }
                } else {
                    $tipo_documento = null;
                }
                
                $limite_credito = ($limite_credito !== '' && is_numeric($limite_credito)) ? (float)$limite_credito : 0;
                $dias_credito = ($dias_credito !== '' && is_numeric($dias_credito)) ? (int)$dias_credito : 0;

                if ($nombre) {
                    LedhouseCliente::updateOrCreate(
                        ['nombre' => $nombre],
                        [
                            'whatsapp'  => $whatsapp,
                            'direccion' => $direccion,
                            'tipo_documento' => $tipo_documento,
                            'documento' => $documento,
                            'limite_credito' => $limite_credito,
                            'dias_credito' => $dias_credito,
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

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        $cliente = LedhouseCliente::findOrFail($id);
        $cliente->delete();

        return response()->json(null, 204);
    }
}
