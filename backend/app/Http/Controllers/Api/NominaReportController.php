<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use App\Services\NominaReportService;

class NominaReportController extends Controller
{
    private NominaReportService $reportService;

    public function __construct(NominaReportService $reportService)
    {
        $this->reportService = $reportService;
    }

    /**
     * Endpoint JSON para la Nómina Consolidada.
     */
    public function nominaConsolidada(Request $request): JsonResponse
    {
        $request->validate([
            'payroll_id' => 'required|exists:payrolls,id',
        ]);

        $data = $this->reportService->getNominaConsolidada($request->payroll_id);

        return response()->json($data);
    }

    /**
     * Endpoint JSON para Planilla TSS.
     */
    public function planillaTSS(Request $request): JsonResponse
    {
        $request->validate([
            'payroll_id' => 'required|exists:payrolls,id',
        ]);

        $data = $this->reportService->getPlanillaTSS($request->payroll_id);

        return response()->json($data);
    }

    /**
     * Endpoint JSON para Retenciones ISR.
     */
    public function retencionesISR(Request $request): JsonResponse
    {
        $request->validate([
            'payroll_id' => 'required|exists:payrolls,id',
        ]);

        $data = $this->reportService->getRetencionesISR($request->payroll_id);

        return response()->json($data);
    }

    /**
     * Endpoint JSON para Provisiones Acumuladas.
     */
    public function provisiones(Request $request): JsonResponse
    {
        $request->validate([
            'from' => 'required|date',
            'to'   => 'required|date|after_or_equal:from',
        ]);

        $data = $this->reportService->getProvisiones($request->from, $request->to);

        return response()->json($data);
    }

    /**
     * Endpoint JSON para Historial Salarios.
     */
    public function historialSalarios(Request $request): JsonResponse
    {
        $data = $this->reportService->getHistorialSalarios(
            $request->employee_id,
            $request->from,
            $request->to
        );

        return response()->json($data);
    }
}
