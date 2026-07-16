<?php

namespace App\Http\Controllers\Api\Accounting;

use App\Http\Controllers\Controller;
use App\Models\CierreContable;
use App\Services\CierreContableService;
use Illuminate\Http\Request;

class CierreContableController extends Controller
{
    protected $cierreService;

    public function __construct(CierreContableService $cierreService)
    {
        $this->cierreService = $cierreService;
    }

    public function index(Request $request)
    {
        $anio = $request->query('anio', date('Y'));
        
        $cierres = CierreContable::where('anio', $anio)->get()->keyBy('mes');
        
        $meses = [];
        $nombres = [
            1 => 'Enero', 2 => 'Febrero', 3 => 'Marzo', 4 => 'Abril',
            5 => 'Mayo', 6 => 'Junio', 7 => 'Julio', 8 => 'Agosto',
            9 => 'Septiembre', 10 => 'Octubre', 11 => 'Noviembre', 12 => 'Diciembre'
        ];

        for ($i = 1; $i <= 12; $i++) {
            $estado = isset($cierres[$i]) ? $cierres[$i]->estado : 'abierto';
            $meses[] = [
                'mes' => $i,
                'nombre' => $nombres[$i],
                'estado' => $estado
            ];
        }

        return response()->json($meses);
    }

    public function toggle(Request $request)
    {
        $request->validate([
            'anio' => 'required|integer',
            'mes' => 'required|integer|min:1|max:12',
            'estado' => 'required|in:abierto,cerrado'
        ]);

        $cierre = CierreContable::firstOrCreate(
            ['anio' => $request->anio, 'mes' => $request->mes]
        );

        $cierre->estado = $request->estado;
        
        if ($request->estado === 'cerrado') {
            $cierre->cerrado_por = auth()->id() ?? 1; // Fallback for testing
            $cierre->cerrado_el = now();
        } else {
            $cierre->cerrado_por = null;
            $cierre->cerrado_el = null;
        }
        
        $cierre->save();

        return response()->json([
            'message' => "Mes {$request->mes} marcado como {$request->estado}",
            'cierre' => $cierre
        ]);
    }
}
