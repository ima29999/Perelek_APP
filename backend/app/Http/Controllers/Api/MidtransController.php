<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Invoice;
use App\Models\Payment;
use App\Services\MidtransService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class MidtransController extends Controller
{
    protected MidtransService $midtrans;

    public function __construct(MidtransService $midtrans)
    {
        $this->midtrans = $midtrans;
    }

    // -------------------------------------------------------------------------
    // POST /api/payments/midtrans/charge
    // Warga memilih bayar online -> backend buat transaksi Snap di Midtrans,
    // simpan record payment lokal berstatus pending, lalu kembalikan
    // snap_token + redirect_url untuk dibuka di WebView Flutter.
    // -------------------------------------------------------------------------
    public function charge(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'invoice_id' => 'required|exists:invoices,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal.',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $user    = $request->user();

        // Sama seperti PaymentController::store() — tombol Bayar warga ini
        // sedang dinonaktifkan sementara oleh admin, tolak juga di jalur
        // pembayaran online (Midtrans), bukan cuma yang manual.
        if (!$user->can_pay) {
            return response()->json([
                'success' => false,
                'message' => 'Fitur pembayaran untuk akun Anda sedang dinonaktifkan sementara oleh admin. Hubungi admin RT untuk info lebih lanjut.',
            ], 403);
        }

        $invoice = Invoice::findOrFail($request->invoice_id);

        // Cek apakah sudah ada pembayaran pending/confirmated untuk invoice ini,
        // baik lewat channel manual maupun Midtrans.
        $existing = Payment::where('invoice_id', $invoice->id)
            ->where('user_id', $user->id)
            ->whereIn('status', ['pending', 'confirmated'])
            ->first();

        if ($existing) {
            if ($existing->isOnline() && $existing->order_id) {
                $existing = $this->syncStatusFromMidtransIfNeeded($existing);
            }

            // Jika transaksi online sebelumnya sudah dikonfirmasi oleh Midtrans,
            // larang membuat transaksi baru untuk invoice yang sama.
            if ($existing->status === 'confirmated') {
                return response()->json([
                    'success' => false,
                    'message' => 'Tagihan ini sudah dibayar.',
                ], 422);
            }

            // Jika masih pending, lanjutkan transaksi yang sudah dibuat.
            if ($existing->isOnline() && $existing->snap_token && $existing->status === 'pending') {
                return response()->json([
                    'success' => true,
                    'message' => 'Melanjutkan transaksi yang belum selesai.',
                    'data'    => [
                        'payment'      => $existing,
                        'snap_token'   => $existing->snap_token,
                        'redirect_url' => $this->snapRedirectUrl($existing->snap_token),
                    ],
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Anda sudah memiliki pembayaran untuk tagihan ini.',
            ], 422);
        }

        $orderId = $this->generateOrderId($invoice->id, $user->id);
        // Midtrans tidak menerima nominal desimal, harus integer.
        $grossAmount = (int) round((float) $invoice->nominal);

        try {
            $customerDetails = array_filter([
                'first_name' => $user->name,
                'email'      => $user->email,
                'phone'      => $user->phone,
            ], fn ($value) => !empty($value));

            $snapResponse = $this->midtrans->createSnapTransaction([
                'transaction_details' => [
                    'order_id'     => $orderId,
                    'gross_amount' => $grossAmount,
                ],
                'customer_details' => $customerDetails,
                'item_details' => [[
                    'id'       => 'invoice-' . $invoice->id,
                    'price'    => $grossAmount,
                    'quantity' => 1,
                    'name'     => substr($invoice->title, 0, 50),
                ]],
                'callbacks' => [
                    'finish' => config('services.midtrans.finish_url'),
                ],
            ]);
        } catch (\RuntimeException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal menghubungi Midtrans. Coba lagi nanti.',
            ], 502);
        }

        $payment = Payment::create([
            'invoice_id'   => $invoice->id,
            'user_id'      => $user->id,
            'amount'       => $invoice->nominal,
            'payment_date' => now()->toDateString(),
            'method'       => 'midtrans',
            'channel'      => 'midtrans',
            'proof_path'   => null,
            'status'       => 'pending',
            'order_id'     => $orderId,
            'snap_token'   => $snapResponse['token'],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Transaksi berhasil dibuat.',
            'data'    => [
                'payment'      => $payment->load(['invoice:id,title,period', 'user:id,name']),
                'snap_token'   => $snapResponse['token'],
                'redirect_url' => $snapResponse['redirect_url'] ?? $this->snapRedirectUrl($snapResponse['token']),
            ],
        ], 201);
    }

    // -------------------------------------------------------------------------
    // GET /api/payments/midtrans/{payment}/status
    // Dipanggil FE setelah WebView ditutup. Statusnya 100% otomatis: tidak ada
    // admin yang mengonfirmasi di sini. Kalau webhook dari Midtrans belum
    // sempat masuk saat endpoint ini dipanggil, kita langsung tanya status
    // terbaru ke Midtrans (Get Status API) dan update record lokal saat itu
    // juga, supaya warga tidak perlu menunggu apa pun selain proses Midtrans.
    // -------------------------------------------------------------------------
    public function status(Request $request, Payment $payment)
    {
        $user = $request->user();

        if ($user->role !== 'admin' && $payment->user_id !== $user->id) {
            return response()->json(['success' => false, 'message' => 'Akses ditolak.'], 403);
        }

        $payment = $this->syncStatusFromMidtransIfNeeded($payment);

        return response()->json([
            'success' => true,
            'data'    => $payment->load(['invoice:id,title,period']),
        ]);
    }

    /**
     * Kalau payment ini pembayaran online yang masih 'pending' dan punya
     * order_id, tanya status terbaru langsung ke Midtrans dan simpan hasilnya.
     * Ini membuat konfirmasi tetap otomatis walau webhook belum masuk,
     * tanpa melibatkan admin sama sekali.
     */
    private function syncStatusFromMidtransIfNeeded(Payment $payment): Payment
    {
        $payment = $payment->fresh();

        if (!$payment->isOnline() || $payment->status !== 'pending' || !$payment->order_id) {
            return $payment;
        }

        try {
            $data = $this->midtrans->getTransactionStatus($payment->order_id);
        } catch (\RuntimeException $e) {
            // Belum bisa dicek (mis. transaksi belum dibuat/diselesaikan di Midtrans).
            // Biarkan tetap pending, nanti dicoba lagi lewat webhook atau polling berikutnya.
            return $payment;
        }

        $transactionStatus = $data['transaction_status'] ?? null;
        if (!$transactionStatus) {
            return $payment;
        }

        return $this->midtrans->syncPaymentStatus($payment);
    }

    // -------------------------------------------------------------------------
    // POST /api/webhooks/midtrans  (PUBLIC - dipanggil server Midtrans, bukan FE)
    // Ini sumber kebenaran utama status pembayaran online. Harus didaftarkan
    // sebagai "Payment Notification URL" di dashboard Midtrans:
    // https://domain-backend-kamu.com/api/webhooks/midtrans
    // -------------------------------------------------------------------------
    public function notification(Request $request)
    {
        $data = $request->all();

        $orderId      = $data['order_id'] ?? null;
        $statusCode   = $data['status_code'] ?? null;
        $grossAmount  = $data['gross_amount'] ?? null;
        $signatureKey = $data['signature_key'] ?? null;

        if (!$orderId || !$statusCode || !$grossAmount || !$signatureKey) {
            return response()->json(['success' => false, 'message' => 'Payload tidak lengkap.'], 422);
        }

        if (!$this->midtrans->isValidSignature($orderId, $statusCode, $grossAmount, $signatureKey)) {
            Log::warning('Midtrans webhook: signature tidak valid', ['order_id' => $orderId]);
            return response()->json(['success' => false, 'message' => 'Signature tidak valid.'], 403);
        }

        $payment = Payment::where('order_id', $orderId)->first();

        if (!$payment) {
            Log::warning('Midtrans webhook: order_id tidak ditemukan', ['order_id' => $orderId]);
            return response()->json(['success' => false, 'message' => 'Order tidak ditemukan.'], 404);
        }

        // Jangan timpa status yang sudah final (confirmated/rejected) kalau
        // Midtrans mengirim notifikasi duplikat/telat.
        if (in_array($payment->status, ['confirmated', 'rejected'], true)) {
            return response()->json(['success' => true, 'message' => 'Sudah diproses sebelumnya.']);
        }

        $transactionStatus = $data['transaction_status'] ?? 'pending';
        $fraudStatus        = $data['fraud_status'] ?? null;
        $newStatus           = $this->midtrans->mapTransactionStatus($transactionStatus, $fraudStatus);

        $payment->gateway_status = $transactionStatus;
        $payment->status         = $newStatus;

        // Ini satu-satunya sumber konfirmasi: langsung dari notifikasi resmi
        // Midtrans (sudah diverifikasi signature-nya di atas). Tidak ada
        // langkah tambahan menunggu admin — begitu Midtrans bilang sukses,
        // saldo/pembayaran warga langsung tercatat confirmated.
        if ($newStatus === 'confirmated') {
            $payment->paid_at = now();
            $payment->notes   = 'Terkonfirmasi otomatis oleh sistem (Midtrans - ' . $transactionStatus . ').';
        } elseif ($newStatus === 'rejected') {
            $payment->notes = 'Ditolak otomatis oleh sistem (Midtrans - ' . $transactionStatus . ').';
        }

        $payment->save();

        // Dashboard warga/admin & laporan transparansi di-cache singkat
        // (lihat DashboardController & ReportController::transparency).
        // Begitu status pembayaran berubah lewat webhook ini, semua cache
        // terkait langsung dibuang supaya tidak ada satupun halaman yang
        // menampilkan data basi.
        $this->midtrans->invalidatePaymentCaches($payment);

        return response()->json(['success' => true, 'message' => 'Notifikasi diproses.']);
    }

    private function generateOrderId(int $invoiceId, int $userId): string
    {
        return 'PRLK-' . $invoiceId . '-' . $userId . '-' . now()->format('YmdHis');
    }

    private function snapRedirectUrl(string $snapToken): string
    {
        $base = filter_var(config('services.midtrans.is_production'), FILTER_VALIDATE_BOOLEAN)
            ? 'https://app.midtrans.com'
            : 'https://app.sandbox.midtrans.com';

        return $base . '/snap/v4/redirection/' . $snapToken;
    }
}
