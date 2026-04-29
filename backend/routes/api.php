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

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::prefix('v1')->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'index']);
    Route::apiResource('proyectos', ProyectoController::class);
    Route::apiResource('gastos-proyecto', GastoProyectoController::class);
    Route::post('proyectos/{id}/pago-cliente', [ProyectoController::class, 'pagoCliente']);
    Route::post('proyectos/{id}/provisionar-todo', [ProyectoController::class, 'provisionarTodo']);
    Route::post('proyectos/{id}/logo', [ProyectoController::class, 'uploadLogo']);
    Route::delete('proyectos/{id}/logo', [ProyectoController::class, 'removeLogo']);
    Route::post('proyectos/{id}/partidas', [ProyectoController::class, 'addPartida']);
    Route::post('partidas/{id}/subpartidas', [ProyectoController::class, 'addSubpartida']);
    Route::get('/proyectos/{id}/partidas', [ProyectoController::class, 'partidas']);
    Route::apiResource('materiales', \App\Http\Controllers\Api\MaterialController::class);
    Route::post('materiales/{id}/toggle-estado', [\App\Http\Controllers\Api\MaterialController::class, 'toggleEstado']);
    Route::apiResource('categorias', \App\Http\Controllers\Api\CategoriaController::class);
    Route::get('/inventario-proyectos', [InventarioController::class, 'index']);
    Route::get('/inventario-proyectos/{id}', [InventarioController::class, 'show']);
    Route::get('/inventario-proyectos/{id}/pdf', [InventarioController::class, 'downloadPdf']);
    Route::apiResource('compras', \App\Http\Controllers\Api\CompraController::class);
    Route::post('/avances', [\App\Http\Controllers\Api\AvanceProyectoController::class, 'store']);
    Route::post('/pagos', [\App\Http\Controllers\Api\PagoClienteController::class, 'store']);
    Route::get('/subpartidas/{id}/avances', [\App\Http\Controllers\Api\AvanceProyectoController::class, 'history']);
    Route::get('/contabilidad/catalogo', [ContabilidadController::class, 'catalogo']);
    Route::get('/contabilidad/asientos', [ContabilidadController::class, 'asientos']);
    Route::get('/contabilidad/bancos', [ContabilidadController::class, 'bancos']);
    Route::get('/contabilidad/estado-resultados', [ContabilidadController::class, 'estadoResultados']);

    // Compras y Proveedores
    Route::apiResource('proveedores', ProveedorController::class);
    Route::apiResource('compras', CompraController::class);
    Route::get('compras/{id}/pdf', [CompraController::class, 'imprimirTicket']);
    Route::post('recepciones', [RecepcionController::class, 'store']);
    Route::apiResource('consumos', ConsumoController::class);
    Route::get('cuentas-por-pagar', [PagoCompraController::class, 'index']);
    Route::post('pagos-compras', [PagoCompraController::class, 'store']);
    Route::get('pagos-compras/{id}/pdf', [PagoCompraController::class, 'imprimirRecibo']);
    Route::get('pagos-historial', [PagosController::class, 'index']);
    Route::get('pagos-historial/{tipo}/{id}/pdf', [PagosController::class, 'imprimirRecibo']);
    Route::get('cuentas-por-cobrar', [CuentaPorCobrarController::class, 'index']);
    Route::get('/proyectos/{id}/documentos', [\App\Http\Controllers\Api\DocumentoController::class, 'index']);
    Route::post('/documentos', [\App\Http\Controllers\Api\DocumentoController::class, 'store']);
    Route::delete('/documentos/{id}', [\App\Http\Controllers\Api\DocumentoController::class, 'destroy']);
});
