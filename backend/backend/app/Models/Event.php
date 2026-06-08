<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\User;

class Event extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'description',
        'location',
        'event_date',
        'event_time',
        'notify_h1',
        'notify_h0',
        'created_by',
        'is_active',
    ];

    protected $casts = [
        'event_date' => 'date',
        'notify_h1' => 'boolean',
        'notify_h0' => 'boolean',
        'is_active' => 'boolean',
    ];

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
