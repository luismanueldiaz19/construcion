<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AssetExpense;
use Illuminate\Http\Request;

class AssetExpenseController extends Controller
{
    public function index()
    {
        $expenses = AssetExpense::with(['asset', 'proyecto', 'proveedor'])->get();
        return response()->json($expenses);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'asset_id' => 'required|exists:assets,id',
            'proyecto_id' => 'nullable|exists:proyectos,id',
            'expense_type' => 'required|string',
            'amount' => 'required|numeric',
            'date' => 'required|date',
            'description' => 'nullable|string',
            'mileage' => 'nullable|integer',
            'gallons' => 'nullable|numeric',
            'proveedor_id' => 'nullable|exists:proveedores,id',
            'payment_method' => 'nullable|string',
            'banco_id' => 'nullable|exists:catalogo_cuentas,id',
        ]);
        
        $expense = AssetExpense::create($validated);
        
        // TODO: Integración Contable.
        // Aquí se puede generar el Asiento Contable automáticamente si se proveen las cuentas.
        // Ejemplo: Débito a Gasto de Mantenimiento (o Gasto Proyecto), Crédito a Banco (banco_id).

        return response()->json($expense, 201);
    }

    public function show($id)
    {
        $expense = AssetExpense::with(['asset', 'proyecto', 'proveedor'])->findOrFail($id);
        return response()->json($expense);
    }
}
