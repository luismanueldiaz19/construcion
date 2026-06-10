<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Proveedor;
use Illuminate\Http\Request;

class ProveedorController extends Controller
{
    public function index(Request $request)
    {
        $query = Proveedor::query();

        if ($request->has('search') && !empty($request->search)) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('code', 'like', "%{$search}%")
                  ->orWhere('rnc', 'like', "%{$search}%");
            });
        }

        if ($request->has('type') && !empty($request->type)) {
            $query->where('type', $request->type);
        }

        if ($request->has('classification') && !empty($request->classification)) {
            $query->where('classification', $request->classification);
        }

        if ($request->has('active') && $request->active !== '') {
            $query->where('active', filter_var($request->active, FILTER_VALIDATE_BOOLEAN));
        }

        return $query->orderBy('name')->get();
    }

    public function show($id)
    {
        return Proveedor::findOrFail($id);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'code' => 'nullable|string|unique:proveedores',
            'type' => 'required|in:empresa,persona_fisica,subcontratista',
            'name' => 'required|string|max:255',
            'commercial_name' => 'nullable|string|max:255',
            'rnc' => 'nullable|string|max:50',
            'contact_name' => 'nullable|string|max:255',
            'contact_position' => 'nullable|string|max:255',
            'phone' => 'nullable|string|max:50',
            'mobile' => 'nullable|string|max:50',
            'whatsapp' => 'nullable|string|max:50',
            'email' => 'nullable|email|max:255',
            'country' => 'nullable|string|max:100',
            'province' => 'nullable|string|max:100',
            'city' => 'nullable|string|max:100',
            'sector' => 'nullable|string|max:100',
            'address' => 'nullable|string',
            'allow_credit' => 'boolean',
            'credit_days' => 'integer|min:0',
            'credit_limit' => 'numeric|min:0',
            'bank_name' => 'nullable|string|max:100',
            'account_number' => 'nullable|string|max:100',
            'account_type' => 'nullable|string|max:50',
            'classification' => 'required|in:excelente,bueno,regular,riesgoso',
            'active' => 'boolean',
            'notes' => 'nullable|string',
        ]);

        if (empty($validated['code'])) {
            $lastProv = Proveedor::withTrashed()->latest('id')->first();
            $nextId = $lastProv ? $lastProv->id + 1 : 1;
            $validated['code'] = 'PROV-' . str_pad($nextId, 4, '0', STR_PAD_LEFT);
        }

        return Proveedor::create($validated);
    }

    public function update(Request $request, $id)
    {
        $proveedor = Proveedor::findOrFail($id);

        $validated = $request->validate([
            'code' => 'nullable|string|unique:proveedores,code,' . $id,
            'type' => 'required|in:empresa,persona_fisica,subcontratista',
            'name' => 'required|string|max:255',
            'commercial_name' => 'nullable|string|max:255',
            'rnc' => 'nullable|string|max:50',
            'contact_name' => 'nullable|string|max:255',
            'contact_position' => 'nullable|string|max:255',
            'phone' => 'nullable|string|max:50',
            'mobile' => 'nullable|string|max:50',
            'whatsapp' => 'nullable|string|max:50',
            'email' => 'nullable|email|max:255',
            'country' => 'nullable|string|max:100',
            'province' => 'nullable|string|max:100',
            'city' => 'nullable|string|max:100',
            'sector' => 'nullable|string|max:100',
            'address' => 'nullable|string',
            'allow_credit' => 'boolean',
            'credit_days' => 'integer|min:0',
            'credit_limit' => 'numeric|min:0',
            'bank_name' => 'nullable|string|max:100',
            'account_number' => 'nullable|string|max:100',
            'account_type' => 'nullable|string|max:50',
            'classification' => 'required|in:excelente,bueno,regular,riesgoso',
            'active' => 'boolean',
            'notes' => 'nullable|string',
        ]);

        if (empty($validated['code'])) {
            $validated['code'] = $proveedor->code;
        }

        $proveedor->update($validated);
        return $proveedor;
    }

    public function toggleActive($id)
    {
        $proveedor = Proveedor::findOrFail($id);
        $proveedor->active = !$proveedor->active;
        $proveedor->save();

        return response()->json([
            'message' => 'Estado actualizado',
            'proveedor' => $proveedor
        ]);
    }
}
