<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\EventController;
use App\Http\Controllers\ExpenseController;
use App\Http\Controllers\FaqController;
use App\Http\Controllers\GuidanceController;
use App\Http\Controllers\InvoiceController;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\UserController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('auth/login', function () {
    return response()->json([
        'message' => 'Gunakan POST /api/auth/login atau POST /api/login dengan payload identifier dan password.',
        'example' => [
            'identifier' => 'admin@perelek.local',
            'password' => 'password123',
        ],
    ]);
});

Route::post('auth/login', [AuthController::class, 'login']);
Route::post('login', [AuthController::class, 'login']);
Route::post('auth/forgot-password', [AuthController::class, 'forgotPassword']);
Route::post('auth/reset-password', [AuthController::class, 'resetPassword']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('auth/logout', [AuthController::class, 'logout']);
    Route::post('auth/refresh', [AuthController::class, 'refresh']);
    Route::get('auth/me', [AuthController::class, 'me']);

    Route::get('dashboard', [DashboardController::class, 'user']);
    Route::get('guidance', [GuidanceController::class, 'index']);
    Route::get('faqs', [FaqController::class, 'index']);
    Route::get('events', [EventController::class, 'index']);
    Route::get('invoices', [InvoiceController::class, 'index']);
    Route::get('payments/my', [PaymentController::class, 'index']);
    Route::post('payments', [PaymentController::class, 'store']);
    Route::get('payments/{payment}', [PaymentController::class, 'show']);
    Route::delete('payments/{payment}', [PaymentController::class, 'destroy']);
    Route::get('reports/personal', [ReportController::class, 'personal']);
    Route::get('profile', [UserController::class, 'profile']);
    Route::patch('profile', [UserController::class, 'updateProfile']);

    Route::middleware('role:admin')->group(function () {
        Route::apiResource('admin/users', UserController::class)->except(['create', 'edit']);
        Route::apiResource('admin/invoices', InvoiceController::class)->except(['create', 'edit']);
        Route::apiResource('admin/expenses', ExpenseController::class)->except(['create', 'edit']);
        Route::apiResource('admin/events', EventController::class)->except(['create', 'edit']);
        Route::apiResource('admin/faqs', FaqController::class)->except(['create', 'edit']);
        Route::get('admin/payments', [PaymentController::class, 'index']);
        Route::patch('admin/payments/{payment}/verify', [PaymentController::class, 'verify']);
        Route::get('admin/reports/financial', [ReportController::class, 'financial']);
        Route::get('admin/reports/arrears', [ReportController::class, 'arrears']);
        Route::get('admin/dashboard', [DashboardController::class, 'admin']);
    });
});
