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

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::prefix('v1')->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'index']);
    Route::apiResource('proyectos', ProyectoController::class);
    Route::apiResource('gastos-proyecto', GastoProyectoController::class);
    Route::post('proyectos/{id}/pago-cliente', [ProyectoController::class, 'pagoCliente']);
    Route::post('proyectos/{id}/provisionar-todo', [ProyectoController::class, 'provisionarTodo']);
    Route::get('/proyectos/{id}/partidas', [ProyectoController::class, 'partidas']);
    Route::apiResource('materiales', \App\Http\Controllers\Api\MaterialController::class);
    Route::get('/inventario-proyectos', [InventarioController::class, 'index']);
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
    Route::post('recepciones', [RecepcionController::class, 'store']);
    Route::post('consumos', [ConsumoController::class, 'store']);
});
