<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Invoice;
use App\Models\Payment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

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
        $invoice = Invoice::findOrFail($request->invoice_id);

        // Cek apakah sudah ada pembayaran pending/confirmed
        $existing = Payment::where('invoice_id', $invoice->id)
            ->where('user_id', $user->id)
            ->whereIn('status', ['pending', 'confirmed'])
            ->first();

        if ($existing) {
            return response()->json([
                'success' => false,
                'message' => 'Anda sudah memiliki pembayaran ' . $existing->status . ' untuk tagihan ini.',
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
            'status'       => 'pending',
            'notes'        => $request->notes,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Pembayaran berhasil dikirim, menunggu konfirmasi admin.',
            'data'    => $payment->load(['invoice:id,title,period', 'user:id,name']),
        ], 201);
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
    // PATCH /api/admin/payments/{payment}/verify  - Konfirmasi / Tolak
    // -------------------------------------------------------------------------
    public function verify(Request $request, Payment $payment)
    {
        $validator = Validator::make($request->all(), [
            'status' => 'required|in:confirmed,rejected',
            'notes'  => 'nullable|string|max:500',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal.',
                'errors'  => $validator->errors(),
            ], 422);
        }

        if ($payment->status !== 'pending') {
            return response()->json([
                'success' => false,
                'message' => 'Pembayaran sudah diproses sebelumnya.',
            ], 422);
        }

        $payment->update([
            'status'      => $request->status,
            'notes'       => $request->notes,
            'verified_by' => $request->user()->id,
        ]);

        $message = $request->status === 'confirmed'
            ? 'Pembayaran berhasil dikonfirmasi.'
            : 'Pembayaran ditolak.';

        return response()->json([
            'success' => true,
            'message' => $message,
            'data'    => $payment->fresh()->load(['invoice:id,title', 'user:id,name', 'verifier:id,name']),
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

        if ($payment->status !== 'pending') {
            return response()->json([
                'success' => false,
                'message' => 'Hanya pembayaran berstatus pending yang dapat dibatalkan.',
            ], 422);
        }

        // Hapus file bukti
        if ($payment->proof_path) {
            Storage::disk('public')->delete('payment_proofs/' . $payment->proof_path);
        }

        $payment->delete();

        return response()->json([
            'success' => true,
            'message' => 'Pembayaran berhasil dibatalkan.',
        ]);
    }
}
