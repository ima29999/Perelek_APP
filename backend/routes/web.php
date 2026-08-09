<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\DB;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
| Semua UI dihandle oleh frontend (React/Vue).
| Backend hanya menyediakan REST API.
| Route ini hanya untuk health-check dan fallback.
|--------------------------------------------------------------------------
*/

Route::get('/', function () {
    return response()->json([
        'app'     => config('app.name'),
        'version' => '1.0.0',
        'status'  => 'running',
        'docs'    => 'Gunakan /api/* untuk mengakses API',
    ]);
});

Route::get('/health', function () {
    try {
        DB::connection()->getPdo();
        $db = 'connected';
    } catch (\Exception $e) {
        $db = 'error: ' . $e->getMessage();
    }

    return response()->json([
        'status'   => 'ok',
        'database' => $db,
        'time'     => now()->toDateTimeString(),
    ]);
});

// Menangani URL pengalihan setelah dari Midtrans.
//
// BUG PENTING YANG DIPERBAIKI DI SINI:
// Sebelumnya halaman ini SELALU menampilkan "Pembayaran Berhasil!" apapun
// yang sebenarnya terjadi di Midtrans. Midtrans memanggil finish_url ini
// begitu warga SELESAI BERINTERAKSI dengan Snap UI — itu TIDAK SAMA dengan
// "pembayaran sudah dikonfirmasi/settlement". Untuk metode seperti Virtual
// Account atau simulasi Sandbox, transaksi bisa saja masih berstatus
// 'pending' di Midtrans walau warga sudah sampai ke halaman ini. Karena
// halaman lama selalu bilang "Berhasil", warga jadi mengira sudah lunas
// padahal Midtrans sendiri masih menunggu.
//
// Sekarang halaman ini:
//   1. Mencari payment berdasarkan order_id dari query string yang dikirim
//      Midtrans, lalu langsung memaksa sync ke Midtrans SAAT INI JUGA
//      (bukan menunggu polling FE / command terjadwal) — jadi begitu warga
//      lihat halaman ini, database sudah sinkron duluan.
//   2. Menampilkan pesan yang SESUAI status sebenarnya di database (bukan
//      selalu "berhasil"): confirmated -> sukses, pending -> masih
//      diproses, rejected -> gagal.
Route::get('/payment/finish', function (\Illuminate\Http\Request $request) {
    $status  = null; // confirmated | pending | rejected | null (tidak ditemukan)
    $orderId = $request->query('order_id');

    if ($orderId) {
        $payment = \App\Models\Payment::where('order_id', $orderId)->first();
        if ($payment) {
            // Paksa cek ulang ke Midtrans sekarang juga, jangan andalkan
            // data lama di database.
            $payment = app(\App\Services\MidtransService::class)->syncPaymentStatus($payment);
            $status  = $payment->status;
        }
    }

    $view = match ($status) {
        'confirmated' => [
            'icon'  => '✓',
            'color' => '#2ecc71',
            'title' => 'Pembayaran Berhasil!',
            'desc'  => 'Terima kasih, pembayaran Anda telah kami terima dan saldo sudah bertambah.',
        ],
        'rejected' => [
            'icon'  => '✕',
            'color' => '#e74c3c',
            'title' => 'Pembayaran Gagal',
            'desc'  => 'Pembayaran ditolak/dibatalkan oleh Midtrans. Silakan coba lagi dari aplikasi.',
        ],
        'pending' => [
            'icon'  => '⏳',
            'color' => '#f39c12',
            'title' => 'Pembayaran Sedang Diproses',
            'desc'  => 'Midtrans belum mengonfirmasi transaksi ini secara final (mis. Anda memilih metode transfer/VA yang belum diselesaikan, atau di mode Sandbox perlu disimulasikan manual). Silakan selesaikan pembayaran Anda; status di aplikasi akan otomatis berubah begitu Midtrans mengonfirmasi.',
        ],
        default => [
            'icon'  => 'ℹ',
            'color' => '#7f8c8d',
            'title' => 'Selesai Berinteraksi dengan Midtrans',
            'desc'  => 'Silakan kembali ke aplikasi dan cek status pembayaran Anda di halaman Detail Pembayaran.',
        ],
    };

    $autoClose = $status === 'confirmated' || $status === 'rejected';

    return "
    <!DOCTYPE html>
    <html lang='id'>
    <head>
        <meta charset='UTF-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1.0'>
        <title>{$view['title']}</title>
        <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; text-align: center; padding: 50px; background-color: #f4f6f9; color: #333; }
            .card { background: white; padding: 40px; border-radius: 12px; box-shadow: 0 4px 15px rgba(0,0,0,0.05); display: inline-block; max-width: 420px; width: 100%; margin-top: 50px; }
            .icon { font-size: 60px; color: {$view['color']}; margin-bottom: 20px; }
            h1 { font-size: 22px; margin-bottom: 10px; color: #2c3e50; }
            p { font-size: 14px; color: #7f8c8d; line-height: 1.6; margin-bottom: 20px; }
            .countdown { font-weight: bold; color: #e74c3c; }
        </style>
    </head>
    <body>
        <div class='card'>
            <div class='icon'>{$view['icon']}</div>
            <h1>{$view['title']}</h1>
            <p>{$view['desc']}</p>
            " . ($autoClose
                ? "<p style='font-size: 13px;'>Halaman ini akan tertutup otomatis dalam <span id='timer' class='countdown'>3</span> detik...</p>
            <script>
                var timeleft = 3;
                var downloadTimer = setInterval(function(){
                    timeleft--;
                    document.getElementById('timer').textContent = timeleft;
                    if(timeleft <= 0){
                        clearInterval(downloadTimer);
                        window.close();
                    }
                }, 1000);
            </script>"
                : "<p style='font-size: 12px;'>Anda boleh menutup halaman ini kapan saja dan kembali ke aplikasi.</p>")
            . "
        </div>
    </body>
    </html>
    ";
});

Route::get('/payment/unfinish', function () {
    return response()->json([
        'success' => false,
        'message' => 'Pembayaran belum diselesaikan.'
    ]);
});

Route::get('/payment/error', function () {
    return response()->json([
        'success' => false,
        'message' => 'Terjadi kesalahan pada proses pembayaran.'
    ]);
});