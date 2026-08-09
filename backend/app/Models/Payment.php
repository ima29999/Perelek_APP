<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Payment extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'invoice_id', 'user_id', 'amount',
        'payment_date', 'method', 'proof_path',
        'status', 'notes', 'verified_by',
        // Midtrans / online payment
        'channel', 'order_id', 'snap_token', 'gateway_status', 'paid_at',
    ];

    protected function serializeDate(\DateTimeInterface $date)
    {
        return $date->format('d-m-Y');
    }

    protected $casts = [
        'payment_date' => 'date',
        'amount'       => 'decimal:2',
        'paid_at'      => 'datetime',
    ];

    /**
     * True jika pembayaran ini dibuat lewat payment gateway (Midtrans),
     * false jika lewat upload bukti manual.
     */
    public function isOnline(): bool
    {
        return $this->channel === 'midtrans';
    }

    public function invoice()
    {
        return $this->belongsTo(Invoice::class, 'invoice_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function verifier()
    {
        return $this->belongsTo(User::class, 'verified_by');
    }
}
