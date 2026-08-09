<?php

namespace Database\Seeders;

use App\Models\Notification;
use App\Models\User;
use App\Models\Payment;
use App\Models\Invoice;
use Illuminate\Database\Seeder;
use Carbon\Carbon;

class NotificationSeeder extends Seeder
{
    public function run(): void
    {
        // Ambil semua user warga (bukan admin)
        $wargas = User::where('role', 'user')->get();

        if ($wargas->isEmpty()) {
            $this->command->warn('Tidak ada user warga. Jalankan DemoDataSeeder terlebih dahulu.');
            return;
        }

        $notifications = [];
        $now = Carbon::now();

        foreach ($wargas as $warga) {
            // Ambil 3-5 pembayaran confirmated terakhir milik user ini
            $confirmedPayments = Payment::where('user_id', $warga->id)
                ->where('status', 'confirmated')
                ->with('invoice')
                ->orderByDesc('updated_at')
                ->limit(5)
                ->get();

            foreach ($confirmedPayments as $payment) {
                $readAt = rand(0, 1) ? $payment->updated_at->addHours(rand(1, 72)) : null;
                $notifications[] = [
                    'user_id'    => $warga->id,
                    'type'       => 'payment',
                    'title'      => 'Pembayaran Terkonfirmasi',
                    'body'       => 'Pembayaran ' . $payment->invoice->title . ' Anda telah terkonfirmasi otomatis oleh sistem.',
                    'data'       => json_encode(['payment_id' => $payment->id, 'invoice_id' => $payment->invoice_id]),
                    'read_at'    => $readAt,
                    'created_at' => $payment->updated_at,
                    'updated_at' => $payment->updated_at,
                ];
            }

            // Notifikasi pembayaran ditolak
            $rejectedPayments = Payment::where('user_id', $warga->id)
                ->where('status', 'rejected')
                ->with('invoice')
                ->orderByDesc('updated_at')
                ->limit(2)
                ->get();

            foreach ($rejectedPayments as $payment) {
                $readAt = rand(0, 1) ? $payment->updated_at->addHours(rand(1, 48)) : null;
                $notifications[] = [
                    'user_id'    => $warga->id,
                    'type'       => 'payment',
                    'title'      => 'Pembayaran Ditolak ❌',
                    'body'       => 'Pembayaran ' . $payment->invoice->title . ' Anda ditolak. Alasan: ' . ($payment->notes ?? 'Bukti tidak valid. Silakan kirim ulang.'),
                    'data'       => json_encode(['payment_id' => $payment->id, 'invoice_id' => $payment->invoice_id]),
                    'read_at'    => $readAt,
                    'created_at' => $payment->updated_at,
                    'updated_at' => $payment->updated_at,
                ];
            }

            // Notifikasi tagihan baru (invoice terbaru 2026)
            $recentInvoices = Invoice::where('is_active', true)
                ->whereYear('created_at', 2026)
                ->limit(3)
                ->get();

            foreach ($recentInvoices as $invoice) {
                $createdAt = $invoice->created_at->addMinutes(rand(5, 60));
                $notifications[] = [
                    'user_id'    => $warga->id,
                    'type'       => 'invoice',
                    'title'      => 'Tagihan Baru',
                    'body'       => 'Tagihan baru telah diterbitkan: ' . $invoice->title . '. Segera lakukan pembayaran sebelum ' . ($invoice->deadline ? Carbon::parse($invoice->deadline)->format('d M Y') : 'batas waktu') . '.',
                    'data'       => json_encode(['invoice_id' => $invoice->id]),
                    'read_at'    => rand(0, 1) ? $createdAt->addHours(rand(2, 48)) : null,
                    'created_at' => $createdAt,
                    'updated_at' => $createdAt,
                ];
            }

            

            

            // Notifikasi sistem (selamat datang / pengingat)
            $sysDate = $warga->created_at ?? $now->copy()->subMonths(rand(1, 6));
            $notifications[] = [
                'user_id'    => $warga->id,
                'type'       => 'system',
                'title'      => 'Selamat Datang di ARUSKAS RT!',
                'body'       => 'Halo ' . $warga->name . '! Akun Anda telah aktif. Gunakan aplikasi ini untuk membayar iuran, melihat pengumuman, dan memantau keuangan RT.',
                'data'       => json_encode(['type' => 'welcome']),
                'read_at'    => $sysDate->copy()->addDays(rand(1, 3)),
                'created_at' => $sysDate,
                'updated_at' => $sysDate,
            ];

        }

        // Insert semua notifikasi sekaligus (bulk insert lebih cepat)
        $chunks = array_chunk($notifications, 100);
        foreach ($chunks as $chunk) {
            Notification::insert($chunk);
        }

        $this->command->info('NotificationSeeder selesai: ' . count($notifications) . ' notifikasi dibuat.');
    }
}
