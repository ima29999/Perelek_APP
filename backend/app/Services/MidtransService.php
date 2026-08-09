<?php

namespace App\Services;

use App\Models\Payment;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\ReportController;
use GuzzleHttp\Client;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class MidtransService
{
    protected Client $http;
    protected string $serverKey;
    protected bool $isProduction;

    public function __construct()
    {
        $this->serverKey    = (string) config('services.midtrans.server_key');
        $this->isProduction = filter_var(config('services.midtrans.is_production'), FILTER_VALIDATE_BOOLEAN);

        $this->http = new Client([
            'base_uri' => $this->isProduction
                ? 'https://app.midtrans.com'
                : 'https://app.sandbox.midtrans.com',
            'timeout'  => 20,
        ]);
    }

    /**
     * Buat transaksi Snap baru di Midtrans.
     * Mengembalikan array berisi 'token' dan 'redirect_url'.
     *
     * @throws \RuntimeException jika Midtrans menolak request
     */
    public function createSnapTransaction(array $payload): array
    {
        try {
            $response = $this->http->post('/snap/v1/transactions', [
                'headers' => [
                    'Accept'        => 'application/json',
                    'Content-Type'  => 'application/json',
                    'Authorization' => 'Basic ' . base64_encode($this->serverKey . ':'),
                ],
                'json' => $payload,
            ]);

            $body = json_decode((string) $response->getBody(), true);

            if (empty($body['token'])) {
                throw new \RuntimeException('Respons Midtrans tidak berisi token Snap.');
            }

            return $body;
        } catch (\GuzzleHttp\Exception\RequestException $e) {
            $errorBody = $e->getResponse()
                ? (string) $e->getResponse()->getBody()
                : $e->getMessage();

            Log::error('Midtrans createSnapTransaction gagal', ['error' => $errorBody]);

            throw new \RuntimeException('Gagal membuat transaksi Midtrans: ' . $errorBody);
        }
    }

    /**
     * Verifikasi signature_key yang dikirim Midtrans pada webhook notification,
     * supaya kita yakin notifikasi benar-benar berasal dari Midtrans dan
     * bukan dipalsukan oleh pihak luar.
     *
     * signature_key = SHA512(order_id + status_code + gross_amount + ServerKey)
     */
    public function isValidSignature(string $orderId, string $statusCode, string $grossAmount, string $signatureKey): bool
    {
        $expected = hash('sha512', $orderId . $statusCode . $grossAmount . $this->serverKey);

        return hash_equals($expected, $signatureKey);
    }

    /**
     * Map transaction_status + fraud_status dari Midtrans ke status internal
     * payment kita: 'pending' | 'confirmated' | 'rejected'.
     *
     * Tidak ada langkah konfirmasi admin di alur ini sama sekali — status
     * 'confirmated' didapat murni dari respons/notifikasi Midtrans sendiri.
     */
    public function mapTransactionStatus(string $transactionStatus, ?string $fraudStatus = null): string
    {
        if ($transactionStatus === 'capture') {
            return $fraudStatus === 'accept' ? 'confirmated' : 'rejected';
        }

        if ($transactionStatus === 'authorize') {
            return 'confirmated';
        }

        if ($transactionStatus === 'settlement') {
            return 'confirmated';
        }

        if (in_array($transactionStatus, ['deny', 'cancel', 'expire', 'failure'], true)) {
            return 'rejected';
        }

        // 'pending', 'authorize', atau status lain -> transaksi masih diproses
        // Midtrans (mis. menunggu pembayaran VA/QRIS), BUKAN menunggu admin.
        return 'pending';
    }

    /**
     * Ambil status transaksi terbaru langsung dari Midtrans (Get Status API).
     * Dipakai sebagai pengaman: kalau webhook belum/telat masuk, backend bisa
     * langsung tanya ke Midtrans supaya status tetap otomatis ter-update
     * tanpa perlu ada admin yang mengonfirmasi secara manual.
     *
     * @throws \RuntimeException jika Midtrans menolak / gagal request
     */
    public function getTransactionStatus(string $orderId): array
    {
        // Endpoint Core API Midtrans ada di domain api.*, beda dengan domain
        // app.* yang dipakai untuk Snap, jadi pakai URL absolut di sini.
        $base = $this->isProduction
            ? 'https://api.midtrans.com'
            : 'https://api.sandbox.midtrans.com';

        try {
            $response = $this->http->get("{$base}/v2/{$orderId}/status", [
                'headers' => [
                    'Accept'        => 'application/json',
                    'Authorization' => 'Basic ' . base64_encode($this->serverKey . ':'),
                ],
            ]);

            return json_decode((string) $response->getBody(), true) ?? [];
        } catch (\GuzzleHttp\Exception\RequestException $e) {
            $errorBody = $e->getResponse()
                ? (string) $e->getResponse()->getBody()
                : $e->getMessage();

            Log::warning('Midtrans getTransactionStatus gagal', [
                'order_id' => $orderId,
                'error'    => $errorBody,
            ]);

            throw new \RuntimeException('Gagal mengambil status transaksi Midtrans: ' . $errorBody);
        }
    }

    /**
     * Cek status Midtrans untuk pembayaran online yang masih pending,
     * lalu perbarui record lokal menjadi confirmated/rejected jika sudah final.
     */
    public function syncPaymentStatus(Payment $payment): Payment
    {
        $payment = $payment->fresh();

        if (!$payment->isOnline() || $payment->status !== 'pending' || !$payment->order_id) {
            return $payment;
        }

        try {
            $data = $this->getTransactionStatus($payment->order_id);
        } catch (\RuntimeException $e) {
            return $payment;
        }

        $transactionStatus = $data['transaction_status'] ?? null;
        if (!$transactionStatus) {
            return $payment;
        }

        $fraudStatus = $data['fraud_status'] ?? null;
        $newStatus   = $this->mapTransactionStatus($transactionStatus, $fraudStatus);

        // Selalu simpan status mentah dari Midtrans (kolom gateway_status)
        // walau status lokal kita (pending/confirmated/rejected) belum
        // berubah — supaya command diagnostik & tampilan admin bisa lihat
        // apa jawaban TERBARU dari Midtrans tanpa perlu memanggil API-nya
        // lagi dari tempat lain.
        if ($transactionStatus !== $payment->gateway_status) {
            $payment->gateway_status = $transactionStatus;
            $payment->save();
        }

        if ($newStatus === $payment->status) {
            return $payment;
        }

        $payment->status = $newStatus;

        if ($newStatus === 'confirmated') {
            $payment->paid_at = now();
            $payment->notes   = 'Terkonfirmasi otomatis oleh sistem (Midtrans - ' . $transactionStatus . ').';
        } elseif ($newStatus === 'rejected') {
            $payment->notes = 'Ditolak otomatis oleh sistem (Midtrans - ' . $transactionStatus . ').';
        }

        $payment->save();

        $this->invalidatePaymentCaches($payment);

        return $payment;
    }

    /**
     * Buang semua cache yang menampilkan saldo/pembayaran supaya begitu
     * status payment ini berubah, admin & warga langsung melihat angka
     * terbaru di halaman manapun (dashboard warga, dashboard admin, dan
     * laporan transparansi) — sebelumnya laporan transparansi TIDAK
     * pernah di-invalidate di sini sehingga bisa telat sampai 90 detik
     * (TTL cache-nya) walau status pembayaran sudah confirmated.
     *
     * Public supaya dipakai juga oleh MidtransController::notification()
     * (webhook) dan PaymentController (pembayaran manual), sehingga tidak
     * ada lagi tempat yang lupa membuang cache laporan transparansi.
     */
    public function invalidatePaymentCaches(Payment $payment): void
    {
        Cache::forget(DashboardController::userDashboardCacheKey($payment->user_id));

        $years = array_unique(array_filter([
            (int) now()->year,
            $payment->payment_date ? (int) $payment->payment_date->year : null,
        ]));

        foreach ($years as $year) {
            Cache::forget('dashboard.admin.' . $year);
            Cache::forget(ReportController::transparencyCacheKey($year));
            Cache::forget('public.transparency.' . $year);
        }
    }

    /**
     * Sync status untuk sejumlah pembayaran Midtrans yang masih pending.
     */
    public function syncPendingPayments(iterable $payments): void
    {
        foreach ($payments as $payment) {
            $this->syncPaymentStatus($payment);
        }
    }

    /**
     * Sync SEMUA pembayaran Midtrans yang masih pending di seluruh sistem,
     * tanpa bergantung pada warga/admin membuka halaman tertentu dulu.
     * Dipakai oleh command terjadwal `payments:sync-midtrans` (lihat
     * app/Console/Commands/SyncMidtransPayments.php) sebagai jaring
     * pengaman: kalau webhook Midtrans tidak bisa menjangkau server
     * (mis. saat development di localhost), saldo & status pembayaran
     * tetap ter-update otomatis dalam hitungan menit, bukan menunggu
     * ada yang membuka aplikasi.
     */
    public function syncAllPendingPayments(): int
    {
        $result = $this->diagnosePendingPayments();
        return $result['confirmed_count'];
    }

    /**
     * Sama seperti syncAllPendingPayments(), tapi mengembalikan detail
     * per-pembayaran supaya command CLI bisa menjelaskan APA yang
     * sebenarnya terjadi — bukan cuma "tidak ada yang berubah". Ini
     * penting karena "tidak ada perubahan" bisa berarti dua hal yang
     * SANGAT berbeda:
     *   (a) memang tidak ada pembayaran midtrans yang masih pending, atau
     *   (b) ada, tapi Midtrans SENDIRI masih dan tetap melaporkan status
     *       'pending' untuk transaksi itu (mis. warga memilih Virtual
     *       Account tapi belum benar-benar transfer, atau di Sandbox
     *       transaksinya belum "dibayar" lewat Simulator Midtrans) — ini
     *       BUKAN bug di aplikasi, karena kita sudah menanyakan langsung
     *       ke Midtrans dan itulah jawaban resminya.
     */
    public function diagnosePendingPayments(): array
    {
        $pending = Payment::with(['user:id,name', 'invoice:id,title'])
            ->where('status', 'pending')
            ->whereNotNull('order_id')
            ->where('channel', 'midtrans')
            ->get();

        $confirmedCount = 0;
        $details        = [];

        foreach ($pending as $payment) {
            $before = $payment->status;

            $result = $this->syncPaymentStatus($payment);

            if ($result->status === 'confirmated') {
                $confirmedCount++;
            }

            $details[] = [
                'order_id'        => $payment->order_id,
                'user'            => $payment->user?->name ?? '-',
                'invoice'         => $payment->invoice?->title ?? '-',
                'before'          => $before,
                'after'           => $result->status,
                // gateway_status berisi jawaban MENTAH terakhir dari
                // Midtrans (mis. 'pending', 'settlement', 'deny'), selalu
                // diperbarui oleh syncPaymentStatus() walau status lokal
                // tidak berubah. Kalau masih null, berarti kita gagal
                // menghubungi Midtrans sama sekali (lihat storage/logs).
                'midtrans_status' => $result->gateway_status,
            ];
        }

        return [
            'confirmed_count' => $confirmedCount,
            'total_checked'   => $pending->count(),
            'details'         => $details,
        ];
    }
}
