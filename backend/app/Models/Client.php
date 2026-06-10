<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Client extends Model
{
    use SoftDeletes;

    protected $table = 'clients';

    protected $fillable = [
        'code',
        'type',
        'name',
        'commercial_name',
        'document_number',
        'contact_name',
        'contact_position',
        'phone',
        'mobile',
        'whatsapp',
        'email',
        'country',
        'province',
        'city',
        'sector',
        'address',
        'credit_limit',
        'credit_days',
        'classification',
        'active',
        'notes'
    ];

    protected $casts = [
        'active' => 'boolean',
        'credit_limit' => 'decimal:2',
        'credit_days' => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime'
    ];
}
