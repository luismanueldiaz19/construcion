<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\CuentaCatalogoLedhouse;

class LedhouseCuentaCatalogoController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $query = CuentaCatalogoLedhouse::query();

        if ($request->has('search')) {
            $search = $request->input('search');
            $query->where('codigo', 'like', "%{$search}%")
                  ->orWhere('descripcion', 'like', "%{$search}%");
        }

        return response()->json($query->get());
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'codigo' => 'required|string|unique:cuenta_catalogo_ledhouse,codigo',
            'descripcion' => 'required|string',
            'origen' => 'required|in:VENTAS,COSTOS,GASTOS',
        ]);

        $cuenta = CuentaCatalogoLedhouse::create($validated);

        return response()->json($cuenta, 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $cuenta = CuentaCatalogoLedhouse::findOrFail($id);
        return response()->json($cuenta);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        $cuenta = CuentaCatalogoLedhouse::findOrFail($id);

        $validated = $request->validate([
            'codigo' => 'required|string|unique:cuenta_catalogo_ledhouse,codigo,' . $id,
            'descripcion' => 'required|string',
            'origen' => 'required|in:VENTAS,COSTOS,GASTOS',
        ]);

        $cuenta->update($validated);

        return response()->json($cuenta);
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
            $validOrigenes = ['VENTAS', 'COSTOS', 'GASTOS'];

            foreach ($rows as $row) {
                $codigo = isset($row[0]) ? trim((string)$row[0]) : null;
                $descripcion = isset($row[1]) ? trim((string)$row[1]) : null;
                $origenRaw = isset($row[2]) ? strtoupper(trim((string)$row[2])) : 'VENTAS';
                
                $origen = in_array($origenRaw, $validOrigenes) ? $origenRaw : 'VENTAS';
                
                if ($codigo && $descripcion) {
                    CuentaCatalogoLedhouse::updateOrCreate(
                        ['codigo' => $codigo],
                        [
                            'descripcion' => $descripcion,
                            'origen' => $origen
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
        $cuenta = CuentaCatalogoLedhouse::findOrFail($id);
        $cuenta->delete();

        return response()->json(null, 204);
    }
}
