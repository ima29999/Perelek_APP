<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Support\Facades\Crypt;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, SoftDeletes;

    protected $fillable = [
        'name', 'email', 'password', 'role',
        'nik', 'phone', 'address', 'rt_rw',
        'ktp_photo', 'profile_photo', 'is_active',
    ];

    protected $hidden = ['password', 'remember_token'];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'password'          => 'hashed',
        'is_active'         => 'boolean',
    ];

    // -------------------------------------------------------------------------
    // AES-256 Encryption for NIK & Phone (sensitif)
    // -------------------------------------------------------------------------

    public function setNikAttribute(?string $value): void
    {
        $this->attributes['nik'] = $value ? Crypt::encryptString($value) : null;
    }

    public function getNikAttribute(?string $value): ?string
    {
        if (!$value) return null;
        try {
            return Crypt::decryptString($value);
        } catch (\Exception $e) {
            return $value; // fallback jika belum terenkripsi
        }
    }

    public function setPhoneAttribute(?string $value): void
    {
        $this->attributes['phone'] = $value ? Crypt::encryptString($value) : null;
    }

    public function getPhoneAttribute(?string $value): ?string
    {
        if (!$value) return null;
        try {
            return Crypt::decryptString($value);
        } catch (\Exception $e) {
            return $value;
        }
    }

    // -------------------------------------------------------------------------
    // Relationships
    // -------------------------------------------------------------------------

    public function invoices()
    {
        return $this->hasMany(Invoice::class, 'created_by');
    }

    public function payments()
    {
        return $this->hasMany(Payment::class, 'user_id');
    }

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }
}
