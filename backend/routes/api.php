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
use App\Http\Controllers\Api\LedhouseCuentaCatalogoController;
use App\Http\Controllers\Api\LedhouseClienteController;
use App\Http\Controllers\Api\LedhouseProveedorController;

use App\Http\Controllers\Api\MaterialController;
use App\Http\Controllers\Api\ClientController;
use App\Http\Controllers\Api\CategoriaController;
use App\Http\Controllers\Api\InventarioLocalController;
use App\Http\Controllers\Api\AvanceProyectoController;
use App\Http\Controllers\Api\PagoClienteController;
use App\Http\Controllers\Api\TransferenciaController;
use App\Http\Controllers\Api\DocumentoController;
use App\Http\Controllers\Api\EmployeeController;
use App\Http\Controllers\Api\EmployeeDependentController;
use App\Http\Controllers\Api\EmployeeDocumentController;
use App\Http\Controllers\Api\NominaCatalogController;
use App\Http\Controllers\Api\PayrollController;
use App\Http\Controllers\Api\PayrollLoanController;
use App\Http\Controllers\Api\NominaExportController;
use App\Http\Controllers\Api\NominaReportController;
use App\Http\Controllers\Api\Accounting\CierreContableController;
use App\Http\Controllers\Api\Accounting\ConciliacionController;

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
    Route::post('materiales/import', [MaterialController::class, 'import']);
    Route::get('materiales/import-template', [MaterialController::class, 'importTemplate']);
    Route::apiResource('materiales', MaterialController::class);
    Route::post('materiales/{id}/toggle-estado', [MaterialController::class, 'toggleEstado']);
    Route::apiResource('clients', ClientController::class)->except(['destroy']);
    Route::post('clients/{id}/toggle-active', [ClientController::class, 'toggleActive']);
    Route::apiResource('categorias', CategoriaController::class);
    Route::apiResource('inventarios-locales', InventarioLocalController::class);
    Route::get('/inventario-proyectos', [InventarioController::class, 'index']);
    Route::get('/inventario-proyectos/{id}', [InventarioController::class, 'show']);
    Route::get('/inventario-proyectos/{id}/pdf', [InventarioController::class, 'downloadPdf']);
    Route::apiResource('compras', CompraController::class)->except(['destroy']);
    Route::delete('compras/{compra}', [CompraController::class, 'destroy'])->middleware('auth:sanctum');
    Route::get('compras-pendientes', [CompraController::class, 'pendientes']);
    Route::post('/avances', [AvanceProyectoController::class, 'store']);
    Route::post('/pagos', [PagoClienteController::class, 'store']);
    Route::delete('/pagos/{id}/comprobante', [PagoClienteController::class, 'deleteComprobante']);
    Route::get('/subpartidas/{id}/avances', [AvanceProyectoController::class, 'history']);
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
    Route::get('/contabilidad/cierres', [CierreContableController::class, 'index']);
    Route::post('/contabilidad/cierres/toggle', [CierreContableController::class, 'toggle']);

    // Conciliaciones Bancarias
    Route::get('/contabilidad/conciliaciones/bancos', [ConciliacionController::class, 'getBancos']);
    Route::get('/contabilidad/conciliaciones/movimientos', [ConciliacionController::class, 'getMovimientos']);
    Route::post('/contabilidad/conciliaciones/guardar', [ConciliacionController::class, 'saveConciliacion']);
    Route::get('/contabilidad/conciliaciones/pdf', [ConciliacionController::class, 'generarPdf']);

    // Compras y Proveedores
    Route::apiResource('proveedores', ProveedorController::class);
    Route::post('proveedores/{id}/toggle-active', [ProveedorController::class, 'toggleActive']);
    Route::get('compras/{id}/pdf', [CompraController::class, 'imprimirTicket']);
    Route::post('compras/{id}/documentos', [CompraController::class, 'uploadDocumento']);
    Route::delete('compras/documentos/{id}', [CompraController::class, 'deleteDocumento']);
    Route::post('recepciones', [RecepcionController::class, 'store']);
    Route::apiResource('consumos', ConsumoController::class)->except(['destroy']);
    Route::delete('consumos/{consumo}', [ConsumoController::class, 'destroy'])->middleware('auth:sanctum');
    Route::post('transferencias', [TransferenciaController::class, 'store']);
    Route::get('cuentas-por-pagar', [PagoCompraController::class, 'index']);
    Route::post('pagos-compras', [PagoCompraController::class, 'store']);
    Route::get('pagos-compras/{id}/pdf', [PagoCompraController::class, 'imprimirRecibo']);
    Route::get('pagos-historial', [PagosController::class, 'index']);
    Route::get('pagos-historial/{tipo}/{id}/pdf', [PagosController::class, 'imprimirRecibo']);
    Route::get('cuentas-por-cobrar', [CuentaPorCobrarController::class, 'index']);
    Route::get('/proyectos/{id}/documentos', [DocumentoController::class, 'index']);
    Route::post('/documentos', [DocumentoController::class, 'store']);
    Route::delete('/documentos/{id}', [DocumentoController::class, 'destroy']);

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
        Route::get('/',              [EmployeeController::class, 'index']);
        Route::post('/',             [EmployeeController::class, 'store']);
        Route::get('/{id}',          [EmployeeController::class, 'show']);
        Route::put('/{id}',          [EmployeeController::class, 'update']);
        Route::delete('/{id}',       [EmployeeController::class, 'destroy']);
        Route::post('/{id}/restore', [EmployeeController::class, 'restore']);

        // Acciones especiales (auditoría obligatoria)
        Route::post('/{id}/change-salary', [EmployeeController::class, 'changeSalary']);
        Route::post('/{id}/change-status', [EmployeeController::class, 'changeStatus']);
        Route::post('/{id}/terminate',     [EmployeeController::class, 'terminate']);

        // Sub-recursos del empleado
        Route::get('/{id}/payroll-history', [EmployeeController::class, 'payrollHistory']);

        // Dependientes
        Route::get('/{id}/dependents',       [EmployeeDependentController::class, 'index']);
        Route::post('/{id}/dependents',      [EmployeeDependentController::class, 'store']);
        Route::delete('/dependents/{depId}', [EmployeeDependentController::class, 'destroy']);

        // Documentos
        Route::get('/{id}/documents',        [EmployeeDocumentController::class, 'index']);
        Route::post('/{id}/documents',       [EmployeeDocumentController::class, 'store']);
        Route::delete('/documents/{docId}',  [EmployeeDocumentController::class, 'destroy']);
    });

    // ── Catálogos de Nómina ────────────────────────────────────────────
    Route::prefix('nomina')->group(function () {
        // Departamentos
        Route::get('/departments',        [NominaCatalogController::class, 'departments']);
        Route::post('/departments',       [NominaCatalogController::class, 'storeDepartment']);
        Route::put('/departments/{id}',   [NominaCatalogController::class, 'updateDepartment']);

        // Cargos / Posiciones
        Route::get('/positions',          [NominaCatalogController::class, 'positions']);
        Route::post('/positions',         [NominaCatalogController::class, 'storePosition']);
        Route::put('/positions/{id}',     [NominaCatalogController::class, 'updatePosition']);

        // Horarios, grupos, referencia
        Route::get('/work-schedules',     [NominaCatalogController::class, 'workSchedules']);
        Route::get('/payroll-groups',     [NominaCatalogController::class, 'payrollGroups']);
        Route::get('/afps',               [NominaCatalogController::class, 'afps']);
        Route::get('/arss',               [NominaCatalogController::class, 'arss']);
        Route::get('/banks',              [NominaCatalogController::class, 'banks']);

        // Conceptos de nómina (CRUD para admin/contador)
        Route::get('/concepts',           [NominaCatalogController::class, 'payrollConcepts']);
        Route::post('/concepts',          [NominaCatalogController::class, 'storePayrollConcept']);

        // Parámetros legales (TSS, ISR, INFOTEP)
        Route::get('/legal-parameters',   [NominaCatalogController::class, 'legalParameters']);

        // Periodos de nómina
        Route::get('/periods',            [NominaCatalogController::class, 'payrollPeriods']);
        Route::post('/periods',           [NominaCatalogController::class, 'storePayrollPeriod']);
        Route::delete('/periods/{id}',    [NominaCatalogController::class, 'destroyPayrollPeriod']);
    });

    // ── Proceso de Nómina ──────────────────────────────────────────────
    Route::prefix('payrolls')->group(function () {
        Route::get('/',                        [PayrollController::class, 'index']);
        Route::post('/',                       [PayrollController::class, 'store']);
        Route::get('/{id}',                    [PayrollController::class, 'show']);
        
        // Flujo de aprobación
        Route::post('/{id}/calculate',         [PayrollController::class, 'calculate']);
        Route::post('/{id}/review',            [PayrollController::class, 'review']);
        Route::post('/{id}/approve',           [PayrollController::class, 'approve']);
        Route::post('/{id}/mark-paid',         [PayrollController::class, 'markPaid']);
        Route::post('/{id}/close',             [PayrollController::class, 'close']);
        Route::delete('/{id}/force-delete',    [PayrollController::class, 'forceDelete']);

        // Empleados y desgloses
        Route::get('/{id}/employee-summary',   [PayrollController::class, 'employeeSummary']);
        Route::get('/{id}/vouchers/pdf',       [PayrollController::class, 'downloadVouchersPdf']);
        Route::get('/{id}/employee/{empId}',   [PayrollController::class, 'employeeDetail']);
        Route::put('/details/{detailId}',      [PayrollController::class, 'updateDetail']);
    });

    // ── Préstamos y Adelantos ──────────────────────────────────────────
    Route::prefix('payroll-loans')->group(function () {
        Route::get('/',           [PayrollLoanController::class, 'index']);
        Route::post('/',          [PayrollLoanController::class, 'store']);
        Route::get('/{id}',       [PayrollLoanController::class, 'show']);
        Route::put('/{id}',       [PayrollLoanController::class, 'update']);
        Route::delete('/{id}',    [PayrollLoanController::class, 'destroy']);
    });

    // ── Exportaciones Excel (Tarea 09) ─────────────────────────────────
    Route::prefix('nomina/export')->group(function () {
        Route::get('/nomina-consolidada', [NominaExportController::class, 'nominaConsolidada']);
        Route::get('/planilla-tss',       [NominaExportController::class, 'planillaTSS']);
        Route::get('/historial-salarios', [NominaExportController::class, 'historialSalarios']);
        Route::get('/retenciones-isr',    [NominaExportController::class, 'retencionesISR']);
        Route::get('/provisiones',        [NominaExportController::class, 'provisiones']);
        Route::get('/kardex',             [NominaExportController::class, 'kardex']);
    });

    // ── Vistas UI Reportes (JSON) ───────────────────────────────────────
    Route::prefix('nomina/reports')->group(function () {
        Route::get('/nomina-consolidada', [NominaReportController::class, 'nominaConsolidada']);
        Route::get('/planilla-tss',       [NominaReportController::class, 'planillaTSS']);
        Route::get('/retenciones-isr',    [NominaReportController::class, 'retencionesISR']);
        Route::get('/provisiones',        [NominaReportController::class, 'provisiones']);
        Route::get('/historial-salarios', [NominaReportController::class, 'historialSalarios']);
    });

    // ── MÓDULO LED-HOUSE ───────────────────────────────────────────────
    Route::prefix('ledhouse')->group(function () {
        Route::get('/estado-resultado/matriz', [LedhouseEstadoResultadoController::class, 'matriz']);
        Route::get('/estado-resultado/matriz-pdf', [LedhouseEstadoResultadoController::class, 'generateMatrizPdf']);
        Route::get('/estado-resultado/pdf', [LedhouseEstadoResultadoController::class, 'generatePdf']);
        Route::get('/estado-resultado', [LedhouseEstadoResultadoController::class, 'index']);
        Route::get('/estado-resultado/summary', [LedhouseEstadoResultadoController::class, 'summary']);
        Route::post('/estado-resultado', [LedhouseEstadoResultadoController::class, 'store']);
        Route::put('/estado-resultado/{id}', [LedhouseEstadoResultadoController::class, 'update']);
        Route::delete('/estado-resultado/{id}', [LedhouseEstadoResultadoController::class, 'destroy']);
        Route::post('/estado-resultado/import', [LedhouseEstadoResultadoController::class, 'import']);

        // CXP
        Route::apiResource('cxp', LedhouseCxpController::class);

        // CXC
        Route::get('cxc/grouped', [LedhouseCxcController::class, 'groupedByCliente']);
        Route::post('cxc/import-by-cliente/{cliente_id}', [LedhouseCxcController::class, 'importByCliente']);
        Route::apiResource('cxc', LedhouseCxcController::class);
        Route::post('cxc/{cxc}/soporte', [LedhouseCxcController::class, 'addSoporte']);
        Route::get('cxc/{cxc}/soporte', [LedhouseCxcController::class, 'getSoportes']);

        // Cuentas de Catalogo
        Route::post('cuentas-catalogo/import', [LedhouseCuentaCatalogoController::class, 'import']);
        Route::apiResource('cuentas-catalogo', LedhouseCuentaCatalogoController::class);

        // Clientes
        Route::post('clientes/import', [LedhouseClienteController::class, 'import']);
        Route::apiResource('clientes', LedhouseClienteController::class);

        // Proveedores
        Route::apiResource('proveedores', LedhouseProveedorController::class);
    });
});


