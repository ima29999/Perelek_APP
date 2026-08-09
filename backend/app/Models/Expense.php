<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

class Expense extends Model
{
    use HasFactory;

    protected $fillable = [
        'title', 'category', 'nominal',
        'description', 'date', 'image', 'created_by',
    ];

    protected $casts = [
        'nominal' => 'decimal:2',
        'date'    => 'datetime',
    ];

    protected $appends = ['image_url'];

    public function getImageUrlAttribute()
    {
        if ($this->image) {
            return url('/api/storage/' . ltrim($this->image, '/'));
        }
        return null;
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}