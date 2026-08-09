<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Invoice;
use App\Models\Payment;
use App\Services\MidtransService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use App\Helpers\NotifHelper;

class InvoiceController extends Controller
{
    // -------------------------------------------------------------------------
    // GET /api/admin/invoices  (admin) | GET /api/invoices (warga)
    // -------------------------------------------------------------------------
    public function index(Request $request)
    {
        $user  = $request->user();
        $query = Invoice::with('creator:id,name');

        // Filter aktif
        if ($request->has('is_active')) {
            $query->where('is_active', (bool) $request->is_active);
        }

        // Search
        if ($search = $request->get('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('period', 'like', "%{$search}%");
            });
        }

        $invoices = $query->orderByDesc('created_at')
            ->paginate($request->get('per_page', 15));

        // Untuk warga, tambahkan info status bayar.
        // Sebelumnya ini menjalankan 1 query Payment terpisah UNTUK SETIAP invoice
        // di halaman (N+1 query) — dengan per_page=15 berarti 15 query tambahan
        // pada setiap request. Sekarang cukup 1 query untuk seluruh halaman,
        // hasilnya di-index di memori lalu dicocokkan per invoice.
        if ($user && $user->role === 'user') {
            $invoiceIds = $invoices->getCollection()->pluck('id');

            $midtrans = app(MidtransService::class);
            Payment::where('user_id', $user->id)
                ->whereIn('invoice_id', $invoiceIds)
                ->where('status', 'pending')
                ->whereNotNull('order_id')
                ->get()
                ->each(fn($payment) => $midtrans->syncPaymentStatus($payment));

            $latestPayments = Payment::where('user_id', $user->id)
                ->whereIn('invoice_id', $invoiceIds)
                ->orderByDesc('created_at')
                ->get(['id', 'invoice_id', 'status', 'channel', 'created_at'])
                // Ambil pembayaran terbaru per invoice_id (setara "latest()" versi lama)
                ->groupBy('invoice_id')
                ->map(fn($group) => $group->first());

            $invoices->getCollection()->transform(function ($invoice) use ($latestPayments) {
                $payment = $latestPayments->get($invoice->id);
                $invoice->payment_status  = $payment?->status ?? 'unpaid';
                $invoice->payment_id      = $payment?->id;
                $invoice->payment_channel = $payment?->channel;
                return $invoice;
            });
        }

        return response()->json([
            'success' => true,
            'data'    => $invoices,
        ]);
    }

    // -------------------------------------------------------------------------
    // POST /api/admin/invoices
    // -------------------------------------------------------------------------
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'title'       => 'required|string|max:255',
            'description' => 'nullable|string',
            'nominal'     => 'required|numeric|min:1',
            'period'      => 'nullable|string|max:50',
            'deadline'    => 'nullable|date',
            'is_active'   => 'boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal.',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $invoice = Invoice::create([
            'title'       => $request->title,
            'description' => $request->description,
            'nominal'     => $request->nominal,
            'period'      => $request->period,
            'deadline'    => $request->deadline,
            'created_by'  => $request->user()->id,
            'is_active'   => $request->get('is_active', true),
        ]);

        // Beritahu warga
        NotifHelper::broadcast(
            type:  'invoice',
            title: 'Tagihan Baru 🧾',
            body:  "Tagihan \"{$invoice->title}\" telah diterbitkan. Jatuh tempo: {$invoice->deadline}.",
            data:  ['invoice_id' => $invoice->id],
        );

        return response()->json([
            'success' => true,
            'message' => 'Tagihan berhasil dibuat.',
            'data'    => $invoice->load('creator:id,name'),
        ], 201);
    }

    // -------------------------------------------------------------------------
    // GET /api/admin/invoices/{invoice}
    // -------------------------------------------------------------------------
    public function show(Invoice $invoice)
    {
        $midtrans = app(MidtransService::class);
        $invoice->payments()
            ->where('status', 'pending')
            ->whereNotNull('order_id')
            ->get()
            ->each(fn($payment) => $midtrans->syncPaymentStatus($payment));

        $invoice->load(['creator:id,name', 'payments.user:id,name,rt_rw']);

        $paidCount = $invoice->payments->where('status', 'confirmated')->count();

        return response()->json([
            'success' => true,
            'data'    => array_merge($invoice->toArray(), [
                'paid_count' => $paidCount,
            ]),
        ]);
    }

    // -------------------------------------------------------------------------
    // PUT /api/admin/invoices/{invoice}
    // -------------------------------------------------------------------------
    public function update(Request $request, Invoice $invoice)
    {
        $validator = Validator::make($request->all(), [
            'title'       => 'sometimes|string|max:255',
            'description' => 'nullable|string',
            'nominal'     => 'sometimes|numeric|min:1',
            'period'      => 'nullable|string|max:50',
            'deadline'    => 'nullable|date',
            'is_active'   => 'boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal.',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $invoice->update($request->only('title', 'description', 'nominal', 'period', 'deadline', 'is_active'));

        return response()->json([
            'success' => true,
            'message' => 'Tagihan berhasil diperbarui.',
            'data'    => $invoice->fresh()->load('creator:id,name'),
        ]);
    }

    // -------------------------------------------------------------------------
    // DELETE /api/admin/invoices/{invoice}
    // -------------------------------------------------------------------------
    public function destroy(Invoice $invoice)
    {
        $invoice->delete();

        return response()->json([
            'success' => true,
            'message' => 'Tagihan berhasil dihapus.',
        ]);
    }
}
