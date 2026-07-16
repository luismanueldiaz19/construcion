<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CierreContable extends Model
{
    use HasFactory;

    protected $table = 'cierres_contables';

    protected $fillable = [
        'anio',
        'mes',
        'estado',
        'cerrado_por',
        'cerrado_el'
    ];

    protected $casts = [
        'cerrado_el' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'cerrado_por');
    }
}
