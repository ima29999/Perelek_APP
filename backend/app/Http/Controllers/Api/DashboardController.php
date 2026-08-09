<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Expense;
use App\Models\Invoice;
use App\Models\Payment;
use App\Models\User;
use App\Models\Event;
use App\Services\MidtransService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class DashboardController extends Controller
{
    // -------------------------------------------------------------------------
    // GET /api/admin/dashboard
    // -------------------------------------------------------------------------
    public function admin(Request $request)
    {
        $year  = $request->get('year', date('Y'));
        $month = $request->get('month');

        // Cache 60 detik: dashboard admin di-hit berulang kali setiap kali
        // tab/halaman dashboard dibuka. Data statistik semacam ini wajar
        // "telat" beberapa puluh detik (pola yang sama dipakai Shopee/IG
        // untuk data ringkasan/feed). Kirim query ?fresh=1 (dipakai saat
        // pull-to-refresh di app) untuk memaksa data terbaru.
        $cacheKey = "dashboard.admin.{$year}";
        if ($request->boolean('fresh')) {
            Cache::forget($cacheKey);
        }

        $payload = Cache::remember($cacheKey, 60, function () use ($year) {
            // ---- Statistik Utama ----
            $totalWarga  = User::where('role', 'user')->where('is_active', true)->count();
            $midtrans = app(MidtransService::class);
            Payment::where('status', 'pending')
                ->whereNotNull('order_id')
                ->get()
                ->each(fn($payment) => $midtrans->syncPaymentStatus($payment));

            $totalIncome = Payment::where('status', 'confirmated')->sum('amount');
            $totalExpense = Expense::sum('nominal');
            $saldo       = $totalIncome - $totalExpense;

            // ---- Tren Pemasukan per Bulan (tahun berjalan) ----
            $incomeTrend = Payment::selectRaw('MONTH(payment_date) as month, SUM(amount) as total')
                ->where('status', 'confirmated')
                ->whereYear('payment_date', $year)
                ->groupBy('month')
                ->orderBy('month')
                ->get()
                ->keyBy('month');

            $expenseTrend = Expense::selectRaw('MONTH(date) as month, SUM(nominal) as total')
                ->whereYear('date', $year)
                ->groupBy('month')
                ->orderBy('month')
                ->get()
                ->keyBy('month');

            $trendData = [];
            $monthNames = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
            for ($m = 1; $m <= 12; $m++) {
                $trendData[] = [
                    'month'   => $monthNames[$m - 1],
                    'income'  => (float) ($incomeTrend[$m]->total ?? 0),
                    'expense' => (float) ($expenseTrend[$m]->total ?? 0),
                ];
            }

            // ---- Pembayaran terbaru ----
            $recentPayments = Payment::with(['user:id,name,rt_rw', 'invoice:id,title,period'])
                ->latest()
                ->limit(10)
                ->get()
                ->map(fn($p) => [
                    'id'           => $p->id,
                    'user'         => $p->user?->name,
                    'rt_rw'        => $p->user?->rt_rw,
                    'invoice'      => $p->invoice?->title,
                    'amount'       => $p->amount,
                    'status'       => $p->status,
                    'payment_date' => $p->payment_date?->format('d M Y'),
                    'proof_url'    => $p->proof_path ? url('storage/payment_proofs/' . $p->proof_path) : null,
                ]);

            // ---- Warga terbaru ----
            $recentWarga = User::where('role', 'user')
                ->latest()
                ->limit(5)
                ->get(['id', 'name', 'rt_rw', 'created_at']);

            // ---- Tagihan aktif ----
            $activeInvoices = Invoice::where('is_active', true)
                ->withCount(['payments as paid_count' => fn($q) => $q->where('status', 'confirmated')])
                ->latest()
                ->limit(5)
                ->get();

            // ---- Kategori pengeluaran ----
            $expenseByCategory = Expense::selectRaw('category, SUM(nominal) as total')
                ->groupBy('category')
                ->orderByDesc('total')
                ->get();

            return [
                'stats' => [
                    'total_warga'    => $totalWarga,
                    'total_income'   => $totalIncome,
                    'total_expense'  => $totalExpense,
                    'saldo'          => $saldo,
                ],
                'trend_data'          => $trendData,
                'recent_payments'     => $recentPayments,
                'recent_warga'        => $recentWarga,
                'active_invoices'     => $activeInvoices,
                'expense_by_category' => $expenseByCategory,
            ];
        });

        return response()->json(['success' => true, 'data' => $payload]);
    }

    // -------------------------------------------------------------------------
    // GET /api/dashboard  - Dashboard warga
    // -------------------------------------------------------------------------
    public function user(Request $request)
    {
        $user = $request->user();

        // Cache 20 detik per warga. Dibuat pendek (lebih pendek dari
        // dashboard admin) karena halaman ini langsung dilihat warga
        // setelah melakukan pembayaran, sehingga harus tetap terasa segar.
        // Cache juga di-invalidate otomatis begitu status pembayaran warga
        // ini berubah (lihat MidtransController & PaymentController::destroy).
        $cacheKey = self::userDashboardCacheKey($user->id);
        if ($request->boolean('fresh')) {
            Cache::forget($cacheKey);
        }

        $payload = Cache::remember($cacheKey, 20, function () use ($user) {
            // Sinkronisasi status Midtrans untuk pembayaran online yang belum final.
            $midtrans = app(MidtransService::class);
            Payment::where('user_id', $user->id)
                ->where('status', 'pending')
                ->whereNotNull('order_id')
                ->get()
                ->each(fn($payment) => $midtrans->syncPaymentStatus($payment));

            // Tagihan aktif belum dibayar
            $unpaidInvoices = Invoice::where('is_active', true)
                ->whereDoesntHave('payments', fn($q) =>
                    $q->where('user_id', $user->id)
                      ->whereIn('status', ['pending', 'confirmated'])
                )
                ->orderBy('deadline')
                ->get(['id', 'title', 'nominal', 'period', 'deadline']);

            // Riwayat pembayaran terbaru
            $recentPayments = Payment::where('user_id', $user->id)
                ->with('invoice:id,title,period')
                ->latest()
                ->limit(5)
                ->get()
                ->map(fn($p) => [
                    'id'           => $p->id,
                    'invoice'      => $p->invoice?->title,
                    'period'       => $p->invoice?->period,
                    'amount'       => $p->amount,
                    'status'       => $p->status,
                    'payment_date' => $p->payment_date?->format('d M Y'),
                    'proof_url'    => $p->proof_path ? url('storage/payment_proofs/' . $p->proof_path) : null,
                ]);

            // Total sudah bayar tahun ini
            $paidThisYear = Payment::where('user_id', $user->id)
                ->where('status', 'confirmated')
                ->whereYear('payment_date', date('Y'))
                ->sum('amount');

            // Event mendatang
            $upcomingEvents = Event::where('start_date', '>=', now())
                ->orderBy('start_date')
                ->limit(3)
                ->get(['id', 'title', 'start_date', 'location', 'color']);

            // Pengumuman (tagihan aktif sebagai pengumuman)
            $announcements = Invoice::where('is_active', true)
                ->whereNotNull('deadline')
                ->where('deadline', '>=', now())
                ->orderBy('deadline')
                ->limit(3)
                ->get(['id', 'title', 'nominal', 'deadline', 'description']);

            return [
                'user'            => [
                    'id'     => $user->id,
                    'name'   => $user->name,
                    'rt_rw'  => $user->rt_rw,
                    'address' => $user->address,
                ],
                'stats' => [
                    'unpaid_count'   => $unpaidInvoices->count(),
                    'paid_this_year' => $paidThisYear,
                ],
                'unpaid_invoices'  => $unpaidInvoices,
                'recent_payments'  => $recentPayments,
                'upcoming_events'  => $upcomingEvents,
                'announcements'    => $announcements,
            ];
        });

        return response()->json(['success' => true, 'data' => $payload]);
    }

    /**
     * Key cache dashboard warga per user — dipakai juga oleh controller lain
     * (MidtransController, PaymentController) untuk invalidasi saat status
     * pembayaran warga tsb berubah, supaya dashboard tidak pernah basi.
     */
    public static function userDashboardCacheKey(int $userId): string
    {
        return "dashboard.user.{$userId}";
    }
}
