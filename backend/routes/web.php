<?php

use Illuminate\Support\Facades\Route;

use Barryvdh\DomPDF\Facade\Pdf;

Route::get('/compras/{id}/print', function ($id) {
    $compra = \App\Models\Compra::with('proveedor', 'proyecto', 'detalles.material')->findOrFail($id);
    $pdf = Pdf::loadView('compras.print', compact('compra'));
    return $pdf->stream('factura_compra_'.$id.'.pdf');
});

Route::get('/gastos/{id}/print', function ($id) {
    $gasto = \App\Models\GastoProyecto::with(['proyecto', 'subpartida', 'proveedor'])->findOrFail($id);
    $pdf = Pdf::loadView('gastos.print', compact('gasto'));
    return $pdf->stream('comprobante_gasto_'.$id.'.pdf');
});

Route::get('/reports/compras/pdf', [\App\Http\Controllers\Api\ReportController::class, 'comprasPdf']);
Route::get('/reports/gastos/pdf', [\App\Http\Controllers\Api\ReportController::class, 'gastosPdf']);
Route::get('/reports/partida/{id}/pdf', [\App\Http\Controllers\Api\ReportController::class, 'partidaPdf']);
Route::get('/reports/proyecto/{id}/pdf', [\App\Http\Controllers\Api\ReportController::class, 'proyectoPdf']);

// =========================================================
// RUTA PARA EL FRONTEND (FLUTTER WEB)
// =========================================================
// Esta ruta atrapa todo lo demás que no sea la API o los PDFs
// y carga la aplicación web de Flutter. Flutter se encarga
// internamente del resto de las rutas en el navegador.
Route::get('/{any}', function () {
    return view('app');
})->where('any', '.*');
