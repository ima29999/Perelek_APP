<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class NotificationController extends Controller
{
    // GET /notifications
    public function index(Request $request)
    {
        $notifications = Notification::where('user_id', auth()->id())
            ->latest()
            ->take(50)
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $notifications,
        ]);
    }

    // POST /reports/submit
    // Warga mengirim laporan secara realtime ke semua admin.
    // Laporan ini akan muncul sebagai notifikasi berjudul "Laporan Warga".
    public function submitReport(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'title'       => 'required|string|max:100',
            'description' => 'required|string|max:500',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first(),
            ], 422);
        }

        $reporter = auth()->user();

        // Ambil semua user dengan role admin agar laporan tersampaikan
        // ke setiap admin secara realtime (lewat polling/refresh notifikasi).
        $admins = User::where('role', 'admin')->get();

        if ($admins->isEmpty()) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak ada admin terdaftar untuk menerima laporan.',
            ], 404);
        }

        $now = now();

        foreach ($admins as $admin) {
            Notification::create([
                'user_id' => $admin->id,
                'type'    => 'report',
                'title'   => 'Laporan Warga',
                'body'    => $request->input('description'),
                'data'    => [
                    'report_title'   => $request->input('title'),
                    'description'    => $request->input('description'),
                    'reporter_name'  => $reporter->name,
                    'reporter_email' => $reporter->email,
                    'reported_at'    => $now->toIso8601String(),
                ],
                'read_at' => null,
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Laporan berhasil dikirim ke admin',
        ]);
    }

    /**
     * Mengirim notifikasi pembayaran terbaru dari warga ke seluruh admin.
     * Fungsi ini dapat dipanggil secara internal dari PaymentController / sistem setelah warga mengunggah bukti bayar.
     */
    public function sendPaymentNotification($paymentId, $wargaName, $invoiceTitle, $amount, $rtRw, $status = 'pending')
    {
        $admins = User::where('role', 'admin')->get();

        if ($admins->isEmpty()) {
            return false;
        }

        foreach ($admins as $admin) {
            Notification::create([
                'user_id' => $admin->id,
                'type'    => 'payment',
                'title'   => 'Pembayaran Baru dari Warga 💳',
                'body'    => "Warga bernama {$wargaName} telah mengirim pembayaran untuk {$invoiceTitle}.",
                'data'    => [
                    'payment_id' => $paymentId,
                    'user'       => $wargaName,
                    'invoice'    => $invoiceTitle,
                    'amount'     => $amount,
                    'rt_rw'      => $rtRw,
                    'status'     => $status,
                ],
                'read_at' => null,
            ]);
        }

        return true;
    }

    // PATCH /notifications/{id}/read
    public function markRead(Notification $notification)
    {
        abort_if($notification->user_id !== auth()->id(), 403);

        $notification->update(['read_at' => now()]);

        return response()->json(['success' => true]);
    }

    // PATCH /notifications/read-all
    public function markAllRead()
    {
        Notification::where('user_id', auth()->id())
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json(['success' => true]);
    }
}