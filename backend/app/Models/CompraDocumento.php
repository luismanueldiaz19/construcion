<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CompraDocumento extends Model
{
    protected $fillable = [
        'compra_id',
        'file_path',
        'file_type',
        'original_name',
    ];

    public function compra()
    {
        return $this->belongsTo(Compra::class);
    }
}
