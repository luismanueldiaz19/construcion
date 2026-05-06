<?php

use App\Models\Compra;
use App\Models\Recepcion;
use App\Models\RecepcionDetalle;
use Illuminate\Support\Facades\DB;

require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

DB::transaction(function() {
    $compras = Compra::where('estado', 'Recibido')->get();
    echo "Encontradas " . $compras->count() . " compras recibidas.\n";

    foreach ($compras as $compra) {
        // Buscar o crear la recepción
        $recepcion = Recepcion::firstOrCreate(
            ['compra_id' => $compra->id],
            [
                'fecha' => $compra->fecha,
                'recibido_por' => 'Migración Sistema',
                'observaciones' => 'Generado automáticamente por actualización de sistema de historial parcial.'
            ]
        );

        echo "Procesando historial para Compra #{$compra->id}...\n";
        
        foreach ($compra->detalles as $detalle) {
            // Crear detalle si no existe
            RecepcionDetalle::firstOrCreate(
                [
                    'recepcion_id' => $recepcion->id,
                    'compra_detalle_id' => $detalle->id
                ],
                ['cantidad_entregada' => $detalle->cantidad]
            );
            
            // Asegurar que el campo cantidad_recibida esté actualizado
            $detalle->update(['cantidad_recibida' => $detalle->cantidad]);
        }
    }
});

echo "Migración de historial completada.\n";
