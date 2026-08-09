<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Foundation\Support\Providers\RouteServiceProvider as ServiceProvider;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Route;

class RouteServiceProvider extends ServiceProvider
{
    public const HOME = '/dashboard';

    public function boot(): void
    {
        // 1. Jalankan konfigurasi Rate Limiting terlebih dahulu
        $this->configureRateLimiting();

        $this->routes(function () {
            Route::middleware('api')
                ->prefix('api')
                ->group(base_path('routes/api.php'));

            Route::middleware('web')
                ->group(base_path('routes/web.php'));
        });
    }

    /**
     * Konfigurasi pembatasan rate (Rate Limiter) untuk aplikasi.
              */
    protected function configureRateLimiting(): void
    {
        // Kita atur batasnya menjadi 10.000 request per menit khusus masa development
        RateLimiter::for('api', function (Request $request) {
            return Limit::perMinute(10000)->by($request->user()?->id ?: $request->ip());
        });
    }
}