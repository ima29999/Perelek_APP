<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Expense extends Model
{
    use HasFactory;

    protected $fillable = [
        'title', 'category', 'nominal',
        'description', 'date', 'created_by',
    ];

    protected $casts = [
        'nominal' => 'decimal:2',
        'date'    => 'date',
    ];

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
