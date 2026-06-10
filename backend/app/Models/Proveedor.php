<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Proveedor extends Model
{
    use SoftDeletes;
    
    protected $table = 'proveedores';
    
    protected $fillable = [
        'code', 'type', 'name', 'commercial_name', 'rnc',
        'contact_name', 'contact_position', 'phone', 'mobile', 'whatsapp', 'email',
        'country', 'province', 'city', 'sector', 'address',
        'allow_credit', 'credit_days', 'credit_limit',
        'bank_name', 'account_number', 'account_type',
        'classification', 'active', 'notes'
    ];

    protected $casts = [
        'allow_credit' => 'boolean',
        'active' => 'boolean',
        'credit_limit' => 'decimal:2',
    ];
}
