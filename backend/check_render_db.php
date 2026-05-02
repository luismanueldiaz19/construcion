<?php

use App\Models\Proyecto;

require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$p = Proyecto::where('nombre', 'Nuevo')->first();
if ($p) {
    $total = $p->presupuesto_estimado 
           + ($p->itbis ?? 0)
           + ($p->transporte ?? 0)
           + ($p->supervision_tecnica ?? 0)
           + ($p->otros_costos ?? 0);
    
    echo "Proyecto: {$p->nombre} (ID: {$p->id})\n";
    echo "Presupuesto Estimado: {$p->presupuesto_estimado}\n";
    echo "ITBIS: {$p->itbis}\n";
    echo "Transporte: {$p->transporte}\n";
    echo "Total Calculado (Lógica CXC): $total\n";
} else {
    echo "Proyecto 'Nuevo' no encontrado.\n";
}
