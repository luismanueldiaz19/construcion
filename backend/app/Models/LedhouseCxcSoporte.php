<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LedhouseCxcSoporte extends Model
{
    protected $fillable = [
        'ledhouse_cxc_id',
        'nota',
        'fecha',
        'fecha_visita',
    ];

    public function cxc()
    {
        return $this->belongsTo(LedhouseCxc::class, 'ledhouse_cxc_id');
    }
}
