<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Documento;
use App\Models\Proyecto;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class DocumentoController extends Controller
{
    public function index($proyectoId)
    {
        $documentos = Documento::where('proyecto_id', $proyectoId)
            ->with('partida')
            ->latest()
            ->get();

        return response()->json($documentos);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'proyecto_id' => 'required|exists:proyectos,id',
            'partida_id' => 'nullable|exists:partidas,id',
            'nombre' => 'required|string|max:255',
            'tipo' => 'required|string|in:plano,evidencia,otro',
            'categoria' => 'nullable|string|max:100',
            'archivo' => 'required|file|mimes:jpg,jpeg,png,pdf|max:15360', // 15MB
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $proyectoId = $request->proyecto_id;
        $file = $request->file('archivo');
        
        // Generar ruta: proyectos/{id}/documentos/{tipo}
        $path = $file->store("proyectos/{$proyectoId}/documentos", 'public');

        $documento = Documento::create([
            'proyecto_id' => $proyectoId,
            'partida_id' => $request->partida_id,
            'nombre' => $request->nombre,
            'tipo' => $request->tipo,
            'categoria' => $request->categoria,
            'file_path' => $path,
            'file_extension' => $file->getClientOriginalExtension(),
            'file_size' => $file->getSize(),
        ]);

        return response()->json([
            'message' => 'Documento subido con éxito',
            'documento' => $documento
        ], 201);
    }

    public function destroy($id)
    {
        $documento = Documento::findOrFail($id);
        
        // Eliminar archivo físico
        if (Storage::disk('public')->exists($documento->file_path)) {
            Storage::disk('public')->delete($documento->file_path);
        }

        $documento->delete();

        return response()->json(['message' => 'Documento eliminado con éxito']);
    }
}
