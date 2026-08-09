<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Invoice;
use App\Models\Payment;
use App\Services\MidtransService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use App\Helpers\NotifHelper;
class PaymentController extends Controller
{
    // -------------------------------------------------------------------------
    // GET /api/payments/my  - Riwayat pembayaran warga sendiri
    // -------------------------------------------------------------------------
    public function index(Request $request)
    {
        $user  = $request->user();
        $query = Payment::with(['invoice:id,title,period,nominal', 'verifier:id,name'])
            ->where('user_id', $user->id);

        // Filter status
        if ($status = $request->get('status')) {
            $query->where('status', $status);
        }

        $midtrans = app(MidtransService::class);
        $midtrans->syncPendingPayments(
            Payment::where('user_id', $user->id)
                ->where('status', 'pending')
                ->whereNotNull('order_id')
                ->get()
        );

        $payments = $query->orderByDesc('created_at')
            ->paginate($request->get('per_page', 15));

        return response()->json([
            'success' => true,
            'data'    => $payments,
        ]);
    }

    // -------------------------------------------------------------------------
    // GET /api/admin/payments  - Semua pembayaran (admin)
    // -------------------------------------------------------------------------
    public function adminIndex(Request $request)
    {
        $midtrans = app(MidtransService::class);
        $midtrans->syncPendingPayments(
            Payment::where('status', 'pending')
                ->whereNotNull('order_id')
                ->get()
        );

        $query = Payment::with([
            'invoice:id,title,period',
            'user:id,name,rt_rw',
            'verifier:id,name',
        ]);

        if ($status = $request->get('status')) {
            $query->where('status', $status);
        }

        if ($search = $request->get('search')) {
            $query->whereHas('user', fn($q) => $q->where('name', 'like', "%{$search}%")
                ->orWhere('rt_rw', 'like', "%{$search}%"));
        }

        $payments = $query->orderByDesc('created_at')
            ->paginate($request->get('per_page', 20));

        return response()->json([
            'success' => true,
            'data'    => $payments,
        ]);
    }

    // -------------------------------------------------------------------------
    // POST /api/payments  - Submit pembayaran + upload bukti
    // -------------------------------------------------------------------------
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'invoice_id'   => 'required|exists:invoices,id',
            'amount'       => 'required|numeric|min:1',
            'payment_date' => 'required|date',
            'method'       => 'required|string|in:transfer,tunai,qris,other',
            'proof'        => 'required|image|mimes:jpg,jpeg,png|max:5120',
            'notes'        => 'nullable|string|max:500',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal.',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $user    = $request->user();

        // Tombol Bayar warga ini sedang dinonaktifkan sementara oleh admin
        // (lihat UserController::disablePayment). Dicek di sini juga, bukan
        // cuma disembunyikan di FE, supaya tidak bisa dilewati dengan
        // memanggil endpoint langsung.
        if (!$user->can_pay) {
            return response()->json([
                'success' => false,
                'message' => 'Fitur pembayaran untuk akun Anda sedang dinonaktifkan sementara oleh admin. Hubungi admin RT untuk info lebih lanjut.',
            ], 403);
        }

        $invoice = Invoice::findOrFail($request->invoice_id);

        // Cek apakah sudah ada pembayaran pending/confirmated
        $existing = Payment::where('invoice_id', $invoice->id)
            ->where('user_id', $user->id)
            ->whereIn('status', ['pending', 'confirmated'])
            ->first();

        if ($existing) {
            return response()->json([
                'success' => false,
                'message' => 'Anda sudah memiliki pembayaran untuk tagihan ini.',
            ], 422);
        }

        // Upload bukti pembayaran
        $filename = time() . '_' . $user->id . '_' . $invoice->id . '.' . $request->file('proof')->extension();
        $request->file('proof')->storeAs('payment_proofs', $filename, 'public');

        $payment = Payment::create([
            'invoice_id'   => $invoice->id,
            'user_id'      => $user->id,
            'amount'       => $request->amount,
            'payment_date' => $request->payment_date,
            'method'       => $request->method,
            'proof_path'   => $filename,
            'status'       => 'confirmated',
            'paid_at'      => now(),
            'notes'        => $request->notes,
        ]);

        $this->invalidateFinancialCaches($user->id, $payment->payment_date);

        return response()->json([
            'success' => true,
            'message' => 'Pembayaran berhasil dikirim dan langsung terkonfirmasi.',
            'data'    => $payment->load(['invoice:id,title,period', 'user:id,name']),
        ], 201);
    }

    /**
     * Halaman dashboard warga/admin (lihat DashboardController) dan laporan
     * transparansi (lihat ReportController::transparency) semuanya di-cache.
     * Panggil ini setiap kali status pembayaran seorang warga berubah
     * (pembayaran manual dikonfirmasi langsung, atau dibatalkan), supaya
     * tidak ada halaman yang menampilkan saldo/status basi selama masa
     * cache. Sebelumnya method ini hanya membuang cache dashboard dan
     * "lupa" cache laporan transparansi, jadi angka di sana bisa telat
     * ter-update sampai 90 detik walau pembayaran sudah confirmated.
     */
    private function invalidateFinancialCaches(int $userId, $paymentDate = null): void
    {
        Cache::forget(DashboardController::userDashboardCacheKey($userId));

        $years = array_unique(array_filter([
            (int) now()->year,
            $paymentDate ? (int) $paymentDate->year : null,
        ]));

        foreach ($years as $year) {
            Cache::forget('dashboard.admin.' . $year);
            Cache::forget(ReportController::transparencyCacheKey($year));
            Cache::forget('public.transparency.' . $year);
        }
    }

    // -------------------------------------------------------------------------
    // GET /api/payments/{payment}  - Detail pembayaran
    // -------------------------------------------------------------------------
    public function show(Request $request, Payment $payment)
    {
        $user = $request->user();

        // Warga hanya bisa lihat milik sendiri
        if ($user->role !== 'admin' && $payment->user_id !== $user->id) {
            return response()->json(['success' => false, 'message' => 'Akses ditolak.'], 403);
        }

        // BUG FIX: sebelumnya endpoint ini TIDAK PERNAH mengecek ulang status
        // ke Midtrans (berbeda dengan index()/adminIndex() yang selalu sync),
        // jadi halaman "Detail Pembayaran" bisa nyangkut di 'pending'
        // selamanya walau pembayarannya sudah sukses di Midtrans. Samakan
        // perilakunya: kalau ini pembayaran online yang masih pending,
        // cek dulu status terbarunya sebelum dikembalikan ke FE.
        if ($payment->isOnline() && $payment->status === 'pending' && $payment->order_id) {
            $midtrans = app(MidtransService::class);
            $payment  = $midtrans->syncPaymentStatus($payment);
        }

        $payment->load(['invoice', 'user:id,name,rt_rw', 'verifier:id,name']);

        return response()->json([
            'success' => true,
            'data'    => array_merge($payment->toArray(), [
                'proof_url' => $payment->proof_path
                    ? url('storage/payment_proofs/' . $payment->proof_path)
                    : null,
            ]),
        ]);
    }


    // -------------------------------------------------------------------------
    // DELETE /api/payments/{payment}  - Warga batal submission
    // -------------------------------------------------------------------------
    public function destroy(Request $request, Payment $payment)
    {
        $user = $request->user();

        if ($payment->user_id !== $user->id) {
            return response()->json(['success' => false, 'message' => 'Akses ditolak.'], 403);
        }

        if ($payment->status === 'confirmated') {
            return response()->json([
                'success' => false,
                'message' => 'Pembayaran yang sudah confirmated tidak dapat dibatalkan.',
            ], 422);
        }

        // Hapus file bukti
        if ($payment->proof_path) {
            Storage::disk('public')->delete('payment_proofs/' . $payment->proof_path);
        }

        $payment->delete();

        $this->invalidateFinancialCaches($user->id, $payment->payment_date);

        return response()->json([
            'success' => true,
            'message' => 'Pembayaran berhasil dibatalkan.',
        ]);
    }
}
