<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Client;
use Illuminate\Http\Request;

class ClientController extends Controller
{
    public function index(Request $request)
    {
        $query = Client::query();

        if ($request->has('search') && !empty($request->search)) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('code', 'like', "%{$search}%")
                  ->orWhere('document_number', 'like', "%{$search}%")
                  ->orWhere('commercial_name', 'like', "%{$search}%");
            });
        }

        if ($request->has('type') && !empty($request->type) && $request->type !== 'Todos') {
            $query->where('type', $request->type);
        }

        if ($request->has('classification') && !empty($request->classification) && $request->classification !== 'Todos') {
            $query->where('classification', $request->classification);
        }

        if ($request->has('active')) {
            $active = $request->active === 'true' || $request->active === '1' || $request->active === true;
            $query->where('active', $active);
        }

        return $query->orderBy('code', 'asc')->get();
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'code' => 'required|string|unique:clients,code',
            'type' => 'required|in:persona_fisica,empresa,gobierno,institucion',
            'name' => 'required|string|max:255',
            'commercial_name' => 'nullable|string|max:255',
            'document_number' => 'nullable|string|max:50',
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
            'credit_limit' => 'nullable|numeric|min:0',
            'credit_days' => 'nullable|integer|min:0',
            'classification' => 'nullable|in:excelente,bueno,regular,riesgoso',
            'active' => 'nullable|boolean',
            'notes' => 'nullable|string',
        ]);

        return Client::create($validated);
    }

    public function show($id)
    {
        return Client::findOrFail($id);
    }

    public function update(Request $request, $id)
    {
        $client = Client::findOrFail($id);

        $validated = $request->validate([
            'code' => 'required|string|unique:clients,code,' . $id,
            'type' => 'required|in:persona_fisica,empresa,gobierno,institucion',
            'name' => 'required|string|max:255',
            'commercial_name' => 'nullable|string|max:255',
            'document_number' => 'nullable|string|max:50',
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
            'credit_limit' => 'nullable|numeric|min:0',
            'credit_days' => 'nullable|integer|min:0',
            'classification' => 'nullable|in:excelente,bueno,regular,riesgoso',
            'active' => 'nullable|boolean',
            'notes' => 'nullable|string',
        ]);

        $client->update($validated);

        return $client;
    }

    public function toggleActive($id)
    {
        $client = Client::findOrFail($id);
        $client->active = !$client->active;
        $client->save();

        return response()->json([
            'message' => 'Estado del cliente actualizado correctamente.',
            'client' => $client
        ]);
    }
}
