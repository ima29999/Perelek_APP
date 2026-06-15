<?php

namespace App\Exceptions;

use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\HttpKernel\Exception\MethodNotAllowedHttpException;
use Throwable;

class Handler extends ExceptionHandler
{
    protected $dontFlash = ['current_password', 'password', 'password_confirmation'];

    public function register(): void
    {
        $this->reportable(function (Throwable $e) {
            //
        });
    }

    public function render($request, Throwable $e)
    {
        // Selalu return JSON untuk API request
        if ($request->is('api/*') || $request->expectsJson()) {

            if ($e instanceof ValidationException) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validasi gagal.',
                    'errors'  => $e->errors(),
                ], 422);
            }

            if ($e instanceof AuthenticationException) {
                return response()->json([
                    'success' => false,
                    'message' => 'Anda belum login atau token tidak valid.',
                ], 401);
            }

            if ($e instanceof NotFoundHttpException) {
                return response()->json([
                    'success' => false,
                    'message' => 'Endpoint atau resource tidak ditemukan.',
                ], 404);
            }

            if ($e instanceof MethodNotAllowedHttpException) {
                return response()->json([
                    'success' => false,
                    'message' => 'Method tidak diizinkan.',
                ], 405);
            }

            if ($e instanceof \Illuminate\Database\Eloquent\ModelNotFoundException) {
                return response()->json([
                    'success' => false,
                    'message' => 'Data tidak ditemukan.',
                ], 404);
            }

            if ($e instanceof \Symfony\Component\HttpKernel\Exception\HttpException) {
                $code = $e->getStatusCode();
                $messages = [
                    403 => 'Akses ditolak.',
                    429 => 'Terlalu banyak permintaan. Coba lagi nanti.',
                    500 => 'Terjadi kesalahan server.',
                ];

                return response()->json([
                    'success' => false,
                    'message' => $messages[$code] ?? $e->getMessage(),
                ], $code);
            }

            // Sembunyikan detail error di production
            if (!config('app.debug')) {
                return response()->json([
                    'success' => false,
                    'message' => 'Terjadi kesalahan internal. Silakan coba lagi.',
                ], 500);
            }

            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'trace'   => collect($e->getTrace())->take(5)->toArray(),
            ], 500);
        }

        return parent::render($request, $e);
    }
}
