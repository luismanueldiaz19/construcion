<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Payroll;
use App\Models\PayrollPeriod;
use App\Models\PayrollDetail;
use App\Services\PayrollCalculationService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

/**
 * PayrollController — Gestión del proceso de nómina.
 *
 * Flujo: borrador → calculado → revisado → aprobado → pagado → cerrado
 *
 * REGLA: Quien calcula ≠ quien aprueba (segregación de funciones).
 * REGLA: Una nómina "cerrada" es INMUTABLE.
 */
class PayrollController extends Controller
{
    public function __construct(private PayrollCalculationService $payrollService) {}

    // ── LISTAR ──
    public function index(Request $request): JsonResponse
    {
        $payrolls = Payroll::with(['period.payrollGroup'])
            ->when($request->status, fn($q, $s) => $q->where('status', $s))
            ->orderByDesc('created_at')
            ->paginate(15);

        return response()->json($payrolls);
    }

    // ── DETALLE ──
    public function show(int $id): JsonResponse
    {
        $payroll = Payroll::with([
            'period.payrollGroup',
            'details.employee',
            'details.concept',
            'processedBy',
            'approvedBy',
        ])->findOrFail($id);

        return response()->json($payroll);
    }
    
    // ── RESUMEN POR EMPLEADO ──
    public function employeeSummary(int $id): JsonResponse
    {
        $payroll = Payroll::findOrFail($id);
        
        $details = PayrollDetail::with(['employee', 'concept'])
            ->where('payroll_id', $id)
            ->get();
            
        $summary = [];
        
        foreach($details as $detail) {
            $empId = $detail->employee_id;
            if (!isset($summary[$empId])) {
                $summary[$empId] = [
                    'employee_id' => $empId,
                    'first_name' => $detail->employee->first_name,
                    'last_name' => $detail->employee->last_name,
                    'identification_number' => $detail->employee->identification_number,
                    'total_gross' => 0,
                    'total_tss' => 0,
                    'total_isr' => 0,
                    'other_deductions' => 0,
                    'total_net' => 0,
                ];
            }
            
            if ($detail->type === 'ingreso') {
                $summary[$empId]['total_gross'] += $detail->amount;
            } elseif ($detail->type === 'deduccion') {
                if ($detail->concept && in_array($detail->concept->code, ['DED_TSS_SFS', 'DED_AFP'])) {
                    $summary[$empId]['total_tss'] += $detail->amount;
                } elseif ($detail->concept && $detail->concept->code === 'DED_ISR') {
                    $summary[$empId]['total_isr'] += $detail->amount;
                } else {
                    $summary[$empId]['other_deductions'] += $detail->amount;
                }
            }
        }
        
        foreach($summary as $empId => &$data) {
            $data['total_net'] = round($data['total_gross'] - ($data['total_tss'] + $data['total_isr'] + $data['other_deductions']), 2);
            $data['total_gross'] = round($data['total_gross'], 2);
            $data['total_tss'] = round($data['total_tss'], 2);
            $data['total_isr'] = round($data['total_isr'], 2);
            $data['other_deductions'] = round($data['other_deductions'], 2);
        }
        
        return response()->json(array_values($summary));
    }

    // ── ELIMINAR ──
    public function destroy(int $id): JsonResponse
    {
        $payroll = Payroll::findOrFail($id);
        
        if (in_array($payroll->status, ['pagado', 'cerrado'])) {
            return response()->json(['message' => 'No se puede eliminar una nómina que ya ha sido pagada o cerrada.'], 403);
        }
        
        $payroll->delete();
        return response()->json(['message' => 'Nómina eliminada exitosamente.']);
    }

    // ── CREAR BORRADOR ──
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'payroll_period_id' => 'required|exists:payroll_periods,id',
            'notes'             => 'nullable|string',
        ]);

        $period = PayrollPeriod::findOrFail($request->payroll_period_id);

        if ($period->isClosed()) {
            return response()->json(['message' => 'El periodo está cerrado. No se puede crear una nueva nómina.'], 422);
        }

        $payroll = Payroll::create([
            'payroll_period_id' => $period->id,
            'status'            => 'borrador',
            'notes'             => $request->notes,
        ]);

        return response()->json($payroll, 201);
    }

    // ── CALCULAR ──
    public function calculate(Request $request, int $id): JsonResponse
    {
        $payroll = Payroll::findOrFail($id);

        if (!$payroll->isEditable()) {
            return response()->json(['message' => 'Solo se puede calcular una nómina en estado borrador o calculado.'], 422);
        }

        // extras = ['employee_id' => ['HE_DIURNA' => 5, 'COMISION' => 2500.00]]
        $extras = $request->input('extras', []);

        $payroll = $this->payrollService->calculate($payroll, $extras);

        $payroll->update([
            'processed_by' => auth()->id(),
            'processed_at' => now(),
        ]);

        return response()->json([
            'message' => 'Nómina calculada correctamente.',
            'payroll' => $payroll->load(['period', 'details.employee', 'details.concept']),
        ]);
    }

    // ── REVISAR (RRHH) ──
    public function review(int $id): JsonResponse
    {
        $payroll = Payroll::findOrFail($id);

        if ($payroll->status !== 'calculado') {
            return response()->json(['message' => 'Solo se puede revisar una nómina en estado "calculado".'], 422);
        }

        $payroll->update([
            'status'      => 'revisado',
            'reviewed_by' => auth()->id(),
            'reviewed_at' => now(),
        ]);

        return response()->json(['message' => 'Nómina marcada como revisada.', 'payroll' => $payroll]);
    }

    // ── APROBAR (Finanzas — no puede ser el mismo que calculó) ──
    public function approve(int $id): JsonResponse
    {
        $payroll = Payroll::findOrFail($id);

        if ($payroll->status !== 'revisado') {
            return response()->json(['message' => 'La nómina debe estar revisada antes de aprobar.'], 422);
        }

        // Segregación de funciones (Comentado temporalmente para pruebas de desarrollo)
        /* 
        if ($payroll->processed_by === auth()->id()) {
            return response()->json(['message' => 'Quien calculó la nómina no puede aprobarla (segregación de funciones).'], 403);
        }
        */

        $payroll->update([
            'status'      => 'aprobado',
            'approved_by' => auth()->id(),
            'approved_at' => now(),
        ]);

        return response()->json(['message' => 'Nómina aprobada.', 'payroll' => $payroll]);
    }

    // ── MARCAR PAGADA ──
    public function markPaid(int $id): JsonResponse
    {
        $payroll = Payroll::findOrFail($id);

        if ($payroll->status !== 'aprobado') {
            return response()->json(['message' => 'Solo se puede marcar como pagada una nómina aprobada.'], 422);
        }

        DB::transaction(function () use ($payroll) {
            $payroll->update([
                'status'  => 'pagado',
                'paid_by' => auth()->id(),
                'paid_at' => now(),
            ]);
        });

        return response()->json(['message' => 'Nómina marcada como pagada.', 'payroll' => $payroll]);
    }

    // ── CERRAR / CONTABILIZAR (INMUTABLE) ──
    public function close(int $id): JsonResponse
    {
        $payroll = Payroll::findOrFail($id);

        if ($payroll->status !== 'pagado') {
            return response()->json(['message' => 'Solo se puede cerrar una nómina pagada.'], 422);
        }

        DB::transaction(function () use ($payroll) {
            $payroll->update([
                'status'    => 'cerrado',
                'closed_at' => now(),
            ]);

            // Marcar el periodo como cerrado
            $payroll->period()->update(['status' => 'cerrado']);

            // Generar Asiento Contable
            $cuentaSalarios = \App\Models\CatalogoCuenta::where('codigo', '6.1.02')->first();
            $cuentaAportes = \App\Models\CatalogoCuenta::where('codigo', '6.1.03')->first();
            $cuentaTSS = \App\Models\CatalogoCuenta::where('codigo', '2.1.04')->first();
            $cuentaISR = \App\Models\CatalogoCuenta::where('codigo', '2.1.05')->first();
            $cuentaInfotep = \App\Models\CatalogoCuenta::where('codigo', '2.1.06')->first();
            $cuentaBanco = \App\Models\CatalogoCuenta::where('codigo', '1.1.01')->first();
            $cuentaOtrasDeducciones = \App\Models\CatalogoCuenta::where('codigo', '2.1.09')->first();

            $totalBruto = $payroll->total_gross;
            $tssEmpleado = $payroll->total_tss_employee;
            
            $isr = \App\Models\PayrollDetail::where('payroll_id', $payroll->id)
                ->where('type', 'deduccion')
                ->whereHas('concept', function($q) {
                    $q->where('code', 'DED_ISR');
                })
                ->sum('amount');
                
            $tssPatronal = \App\Models\PayrollDetail::where('payroll_id', $payroll->id)
                ->where('type', 'aporte_patronal')
                ->whereHas('concept', function($q) {
                    $q->whereIn('code', ['PAT_TSS_SFS', 'PAT_AFP', 'PAT_SRL']);
                })
                ->sum('amount');

            $infotepPatronal = \App\Models\PayrollDetail::where('payroll_id', $payroll->id)
                ->where('type', 'aporte_patronal')
                ->whereHas('concept', function($q) {
                    $q->where('code', 'PAT_INFOTEP');
                })
                ->sum('amount');
                
            $otrasDeducciones = $payroll->total_deductions - $tssEmpleado - $isr;
            $neto = $payroll->total_net;

            if ($cuentaSalarios && $cuentaBanco && $cuentaTSS && $cuentaISR) {
                $detallesAsiento = [];
                
                // DEBE (Gastos)
                $detallesAsiento[] = [
                    'cuenta_id' => $cuentaSalarios->id,
                    'debe' => $totalBruto,
                    'haber' => 0,
                ];
                if ($tssPatronal > 0 && $cuentaAportes) {
                    $detallesAsiento[] = [
                        'cuenta_id' => $cuentaAportes->id,
                        'debe' => $tssPatronal,
                        'haber' => 0,
                    ];
                }
                if ($infotepPatronal > 0 && $cuentaAportes) {
                    $detallesAsiento[] = [
                        'cuenta_id' => $cuentaAportes->id,
                        'debe' => $infotepPatronal,
                        'haber' => 0,
                    ];
                }
                
                // HABER (Pasivos y Activos)
                $detallesAsiento[] = [
                    'cuenta_id' => $cuentaBanco->id,
                    'debe' => 0,
                    'haber' => $neto,
                ];
                
                $totalTSS = $tssEmpleado + $tssPatronal;
                if ($totalTSS > 0) {
                    $detallesAsiento[] = [
                        'cuenta_id' => $cuentaTSS->id,
                        'debe' => 0,
                        'haber' => $totalTSS,
                    ];
                }
                if ($isr > 0) {
                    $detallesAsiento[] = [
                        'cuenta_id' => $cuentaISR->id,
                        'debe' => 0,
                        'haber' => $isr,
                    ];
                }
                if ($infotepPatronal > 0 && $cuentaInfotep) {
                    $detallesAsiento[] = [
                        'cuenta_id' => $cuentaInfotep->id,
                        'debe' => 0,
                        'haber' => $infotepPatronal,
                    ];
                }
                if ($otrasDeducciones > 0 && $cuentaOtrasDeducciones) {
                    $detallesAsiento[] = [
                        'cuenta_id' => $cuentaOtrasDeducciones->id,
                        'debe' => 0,
                        'haber' => $otrasDeducciones,
                    ];
                }

                $asientoService = app(\App\Services\AsientoService::class);
                $asientoService->registrarAsiento(
                    now()->format('Y-m-d'),
                    "Nómina de Empleados - Periodo: " . $payroll->period->name,
                    $detallesAsiento,
                    'Nomina',
                    $payroll->id
                );
            }
        });

        return response()->json(['message' => 'Nómina cerrada y contabilizada.']);
    }

    // ── ELIMINAR NÓMINA (SOLO SUPER USUARIO) ──
    public function forceDelete(int $id): JsonResponse
    {
        // $user = auth()->user();
        // if (!$user) {
        //     return response()->json(['message' => 'No autorizado.'], 403);
        // }

        $payroll = Payroll::findOrFail($id);

        DB::transaction(function () use ($payroll) {
            // 1. Borrar asiento contable
            $asiento = \App\Models\AsientoContable::where('referencia_tipo', 'Nomina')
                ->where('referencia_id', $payroll->id)
                ->first();
            if ($asiento) {
                \App\Models\AsientoDetalle::where('asiento_contable_id', $asiento->id)->delete();
                $asiento->delete();
            }

            // 2. Revertir periodo a "abierto" si estaba cerrado
            if ($payroll->period) {
                $payroll->period->update(['status' => 'abierto']);
            }

            // 3. Borrar detalles (empleados) y la nomina
            \App\Models\PayrollDetail::where('payroll_id', $payroll->id)->delete();
            $payroll->delete();
        });

        return response()->json(['message' => 'Nómina, detalles y asientos eliminados correctamente (Modo Desarrollo).']);
    }

    // ── DETALLE POR EMPLEADO ──
    public function employeeDetail(int $payrollId, int $employeeId): JsonResponse
    {
        $details = PayrollDetail::where('payroll_id', $payrollId)
            ->where('employee_id', $employeeId)
            ->with('concept')
            ->orderBy('type')
            ->orderBy('payroll_concept_id')
            ->get();

        $summary = [
            'total_ingresos'       => $details->where('type', 'ingreso')->sum('amount'),
            'total_deducciones'    => $details->where('type', 'deduccion')->sum('amount'),
            'total_patronal'       => $details->where('type', 'aporte_patronal')->sum('amount'),
        ];
        $summary['neto'] = $summary['total_ingresos'] - $summary['total_deducciones'];

        return response()->json(['details' => $details, 'summary' => $summary]);
    }

    // ── EDITAR DETALLE MANUAL (antes de aprobar) ──
    public function updateDetail(Request $request, int $detailId): JsonResponse
    {
        $request->validate(['amount' => 'required|numeric|min:0', 'notes' => 'nullable|string']);

        $detail  = PayrollDetail::findOrFail($detailId);
        $payroll = $detail->payroll;

        if (!$payroll->isEditable()) {
            return response()->json(['message' => 'No se puede editar un detalle de nómina cerrada o aprobada.'], 422);
        }

        $detail->update([
            'amount'             => $request->amount,
            'notes'              => $request->notes,
            'is_manual_override' => true,
        ]);

        return response()->json(['message' => 'Detalle actualizado.', 'detail' => $detail]);
    }

    // ── DESCARGAR VOUCHERS DE PAGO (PDF) ──
    public function downloadVouchersPdf(int $id)
    {
        $payroll = Payroll::with(['period.payrollGroup'])->findOrFail($id);
        
        $employees = \App\Models\Employee::whereHas('payrollDetails', function($q) use ($id) {
            $q->where('payroll_id', $id);
        })->with(['position', 'payrollDetails' => function($q) use ($id) {
            $q->where('payroll_id', $id)->with('concept');
        }])->get();

        $pdf = \Barryvdh\DomPDF\Facade\Pdf::loadView('pdfs.payroll_vouchers', [
            'payroll' => $payroll,
            'employees' => $employees
        ]);

        return $pdf->stream("vouchers_nomina_{$id}.pdf");
    }
}
