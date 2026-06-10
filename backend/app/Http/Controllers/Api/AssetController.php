<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Asset;
use Illuminate\Http\Request;

class AssetController extends Controller
{
    public function index()
    {
        $assets = Asset::with(['category', 'assignments.user', 'assignments.proyecto', 'expenses'])->get();
        return response()->json($assets);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'category_id' => 'required|exists:asset_categories,id',
            'name' => 'required|string|max:255',
            'brand' => 'nullable|string',
            'model' => 'nullable|string',
            'serial_number' => 'nullable|string',
            'purchase_date' => 'nullable|date',
            'initial_cost' => 'nullable|numeric',
            'status' => 'nullable|string',
            'notes' => 'nullable|string',
        ]);
        
        $asset = Asset::create($validated);
        return response()->json($asset, 201);
    }

    public function show($id)
    {
        $asset = Asset::with(['category', 'assignments.user', 'assignments.proyecto', 'expenses'])->findOrFail($id);
        
        return response()->json($asset);
    }

    public function update(Request $request, $id)
    {
        $asset = Asset::findOrFail($id);
        
        $validated = $request->validate([
            'category_id' => 'sometimes|exists:asset_categories,id',
            'name' => 'sometimes|string|max:255',
            'brand' => 'nullable|string',
            'model' => 'nullable|string',
            'serial_number' => 'nullable|string',
            'purchase_date' => 'nullable|date',
            'initial_cost' => 'nullable|numeric',
            'status' => 'nullable|string',
            'notes' => 'nullable|string',
        ]);
        
        $asset->update($validated);
        return response()->json($asset);
    }
}
