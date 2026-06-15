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
    }

    protected function commands(): void
    {
        $this->load(__DIR__ . '/Commands');
        require base_path('routes/console.php');
    }
}
