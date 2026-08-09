<?php

use App\Http\Controllers\Api\AiChatController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\EventController;
use App\Http\Controllers\Api\ExpenseController;
use App\Http\Controllers\Api\FaqController;
use App\Http\Controllers\Api\GuidanceController;
use App\Http\Controllers\Api\InvoiceController;
use App\Http\Controllers\Api\MidtransController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\PublicController;          // ← BARU
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\UserController;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;

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

// Webhook server-to-server dari Midtrans. WAJIB publik (tanpa auth:sanctum)
// karena yang memanggil endpoint ini adalah server Midtrans, bukan user login.
// Keamanan dijaga lewat verifikasi signature_key di MidtransController::notification().
Route::post('webhooks/midtrans', [MidtransController::class, 'notification']);

// Test endpoint API untuk memastikan backend berjalan dengan benar
Route::get('/test', function () {
    return response()->json([
        'message' => 'Hello from Laravel Docker'
    ]);
});

Route::get('storage/{path}', function ($path) {
    $fullPath = storage_path('app/public/' . $path);
    if (!file_exists($fullPath)) {
        abort(404);
    }

    $mime = mime_content_type($fullPath) ?: 'application/octet-stream';
    return response()->file($fullPath, [
        'Content-Type' => $mime,
        'Access-Control-Allow-Origin' => '*',
    ]);
})->where('path', '.*');

// ============================================================================
// Public endpoints untuk halaman Landing (tanpa login)            ← BARU
// ============================================================================
Route::prefix('public')->group(function () {
    Route::get('transparency',  [PublicController::class, 'transparency']);
    Route::get('events',        [PublicController::class, 'events']);
});

// ============================================================================
// Warga (auth required)
// ============================================================================
Route::middleware(['auth:sanctum'])->group(function () {

    // Dashboard warga
    Route::get('dashboard', [DashboardController::class, 'user']);

    // Asisten chat AI (Google AI Studio / Gemini) - bisa dipakai warga & admin
    Route::post('ai/chat', [AiChatController::class, 'chat']);

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

    // Pembayaran online via Midtrans
    Route::post('payments/midtrans/charge',         [MidtransController::class, 'charge']);
    Route::get ('payments/midtrans/{payment}/status',[MidtransController::class, 'status']);

    // Laporan personal
    Route::get('reports/personal', [ReportController::class, 'personal']);

    // Laporan warga ke admin (realtime, muncul di Notifikasi admin)
    Route::post('reports/submit', [NotificationController::class, 'submitReport']);

    // Transparansi (publik tapi perlu login agar lebih detail)
    Route::get('reports/transparency', [ReportController::class, 'transparency']);


    //notifications
    // PENTING: route 'read-all' harus SEBELUM '{notification}/read'
    // agar Laravel tidak mengira string "read-all" adalah sebuah {id}
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::patch('/notifications/read-all', [NotificationController::class, 'markAllRead']);
    Route::patch('/notifications/{notification}/read', [NotificationController::class, 'markRead']);
});

// ============================================================================
// Admin only
// ============================================================================
Route::middleware(['auth:sanctum', 'role:admin'])->prefix('admin')->group(function () {

    // Dashboard admin
    Route::get('dashboard', [DashboardController::class, 'admin']);

    // Manajemen Warga
    Route::apiResource('users', UserController::class);
    Route::patch('users/{user}/activate', [UserController::class, 'activate']);

    // Toggle tombol "Bayar" per-warga (independen dari is_active akun)
    Route::patch('users/{user}/disable-payment', [UserController::class, 'disablePayment']);
    Route::patch('users/{user}/enable-payment',  [UserController::class, 'enablePayment']);

    // Tagihan
    Route::apiResource('invoices', InvoiceController::class);

    // Pembayaran admin
    Route::get  ('payments',                 [PaymentController::class, 'adminIndex']);
    

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

Route::get('/profile-photo/{filename}', function ($filename) {
    $path = 'profile_photos/' . $filename;
    
    if (!Storage::disk('public')->exists($path)) {
        abort(404);
    }
    
    $file = Storage::disk('public')->get($path);
    $fullPath = storage_path('app/public/' . $path);
    $type = mime_content_type($fullPath); 
    
    return response($file, 200)->header('Content-Type', $type);
});