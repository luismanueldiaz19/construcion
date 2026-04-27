<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\GastoProyecto;
use App\Models\CatalogoCuenta;
use App\Models\Proyecto;
use App\Services\AsientoService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class GastoProyectoController extends Controller
{
    protected $asientoService;

    public function __construct(AsientoService $asientoService)
    {
        $this->asientoService = $asientoService;
    }

    public function index(Request $request)
    {
        $query = GastoProyecto::with(['proyecto', 'subpartida', 'proveedor']);
        if ($request->has('proyecto_id')) {
            $query->where('proyecto_id', $request->proyecto_id);
        }
        return $query->latest()->get();
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'proyecto_id' => 'required|exists:proyectos,id',
            'subpartida_id' => 'nullable|exists:subpartidas,id',
            'proveedor_id' => 'nullable|exists:proveedores,id',
            'cuenta_costo_id' => 'nullable|exists:catalogo_cuentas,id',
            'monto' => 'required|numeric|min:0.01',
            'tipo_gasto' => 'required|string', // Mano de Obra, Alquiler, Transporte, Otros
            'descripcion' => 'required|string',
            'fecha' => 'required|date',
            'metodo_pago' => 'required|string', // Efectivo, Transferencia, Cheque, Crédito
            'banco_id' => 'required_unless:metodo_pago,Crédito|nullable|exists:catalogo_cuentas,id',
        ]);

        return DB::transaction(function () use ($validated) {
            $gasto = GastoProyecto::create($validated);

            // 1. Determinar Cuenta de Costo (Usar la enviada o adivinar por tipo)
            if (isset($validated['cuenta_costo_id'])) {
                $cuentaCosto = CatalogoCuenta::find($validated['cuenta_costo_id']);
            } else {
                $codigoCosto = '5.1.02'; // Default Mano de Obra
                if (str_contains(strtolower($validated['tipo_gasto']), 'alquiler')) $codigoCosto = '5.1.03';
                if (str_contains(strtolower($validated['tipo_gasto']), 'transporte')) $codigoCosto = '5.1.04';
                if (str_contains(strtolower($validated['tipo_gasto']), 'otros')) $codigoCosto = '5.1.04';
                $cuentaCosto = CatalogoCuenta::where('codigo', $codigoCosto)->first();
            }
            
            // 2. Determinar Cuenta de Contrapartida (Banco/Caja o Cuentas por Pagar)
            if ($validated['metodo_pago'] == 'Crédito') {
                $cuentaPago = CatalogoCuenta::where('codigo', '2.1.01')->first(); // Cuentas por Pagar
            } else {
                $cuentaPago = CatalogoCuenta::find($validated['banco_id']);
            }

            // 3. Registrar Asiento Contable
            $detalles = [
                [
                    'cuenta_id' => $cuentaCosto->id,
                    'debe' => $validated['monto'],
                    'haber' => 0,
                    'centro_costo_id' => $validated['proyecto_id'],
                    'subpartida_id' => $validated['subpartida_id'],
                ],
                [
                    'cuenta_id' => $cuentaPago->id,
                    'debe' => 0,
                    'haber' => $validated['monto'],
                    'centro_costo_id' => $validated['proyecto_id'],
                ]
            ];

            $this->asientoService->registrarAsiento(
                $validated['fecha'],
                "Gasto de Proyecto ({$validated['tipo_gasto']}): {$validated['descripcion']}",
                $detalles,
                'Gasto'
            );

            return $gasto->load(['proyecto', 'subpartida', 'proveedor']);
        });
    }

    public function destroy(GastoProyecto $gastoProyecto)
    {
        $gastoProyecto->delete();
        return response()->noContent();
    }
}
