<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AssetCategory;
use Illuminate\Http\Request;

class AssetCategoryController extends Controller
{
    public function index()
    {
        return response()->json(AssetCategory::all());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'default_asset_account_id' => 'nullable|exists:catalogo_cuentas,id',
            'default_expense_account_id' => 'nullable|exists:catalogo_cuentas,id',
        ]);
        
        $category = AssetCategory::create($validated);
        return response()->json($category, 201);
    }

    public function update(Request $request, $id)
    {
        $category = AssetCategory::findOrFail($id);
        
        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'description' => 'nullable|string',
            'default_asset_account_id' => 'nullable|exists:catalogo_cuentas,id',
            'default_expense_account_id' => 'nullable|exists:catalogo_cuentas,id',
        ]);
        
        $category->update($validated);
        return response()->json($category);
    }

    public function destroy($id)
    {
        $category = AssetCategory::findOrFail($id);
        $category->delete();
        return response()->json(null, 204);
    }
}
