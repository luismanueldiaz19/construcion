<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PayrollLoan;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class PayrollLoanController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $loans = PayrollLoan::with('employee')
            ->when($request->employee_id, fn($q, $id) => $q->where('employee_id', $id))
            ->when($request->status, fn($q, $s) => $q->where('status', $s))
            ->orderByDesc('created_at')
            ->paginate(20);
        return response()->json($loans);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'employee_id'        => 'required|exists:employees,id',
            'loan_type'          => 'required|in:prestamo,adelanto,embargo_judicial,cuota_sindical,otro',
            'original_amount'    => 'required|numeric|min:1',
            'monthly_installment'=> 'required|numeric|min:1',
            'total_installments' => 'nullable|integer|min:1',
            'start_date'         => 'required|date',
            'description'        => 'nullable|string',
        ]);

        $data['outstanding_balance']   = $data['original_amount'];
        $data['remaining_installments'] = $data['total_installments'] ?? null;
        $data['status']                = 'activo';
        $data['approved_by']           = auth()->id();
        $data['approved_at']           = now();

        $loan = PayrollLoan::create($data);
        return response()->json($loan->load('employee'), 201);
    }

    public function show(int $id): JsonResponse
    {
        return response()->json(PayrollLoan::with('employee')->findOrFail($id));
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $loan = PayrollLoan::findOrFail($id);
        $data = $request->validate([
            'monthly_installment' => 'sometimes|numeric|min:0',
            'status'              => 'sometimes|in:activo,pagado,cancelado',
            'description'         => 'nullable|string',
        ]);
        $loan->update($data);
        return response()->json($loan);
    }

    public function destroy(int $id): JsonResponse
    {
        $loan = PayrollLoan::findOrFail($id);
        $loan->update(['status' => 'cancelado']);
        $loan->delete();
        return response()->json(['message' => 'Préstamo cancelado y archivado.']);
    }
}
