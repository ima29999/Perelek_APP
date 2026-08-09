<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Invoice extends Model
{
    use HasFactory;

    protected $fillable = [
        'title', 'description', 'nominal',
        'period', 'deadline', 'created_by', 'is_active',
    ];

protected function serializeDate(\DateTimeInterface $date)
    {
        return $date->format('d-m-Y'); // Hasil di Dart nanti langsung: "05-01-2026"
    }

    protected $casts = [
        'deadline'  => 'date',
        'nominal'   => 'decimal:2',
        'is_active' => 'boolean',
    ];

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function payments()
    {
        return $this->hasMany(Payment::class, 'invoice_id');
    }

    /**
     * Cek apakah warga tertentu sudah membayar invoice ini
     */
    public function isPaidByUser(int $userId): bool
    {
        return $this->payments()
            ->where('user_id', $userId)
            ->whereIn('status', ['confirmated'])
            ->exists();
    }
}
