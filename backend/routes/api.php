<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\ProyectoController;
use App\Http\Controllers\Api\ContabilidadController;
use App\Http\Controllers\Api\ProveedorController;
use App\Http\Controllers\Api\CompraController;
use App\Http\Controllers\Api\RecepcionController;
use App\Http\Controllers\Api\InventarioController;
use App\Http\Controllers\Api\ConsumoController;
use App\Http\Controllers\Api\GastoProyectoController;
use App\Http\Controllers\Api\PagoCompraController;
use App\Http\Controllers\Api\PagosController;
use App\Http\Controllers\Api\CuentaPorCobrarController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\AssetController;
use App\Http\Controllers\Api\AssetCategoryController;
use App\Http\Controllers\Api\AssetExpenseController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\LedhouseEstadoResultadoController;
use App\Http\Controllers\Api\LedhouseCxpController;
use App\Http\Controllers\Api\LedhouseCxcController;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::prefix('v1')->group(function () {
    Route::apiResource('assets', AssetController::class);
    Route::apiResource('asset-categories', AssetCategoryController::class);
    Route::apiResource('asset-expenses', AssetExpenseController::class);
    Route::apiResource('users', UserController::class);

    Route::post('register', [AuthController::class, 'register']);
    Route::post('login', [AuthController::class, 'login']);
    Route::middleware('auth:sanctum')->post('logout', [AuthController::class, 'logout']);

    Route::get('/dashboard', [DashboardController::class, 'index']);
    Route::apiResource('proyectos', ProyectoController::class);
    Route::apiResource('gastos-proyecto', GastoProyectoController::class)->except(['destroy']);
    Route::delete('gastos-proyecto/{gastoProyecto}', [GastoProyectoController::class, 'destroy'])->middleware('auth:sanctum');
    Route::get('gastos-proyecto/{id}/pdf', [GastoProyectoController::class, 'imprimirRecibo']);
    Route::post('proyectos/{id}/pago-cliente', [ProyectoController::class, 'pagoCliente']);
    Route::post('proyectos/{id}/logo', [ProyectoController::class, 'uploadLogo']);
    Route::delete('proyectos/{id}/logo', [ProyectoController::class, 'removeLogo']);
    Route::post('proyectos/{id}/partidas', [ProyectoController::class, 'addPartida']);
    Route::post('partidas/{id}/subpartidas', [ProyectoController::class, 'addSubpartida']);
    Route::get('/proyectos/{id}/partidas', [ProyectoController::class, 'partidas']);
    Route::post('materiales/import', [\App\Http\Controllers\Api\MaterialController::class, 'import']);
    Route::get('materiales/import-template', [\App\Http\Controllers\Api\MaterialController::class, 'importTemplate']);
    Route::apiResource('materiales', \App\Http\Controllers\Api\MaterialController::class);
    Route::post('materiales/{id}/toggle-estado', [\App\Http\Controllers\Api\MaterialController::class, 'toggleEstado']);
    Route::apiResource('clients', \App\Http\Controllers\Api\ClientController::class)->except(['destroy']);
    Route::post('clients/{id}/toggle-active', [\App\Http\Controllers\Api\ClientController::class, 'toggleActive']);
    Route::apiResource('categorias', \App\Http\Controllers\Api\CategoriaController::class);
    Route::apiResource('inventarios-locales', \App\Http\Controllers\Api\InventarioLocalController::class);
    Route::get('/inventario-proyectos', [InventarioController::class, 'index']);
    Route::get('/inventario-proyectos/{id}', [InventarioController::class, 'show']);
    Route::get('/inventario-proyectos/{id}/pdf', [InventarioController::class, 'downloadPdf']);
    Route::apiResource('compras', CompraController::class)->except(['destroy']);
    Route::delete('compras/{compra}', [CompraController::class, 'destroy'])->middleware('auth:sanctum');
    Route::get('compras-pendientes', [CompraController::class, 'pendientes']);
    Route::post('/avances', [\App\Http\Controllers\Api\AvanceProyectoController::class, 'store']);
    Route::post('/pagos', [\App\Http\Controllers\Api\PagoClienteController::class, 'store']);
    Route::delete('/pagos/{id}/comprobante', [\App\Http\Controllers\Api\PagoClienteController::class, 'deleteComprobante']);
    Route::get('/subpartidas/{id}/avances', [\App\Http\Controllers\Api\AvanceProyectoController::class, 'history']);
    Route::get('/contabilidad/catalogo', [ContabilidadController::class, 'catalogo']);
    Route::get('/contabilidad/asientos', [ContabilidadController::class, 'asientos']);
    Route::delete('/contabilidad/asientos/{id}', [ContabilidadController::class, 'destroyAsiento'])->middleware('auth:sanctum');
    Route::get('/contabilidad/bancos', [ContabilidadController::class, 'bancos']);
    Route::get('/contabilidad/estado-resultados', [ContabilidadController::class, 'estadoResultados']);
    Route::get('/contabilidad/obligaciones', [ContabilidadController::class, 'obligaciones']);
    Route::post('/contabilidad/obligaciones/pagar', [ContabilidadController::class, 'pagarObligacion']);
    Route::get('/contabilidad/obligaciones/historial', [ContabilidadController::class, 'historialPagosObligaciones']);
    Route::get('/contabilidad/obligaciones/historial/pdf', [ContabilidadController::class, 'historialPagosObligacionesPdf']);

    // Cierres Contables
    Route::get('/contabilidad/cierres', [\App\Http\Controllers\Api\Accounting\CierreContableController::class, 'index']);
    Route::post('/contabilidad/cierres/toggle', [\App\Http\Controllers\Api\Accounting\CierreContableController::class, 'toggle']);

    // Conciliaciones Bancarias
    Route::get('/contabilidad/conciliaciones/bancos', [\App\Http\Controllers\Api\Accounting\ConciliacionController::class, 'getBancos']);
    Route::get('/contabilidad/conciliaciones/movimientos', [\App\Http\Controllers\Api\Accounting\ConciliacionController::class, 'getMovimientos']);
    Route::post('/contabilidad/conciliaciones/guardar', [\App\Http\Controllers\Api\Accounting\ConciliacionController::class, 'saveConciliacion']);
    Route::get('/contabilidad/conciliaciones/pdf', [\App\Http\Controllers\Api\Accounting\ConciliacionController::class, 'generarPdf']);

    // Compras y Proveedores
    Route::apiResource('proveedores', ProveedorController::class);
    Route::post('proveedores/{id}/toggle-active', [ProveedorController::class, 'toggleActive']);
    Route::get('compras/{id}/pdf', [CompraController::class, 'imprimirTicket']);
    Route::post('compras/{id}/documentos', [CompraController::class, 'uploadDocumento']);
    Route::delete('compras/documentos/{id}', [CompraController::class, 'deleteDocumento']);
    Route::post('recepciones', [RecepcionController::class, 'store']);
    Route::apiResource('consumos', ConsumoController::class)->except(['destroy']);
    Route::delete('consumos/{consumo}', [ConsumoController::class, 'destroy'])->middleware('auth:sanctum');
    Route::post('transferencias', [\App\Http\Controllers\Api\TransferenciaController::class, 'store']);
    Route::get('cuentas-por-pagar', [PagoCompraController::class, 'index']);
    Route::post('pagos-compras', [PagoCompraController::class, 'store']);
    Route::get('pagos-compras/{id}/pdf', [PagoCompraController::class, 'imprimirRecibo']);
    Route::get('pagos-historial', [PagosController::class, 'index']);
    Route::get('pagos-historial/{tipo}/{id}/pdf', [PagosController::class, 'imprimirRecibo']);
    Route::get('cuentas-por-cobrar', [CuentaPorCobrarController::class, 'index']);
    Route::get('/proyectos/{id}/documentos', [\App\Http\Controllers\Api\DocumentoController::class, 'index']);
    Route::post('/documentos', [\App\Http\Controllers\Api\DocumentoController::class, 'store']);
    Route::delete('/documentos/{id}', [\App\Http\Controllers\Api\DocumentoController::class, 'destroy']);

    Route::get('/file', function (Request $request) {
        $path = $request->query('path');
        if (!$path) abort(404);
        $fullPath = storage_path('app/public/' . $path);
        if (!file_exists($fullPath)) abort(404);
        return response()->file($fullPath);
    });

    // ═══════════════════════════════════════════════════════════════════
    // MÓDULO DE NÓMINA — Empleados y Sistema de Nómina
    // Legislación: República Dominicana (Código de Trabajo, Ley 87-01)
    // ═══════════════════════════════════════════════════════════════════

    // ── Empleados ──────────────────────────────────────────────────────
    Route::prefix('employees')->group(function () {
        Route::get('/',              [\App\Http\Controllers\Api\EmployeeController::class, 'index']);
        Route::post('/',             [\App\Http\Controllers\Api\EmployeeController::class, 'store']);
        Route::get('/{id}',          [\App\Http\Controllers\Api\EmployeeController::class, 'show']);
        Route::put('/{id}',          [\App\Http\Controllers\Api\EmployeeController::class, 'update']);
        Route::delete('/{id}',       [\App\Http\Controllers\Api\EmployeeController::class, 'destroy']);
        Route::post('/{id}/restore', [\App\Http\Controllers\Api\EmployeeController::class, 'restore']);

        // Acciones especiales (auditoría obligatoria)
        Route::post('/{id}/change-salary', [\App\Http\Controllers\Api\EmployeeController::class, 'changeSalary']);
        Route::post('/{id}/change-status', [\App\Http\Controllers\Api\EmployeeController::class, 'changeStatus']);
        Route::post('/{id}/terminate',     [\App\Http\Controllers\Api\EmployeeController::class, 'terminate']);

        // Sub-recursos del empleado
        Route::get('/{id}/payroll-history', [\App\Http\Controllers\Api\EmployeeController::class, 'payrollHistory']);

        // Dependientes
        Route::get('/{id}/dependents',       [\App\Http\Controllers\Api\EmployeeDependentController::class, 'index']);
        Route::post('/{id}/dependents',      [\App\Http\Controllers\Api\EmployeeDependentController::class, 'store']);
        Route::delete('/dependents/{depId}', [\App\Http\Controllers\Api\EmployeeDependentController::class, 'destroy']);

        // Documentos
        Route::get('/{id}/documents',        [\App\Http\Controllers\Api\EmployeeDocumentController::class, 'index']);
        Route::post('/{id}/documents',       [\App\Http\Controllers\Api\EmployeeDocumentController::class, 'store']);
        Route::delete('/documents/{docId}',  [\App\Http\Controllers\Api\EmployeeDocumentController::class, 'destroy']);
    });

    // ── Catálogos de Nómina ────────────────────────────────────────────
    Route::prefix('nomina')->group(function () {
        // Departamentos
        Route::get('/departments',        [\App\Http\Controllers\Api\NominaCatalogController::class, 'departments']);
        Route::post('/departments',       [\App\Http\Controllers\Api\NominaCatalogController::class, 'storeDepartment']);
        Route::put('/departments/{id}',   [\App\Http\Controllers\Api\NominaCatalogController::class, 'updateDepartment']);

        // Cargos / Posiciones
        Route::get('/positions',          [\App\Http\Controllers\Api\NominaCatalogController::class, 'positions']);
        Route::post('/positions',         [\App\Http\Controllers\Api\NominaCatalogController::class, 'storePosition']);
        Route::put('/positions/{id}',     [\App\Http\Controllers\Api\NominaCatalogController::class, 'updatePosition']);

        // Horarios, grupos, referencia
        Route::get('/work-schedules',     [\App\Http\Controllers\Api\NominaCatalogController::class, 'workSchedules']);
        Route::get('/payroll-groups',     [\App\Http\Controllers\Api\NominaCatalogController::class, 'payrollGroups']);
        Route::get('/afps',               [\App\Http\Controllers\Api\NominaCatalogController::class, 'afps']);
        Route::get('/arss',               [\App\Http\Controllers\Api\NominaCatalogController::class, 'arss']);
        Route::get('/banks',              [\App\Http\Controllers\Api\NominaCatalogController::class, 'banks']);

        // Conceptos de nómina (CRUD para admin/contador)
        Route::get('/concepts',           [\App\Http\Controllers\Api\NominaCatalogController::class, 'payrollConcepts']);
        Route::post('/concepts',          [\App\Http\Controllers\Api\NominaCatalogController::class, 'storePayrollConcept']);

        // Parámetros legales (TSS, ISR, INFOTEP)
        Route::get('/legal-parameters',   [\App\Http\Controllers\Api\NominaCatalogController::class, 'legalParameters']);

        // Periodos de nómina
        Route::get('/periods',            [\App\Http\Controllers\Api\NominaCatalogController::class, 'payrollPeriods']);
        Route::post('/periods',           [\App\Http\Controllers\Api\NominaCatalogController::class, 'storePayrollPeriod']);
        Route::delete('/periods/{id}',    [\App\Http\Controllers\Api\NominaCatalogController::class, 'destroyPayrollPeriod']);
    });

    // ── Proceso de Nómina ──────────────────────────────────────────────
    Route::prefix('payrolls')->group(function () {
        Route::get('/',                        [\App\Http\Controllers\Api\PayrollController::class, 'index']);
        Route::post('/',                       [\App\Http\Controllers\Api\PayrollController::class, 'store']);
        Route::get('/{id}',                    [\App\Http\Controllers\Api\PayrollController::class, 'show']);
        
        // Flujo de aprobación
        Route::post('/{id}/calculate',         [\App\Http\Controllers\Api\PayrollController::class, 'calculate']);
        Route::post('/{id}/review',            [\App\Http\Controllers\Api\PayrollController::class, 'review']);
        Route::post('/{id}/approve',           [\App\Http\Controllers\Api\PayrollController::class, 'approve']);
        Route::post('/{id}/mark-paid',         [\App\Http\Controllers\Api\PayrollController::class, 'markPaid']);
        Route::post('/{id}/close',             [\App\Http\Controllers\Api\PayrollController::class, 'close']);
        Route::delete('/{id}/force-delete',    [\App\Http\Controllers\Api\PayrollController::class, 'forceDelete']);

        // Empleados y desgloses
        Route::get('/{id}/employee-summary',   [\App\Http\Controllers\Api\PayrollController::class, 'employeeSummary']);
        Route::get('/{id}/vouchers/pdf',       [\App\Http\Controllers\Api\PayrollController::class, 'downloadVouchersPdf']);
        Route::get('/{id}/employee/{empId}',   [\App\Http\Controllers\Api\PayrollController::class, 'employeeDetail']);
        Route::put('/details/{detailId}',      [\App\Http\Controllers\Api\PayrollController::class, 'updateDetail']);
    });

    // ── Préstamos y Adelantos ──────────────────────────────────────────
    Route::prefix('payroll-loans')->group(function () {
        Route::get('/',           [\App\Http\Controllers\Api\PayrollLoanController::class, 'index']);
        Route::post('/',          [\App\Http\Controllers\Api\PayrollLoanController::class, 'store']);
        Route::get('/{id}',       [\App\Http\Controllers\Api\PayrollLoanController::class, 'show']);
        Route::put('/{id}',       [\App\Http\Controllers\Api\PayrollLoanController::class, 'update']);
        Route::delete('/{id}',    [\App\Http\Controllers\Api\PayrollLoanController::class, 'destroy']);
    });

    // ── Exportaciones Excel (Tarea 09) ─────────────────────────────────
    Route::prefix('nomina/export')->group(function () {
        Route::get('/nomina-consolidada', [\App\Http\Controllers\Api\NominaExportController::class, 'nominaConsolidada']);
        Route::get('/planilla-tss',       [\App\Http\Controllers\Api\NominaExportController::class, 'planillaTSS']);
        Route::get('/historial-salarios', [\App\Http\Controllers\Api\NominaExportController::class, 'historialSalarios']);
        Route::get('/retenciones-isr',    [\App\Http\Controllers\Api\NominaExportController::class, 'retencionesISR']);
        Route::get('/provisiones',        [\App\Http\Controllers\Api\NominaExportController::class, 'provisiones']);
        Route::get('/kardex',             [\App\Http\Controllers\Api\NominaExportController::class, 'kardex']);
    });

    // ── Vistas UI Reportes (JSON) ───────────────────────────────────────
    Route::prefix('nomina/reports')->group(function () {
        Route::get('/nomina-consolidada', [\App\Http\Controllers\Api\NominaReportController::class, 'nominaConsolidada']);
        Route::get('/planilla-tss',       [\App\Http\Controllers\Api\NominaReportController::class, 'planillaTSS']);
        Route::get('/retenciones-isr',    [\App\Http\Controllers\Api\NominaReportController::class, 'retencionesISR']);
        Route::get('/provisiones',        [\App\Http\Controllers\Api\NominaReportController::class, 'provisiones']);
        Route::get('/historial-salarios', [\App\Http\Controllers\Api\NominaReportController::class, 'historialSalarios']);
    });

    // ── MÓDULO LED-HOUSE ───────────────────────────────────────────────
    Route::prefix('ledhouse')->group(function () {
        Route::get('/estado-resultado', [LedhouseEstadoResultadoController::class, 'index']);
        Route::get('/estado-resultado/summary', [LedhouseEstadoResultadoController::class, 'summary']);
        Route::post('/estado-resultado', [LedhouseEstadoResultadoController::class, 'store']);
        Route::post('/estado-resultado/import', [LedhouseEstadoResultadoController::class, 'import']);

        // CXP
        Route::apiResource('cxp', LedhouseCxpController::class);

        // CXC
        Route::apiResource('cxc', LedhouseCxcController::class);
        Route::post('cxc/{cxc}/soporte', [LedhouseCxcController::class, 'addSoporte']);
        Route::get('cxc/{cxc}/soporte', [LedhouseCxcController::class, 'getSoportes']);
    });
});
