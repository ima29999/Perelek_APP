<?php

namespace App\Console\Commands;

use App\Services\MidtransService;
use Illuminate\Console\Command;

/**
 * php artisan payments:sync-midtrans
 *
 * KENAPA COMMAND INI DIBUTUHKAN
 * ------------------------------
 * Status pembayaran Midtrans SEHARUSNYA otomatis ter-update lewat webhook
 * (POST /api/webhooks/midtrans) begitu Midtrans selesai memproses transaksi.
 * Tapi webhook itu server-to-server: server Midtrans harus bisa MENGHUBUNGI
 * balik URL backend kita. Di banyak kasus dunia nyata itu gagal diam-diam:
 *
 *   - Development/testing di localhost (mis. http://localhost:8000) —
 *     server Midtrans di internet TIDAK BISA menjangkau localhost sama
 *     sekali, jadi webhook tidak akan pernah terpanggil.
 *   - Payment Notification URL di dashboard Midtrans belum/salah diisi.
 *   - Webhook sempat gagal (server down/deploy) tepat saat notifikasi
 *     dikirim, dan tidak ada yang menyadarinya.
 *
 * Sebelumnya, satu-satunya jaring pengaman kalau webhook gagal adalah
 * polling singkat di frontend (10 detik setelah checkout) DAN sinkronisasi
 * "on-demand" yang hanya berjalan saat seseorang kebetulan membuka halaman
 * tertentu (dashboard, daftar tagihan, daftar pembayaran). Kalau tidak ada
 * yang membuka halaman itu, pembayaran yang SUDAH SUKSES di Midtrans bisa
 * nyangkut selamanya berstatus 'pending' di sistem kita — persis gejala
 * yang dilaporkan: uang warga tidak pernah masuk ke saldo admin.
 *
 * Command ini jadi jaring pengaman terakhir yang tidak bergantung pada
 * siapapun membuka aplikasi: dijadwalkan berjalan tiap menit (lihat
 * app/Console/Kernel.php), mengecek ULANG semua pembayaran Midtrans yang
 * masih 'pending' langsung ke Midtrans (Get Status API, sumber kebenaran
 * resmi), lalu mengonfirmasi/menolaknya secara otomatis — tanpa keterlibatan
 * admin sama sekali, konsisten dengan alur "otomatis terkonfirmasi" yang
 * sudah dipakai di seluruh aplikasi ini.
 *
 * Jalankan manual kapan saja untuk mengecek langsung tanpa menunggu jadwal:
 *   php artisan payments:sync-midtrans
 */
class SyncMidtransPayments extends Command
{
    protected $signature = 'payments:sync-midtrans';

    protected $description = 'Sinkronkan ulang semua pembayaran Midtrans yang masih pending ke status terbaru di Midtrans (jaring pengaman kalau webhook tidak sampai, mis. saat development di localhost).';

    public function handle(MidtransService $midtrans): int
    {
        $this->info('Mengecek pembayaran Midtrans yang masih pending...');

        $result = $midtrans->diagnosePendingPayments();

        if ($result['total_checked'] === 0) {
            $this->info('Tidak ada pembayaran dengan channel Midtrans berstatus pending di database. '
                . 'Kalau di aplikasi masih terlihat "Menunggu Konfirmasi", berarti pembayaran itu sudah '
                . 'BUKAN status pending lagi di database (sudah confirmated/rejected) dan kemungkinan itu '
                . 'sekadar tampilan lama/cache di layar — buka lagi halamannya atau tekan "Cek Status Terbaru".');
            return self::SUCCESS;
        }

        $this->table(
            ['Order ID', 'Warga', 'Tagihan', 'Status Lokal (sebelum)', 'Status Lokal (sesudah)', 'Jawaban Midtrans Saat Ini'],
            array_map(fn ($d) => [
                $d['order_id'],
                $d['user'],
                $d['invoice'],
                $d['before'],
                $d['after'],
                $d['midtrans_status'] ?? '(gagal menghubungi Midtrans, lihat storage/logs/laravel.log)',
            ], $result['details'])
        );

        if ($result['confirmed_count'] > 0) {
            $this->info("Selesai. {$result['confirmed_count']} dari {$result['total_checked']} pembayaran baru saja dikonfirmasi & masuk ke saldo admin.");
        } else {
            $this->warn("Selesai. Ada {$result['total_checked']} pembayaran pending yang dicek, tapi TIDAK ADA yang berubah status.");
            $this->line('Lihat kolom "Jawaban Midtrans Saat Ini" di atas:');
            $this->line('  - Kalau tertulis "pending" -> ini BUKAN bug aplikasi. Midtrans sendiri, saat ');
            $this->line('    ditanya langsung, masih dan tetap menjawab "pending" untuk transaksi ini.');
            $this->line('    Penyebab paling umum saat testing di Sandbox: metode pembayaran yang dipilih');
            $this->line('    (mis. Virtual Account / bank transfer) belum benar-benar "dibayar" lewat');
            $this->line('    Simulator Midtrans (https://simulator.sandbox.midtrans.com), atau QRIS/GoPay');
            $this->line('    belum di-klik "Success" di simulator tersebut. Sampai transaksi itu benar-');
            $this->line('    benar disimulasikan sukses di sisi Midtrans, tidak ada kode di aplikasi ini');
            $this->line('    yang bisa membuatnya "confirmated", karena kita memang wajib mempercayai');
            $this->line('    Midtrans sebagai sumber kebenaran (supaya tidak ada yang bisa memalsukan');
            $this->line('    status lunas).');
            $this->line('  - Kalau tertulis "(gagal menghubungi Midtrans...)" -> cek MIDTRANS_SERVER_KEY');
            $this->line('    di .env dan koneksi internet server, lalu lihat storage/logs/laravel.log.');
        }

        return self::SUCCESS;
    }
}
