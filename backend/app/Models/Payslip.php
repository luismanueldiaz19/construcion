<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Payslip extends Model
{
    protected $fillable = [
        'payroll_id',
        'employee_id',
        'pdf_path',
        'email_sent',
        'email_sent_at',
    ];

    protected $casts = [
        'email_sent'    => 'boolean',
        'email_sent_at' => 'datetime',
    ];

    public function payroll(): BelongsTo
    {
        return $this->belongsTo(Payroll::class);
    }

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class);
    }
}
