<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
| Semua UI dihandle oleh frontend (React/Vue).
| Backend hanya menyediakan REST API.
| Route ini hanya untuk health-check dan fallback.
|--------------------------------------------------------------------------
*/

Route::get('/', function () {
    return response()->json([
        'app'     => config('app.name'),
        'version' => '1.0.0',
        'status'  => 'running',
        'docs'    => 'Gunakan /api/* untuk mengakses API',
    ]);
});

Route::get('/health', function () {
    try {
        \DB::connection()->getPdo();
        $db = 'connected';
    } catch (\Exception $e) {
        $db = 'error: ' . $e->getMessage();
    }

    return response()->json([
        'status'   => 'ok',
        'database' => $db,
        'time'     => now()->toDateTimeString(),
    ]);
});
