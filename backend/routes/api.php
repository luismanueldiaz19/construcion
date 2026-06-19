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
    Route::apiResource('gastos-proyecto', GastoProyectoController::class);
    Route::get('gastos-proyecto/{id}/pdf', [GastoProyectoController::class, 'imprimirRecibo']);
    Route::post('proyectos/{id}/pago-cliente', [ProyectoController::class, 'pagoCliente']);
    Route::post('proyectos/{id}/provisionar-todo', [ProyectoController::class, 'provisionarTodo']);
    Route::post('proyectos/{id}/logo', [ProyectoController::class, 'uploadLogo']);
    Route::delete('proyectos/{id}/logo', [ProyectoController::class, 'removeLogo']);
    Route::post('proyectos/{id}/partidas', [ProyectoController::class, 'addPartida']);
    Route::post('partidas/{id}/subpartidas', [ProyectoController::class, 'addSubpartida']);
    Route::get('/proyectos/{id}/partidas', [ProyectoController::class, 'partidas']);
    Route::apiResource('materiales', \App\Http\Controllers\Api\MaterialController::class);
    Route::post('materiales/{id}/toggle-estado', [\App\Http\Controllers\Api\MaterialController::class, 'toggleEstado']);
    Route::apiResource('clients', \App\Http\Controllers\Api\ClientController::class)->except(['destroy']);
    Route::post('clients/{id}/toggle-active', [\App\Http\Controllers\Api\ClientController::class, 'toggleActive']);
    Route::apiResource('categorias', \App\Http\Controllers\Api\CategoriaController::class);
    Route::apiResource('inventarios-locales', \App\Http\Controllers\Api\InventarioLocalController::class);
    Route::get('/inventario-proyectos', [InventarioController::class, 'index']);
    Route::get('/inventario-proyectos/{id}', [InventarioController::class, 'show']);
    Route::get('/inventario-proyectos/{id}/pdf', [InventarioController::class, 'downloadPdf']);
    Route::apiResource('compras', CompraController::class);
    Route::get('compras-pendientes', [CompraController::class, 'pendientes']);
    Route::post('/avances', [\App\Http\Controllers\Api\AvanceProyectoController::class, 'store']);
    Route::post('/pagos', [\App\Http\Controllers\Api\PagoClienteController::class, 'store']);
    Route::get('/subpartidas/{id}/avances', [\App\Http\Controllers\Api\AvanceProyectoController::class, 'history']);
    Route::get('/contabilidad/catalogo', [ContabilidadController::class, 'catalogo']);
    Route::get('/contabilidad/asientos', [ContabilidadController::class, 'asientos']);
    Route::get('/contabilidad/bancos', [ContabilidadController::class, 'bancos']);
    Route::get('/contabilidad/estado-resultados', [ContabilidadController::class, 'estadoResultados']);

    // Compras y Proveedores
    Route::apiResource('proveedores', ProveedorController::class);
    Route::post('proveedores/{id}/toggle-active', [ProveedorController::class, 'toggleActive']);
    Route::get('compras/{id}/pdf', [CompraController::class, 'imprimirTicket']);
    Route::post('compras/{id}/documentos', [CompraController::class, 'uploadDocumento']);
    Route::delete('compras/documentos/{id}', [CompraController::class, 'deleteDocumento']);
    Route::post('recepciones', [RecepcionController::class, 'store']);
    Route::apiResource('consumos', ConsumoController::class);
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
});
