<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\EmployeeDocument;
use App\Models\Employee;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class EmployeeDocumentController extends Controller
{
    public function index(int $id): JsonResponse
    {
        $employee = Employee::findOrFail($id);
        return response()->json($employee->documents);
    }

    public function store(Request $request, int $id): JsonResponse
    {
        $employee = Employee::findOrFail($id);
        $data = $request->validate([
            'document_type'   => 'required|in:contrato,cedula,titulo,certificacion,otro',
            'file_path'       => 'required|string',
            'file_name'       => 'nullable|string',
            'expiration_date' => 'nullable|date',
            'notes'           => 'nullable|string',
        ]);
        $doc = $employee->documents()->create($data);
        return response()->json($doc, 201);
    }

    public function destroy(int $docId): JsonResponse
    {
        EmployeeDocument::findOrFail($docId)->delete();
        return response()->json(['message' => 'Documento eliminado.']);
    }
}
