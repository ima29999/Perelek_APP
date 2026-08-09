<?php

namespace App\Console;

use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;

class Kernel extends ConsoleKernel
{
    protected function schedule(Schedule $schedule): void
    {
        // Backup otomatis harian pukul 02:00
        $schedule->command('backup:run')->dailyAt('02:00');

        // Bersihkan log lama (>30 hari)
        $schedule->command('backup:clean')->daily();

        // Jaring pengaman: cek ulang pembayaran Midtrans yang masih pending
        // tiap menit, supaya saldo/status tetap ter-update otomatis walau
        // webhook Midtrans gagal/tidak sampai (mis. server tidak reachable
        // dari internet saat development). Lihat docblock lengkap di
        // App\Console\Commands\SyncMidtransPayments.
        //
        // CATATAN DEPLOYMENT: scheduler Laravel butuh satu entri cron yang
        // memanggil `php artisan schedule:run` tiap menit di server (lihat
        // https://laravel.com/docs/10.x/scheduling#running-the-scheduler).
        // Tanpa cron itu terpasang, jalankan manual saat perlu:
        //   php artisan payments:sync-midtrans
        $schedule->command('payments:sync-midtrans')
            ->everyMinute()
            ->withoutOverlapping();
    }

    protected function commands(): void
    {
        $this->load(__DIR__ . '/Commands');
        require base_path('routes/console.php');
    }
}
