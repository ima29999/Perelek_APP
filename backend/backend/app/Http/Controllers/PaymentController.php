<?php

namespace App\Http\Controllers;

use App\Models\Invoice;
use App\Models\Payment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Http\JsonResponse;
use Illuminate\Validation\Rule;

class PaymentController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Payment::with(['invoice', 'user']);

        if ($request->user()->isAdmin()) {
            $query->orderByDesc('created_at');
        } else {
            $query->where('user_id', $request->user()->id)->orderByDesc('payment_date');
        }

        return response()->json($query->paginate(50));
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'invoice_id' => 'required|exists:invoices,id',
            'amount' => 'required|numeric|min:0',
            'payment_date' => 'required|date',
            'method' => ['required', Rule::in(['transfer', 'tunai', 'e-wallet', 'lainnya'])],
            'proof' => 'required|image|mimes:jpg,jpeg,png|max:5120',
            'notes' => 'nullable|string|max:1000',
        ]);

        $invoice = Invoice::findOrFail($data['invoice_id']);

        if (! $invoice->is_active) {
            return response()->json(['message' => 'Tagihan tidak aktif tidak dapat dibayar.'], 422);
        }

        $data['user_id'] = $request->user()->id;
        $data['status'] = 'pending';
        $data['proof_path'] = $request->file('proof')->store('payment_proofs', 'public');

        $payment = Payment::create($data);

        return response()->json($payment, 201);
    }

    public function show(Request $request, Payment $payment): JsonResponse
    {
        if (! $request->user()->isAdmin() && $payment->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Akses ditolak.'], 403);
        }

        return response()->json($payment->load(['invoice', 'user', 'verifier']));
    }

    public function verify(Request $request, Payment $payment): JsonResponse
    {
        $data = $request->validate([
            'status' => ['required', Rule::in(['lunas', 'ditolak'])],
            'notes' => 'nullable|string|max:1000',
        ]);

        if ($payment->status === 'lunas') {
            return response()->json(['message' => 'Pembayaran sudah diverifikasi lunas.'], 422);
        }

        $payment->status = $data['status'];
        $payment->notes = $data['notes'] ?? $payment->notes;
        $payment->verified_by = $request->user()->id;
        $payment->save();

        return response()->json($payment->load(['invoice', 'user', 'verifier']));
    }

    public function destroy(Request $request, Payment $payment): JsonResponse
    {
        if ($payment->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Akses ditolak.'], 403);
        }

        if ($payment->status !== 'pending') {
            return response()->json(['message' => 'Hanya pembayaran pending yang dapat dibatalkan.'], 422);
        }

        Storage::disk('public')->delete($payment->proof_path);
        $payment->delete();

        return response()->json(['message' => 'Pembayaran berhasil dibatalkan.']);
    }
}
