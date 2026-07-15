<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\EmployeeDependent;
use App\Models\Employee;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class EmployeeDependentController extends Controller
{
    public function index(int $id): JsonResponse
    {
        $employee = Employee::findOrFail($id);
        return response()->json($employee->dependents);
    }

    public function store(Request $request, int $id): JsonResponse
    {
        $employee = Employee::findOrFail($id);
        $data = $request->validate([
            'name'             => 'required|string|max:100',
            'relationship'     => 'required|in:hijo,hija,conyuge,padre,madre,otro',
            'birth_date'       => 'nullable|date',
            'is_isr_dependent' => 'boolean',
        ]);
        $dependent = $employee->dependents()->create($data);
        return response()->json($dependent, 201);
    }

    public function destroy(int $depId): JsonResponse
    {
        EmployeeDependent::findOrFail($depId)->delete();
        return response()->json(['message' => 'Dependiente eliminado.']);
    }
}
