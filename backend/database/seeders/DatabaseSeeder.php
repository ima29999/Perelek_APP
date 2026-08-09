<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Urutan pemanggilan seeder PENTING karena ada relasi antar tabel:
     *
     * 1. AdminUserSeeder    → Membuat akun admin (user id=1)
     * 2. DemoDataSeeder     → Membuat 30 warga (per KK) + invoices + payments
     *                         (semua lunas) + events + expenses + faqs untuk
     *                         periode 2024-2026
     * 3. NotificationSeeder → Membuat notifikasi berdasarkan data payment &
     *                         invoice yang sudah ada
     */
    public function run(): void
    {
        $this->call([
            AdminUserSeeder::class,
            DemoDataSeeder::class,
            NotificationSeeder::class,
        ]);
    }
}
