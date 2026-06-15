<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\EventController;
use App\Http\Controllers\Api\ExpenseController;
use App\Http\Controllers\Api\FaqController;
use App\Http\Controllers\Api\GuidanceController;
use App\Http\Controllers\Api\InvoiceController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\UserController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes - Perelek Backend
|--------------------------------------------------------------------------
|
| Format respons selalu JSON:
| { "success": true/false, "message": "...", "data": {...} }
|
*/

// ============================================================================
// Auth (Public)
// ============================================================================
Route::prefix('auth')->group(function () {
    Route::post('login',          [AuthController::class, 'login']);
    Route::post('forgot-password',[AuthController::class, 'forgotPassword']);
    Route::post('reset-password', [AuthController::class, 'resetPassword']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::get ('me',      [AuthController::class, 'me']);
        Route::post('logout',  [AuthController::class, 'logout']);
        Route::post('refresh', [AuthController::class, 'refresh']);
    });
});

// Fallback login alias
Route::post('login', [AuthController::class, 'login']);

// ============================================================================
// Public endpoints (tidak perlu login)
// ============================================================================
Route::get('faqs',     [FaqController::class, 'index']);
Route::get('guidance', [GuidanceController::class, 'index']);
Route::get('events',   [EventController::class, 'index']);
// Test endpoint API untuk memastikan backend berjalan dengan benar
Route::get('/test', function () {
    return response()->json([
        'message' => 'Hello from Laravel Docker'
    ]);
});
// ============================================================================
// Warga (auth required)
// ============================================================================
Route::middleware(['auth:sanctum'])->group(function () {

    // Dashboard warga
    Route::get('dashboard', [DashboardController::class, 'user']);

    // Profil
    Route::get  ('profile', [UserController::class, 'profile']);
    Route::patch('profile', [UserController::class, 'updateProfile']);

    // Tagihan (lihat)
    Route::get('invoices', [InvoiceController::class, 'index']);

    // Pembayaran
    Route::get ('payments/my',        [PaymentController::class, 'index']);
    Route::post ('payments',           [PaymentController::class, 'store']);
    Route::get  ('payments/{payment}', [PaymentController::class, 'show']);
    Route::delete('payments/{payment}',[PaymentController::class, 'destroy']);

    // Laporan personal
    Route::get('reports/personal', [ReportController::class, 'personal']);

    // Transparansi (publik tapi perlu login agar lebih detail)
    Route::get('reports/transparency', [ReportController::class, 'transparency']);
});

// ============================================================================
// Admin only
// ============================================================================
Route::middleware(['auth:sanctum', 'role:admin'])->prefix('admin')->group(function () {

    // Dashboard admin
    Route::get('dashboard', [DashboardController::class, 'admin']);

    // Manajemen Warga
    Route::apiResource('users', UserController::class);

    // Tagihan
    Route::apiResource('invoices', InvoiceController::class);

    // Pembayaran admin
    Route::get  ('payments',                 [PaymentController::class, 'adminIndex']);
    Route::patch('payments/{payment}/verify',[PaymentController::class, 'verify']);

    // Pengeluaran
    Route::apiResource('expenses', ExpenseController::class);

    // Kegiatan / Kalender
    Route::apiResource('events', EventController::class);

    // FAQ & Panduan
    Route::apiResource('faqs', FaqController::class);

    // Laporan
    Route::get('reports/financial',    [ReportController::class, 'financial']);
    Route::get('reports/arrears',      [ReportController::class, 'arrears']);
    Route::get('reports/transparency', [ReportController::class, 'transparency']);
});
