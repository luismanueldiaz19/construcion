<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class LedhouseCliente extends Model
{
    use HasFactory;

    protected $fillable = [
        'nombre',
        'whatsapp',
        'direccion',
        'limite_credito',
        'dias_credito'
    ];

    public function cxcs()
    {
        return $this->hasMany(LedhouseCxc::class, 'cliente_id');
    }
}
