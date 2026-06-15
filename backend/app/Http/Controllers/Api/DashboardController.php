<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Expense;
use App\Models\Invoice;
use App\Models\Payment;
use App\Models\User;
use App\Models\Event;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    // -------------------------------------------------------------------------
    // GET /api/admin/dashboard
    // -------------------------------------------------------------------------
    public function admin(Request $request)
    {
        $year  = $request->get('year', date('Y'));
        $month = $request->get('month');

        // ---- Statistik Utama ----
        $totalWarga  = User::where('role', 'user')->where('is_active', true)->count();
        $totalIncome = Payment::where('status', 'confirmed')->sum('amount');
        $totalExpense = Expense::sum('nominal');
        $saldo       = $totalIncome - $totalExpense;

        // ---- Pembayaran pending ----
        $pendingCount = Payment::where('status', 'pending')->count();

        // ---- Tren Pemasukan per Bulan (tahun berjalan) ----
        $incomeTrend = Payment::selectRaw('MONTH(payment_date) as month, SUM(amount) as total')
            ->where('status', 'confirmed')
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
            ->withCount(['payments as paid_count' => fn($q) => $q->where('status', 'confirmed')])
            ->latest()
            ->limit(5)
            ->get();

        // ---- Kategori pengeluaran ----
        $expenseByCategory = Expense::selectRaw('category, SUM(nominal) as total')
            ->groupBy('category')
            ->orderByDesc('total')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => [
                'stats' => [
                    'total_warga'    => $totalWarga,
                    'total_income'   => $totalIncome,
                    'total_expense'  => $totalExpense,
                    'saldo'          => $saldo,
                    'pending_payments' => $pendingCount,
                ],
                'trend_data'          => $trendData,
                'recent_payments'     => $recentPayments,
                'recent_warga'        => $recentWarga,
                'active_invoices'     => $activeInvoices,
                'expense_by_category' => $expenseByCategory,
            ],
        ]);
    }

    // -------------------------------------------------------------------------
    // GET /api/dashboard  - Dashboard warga
    // -------------------------------------------------------------------------
    public function user(Request $request)
    {
        $user = $request->user();

        // Tagihan aktif belum dibayar
        $unpaidInvoices = Invoice::where('is_active', true)
            ->whereDoesntHave('payments', fn($q) =>
                $q->where('user_id', $user->id)
                  ->whereIn('status', ['pending', 'confirmed'])
            )
            ->orderBy('deadline')
            ->get(['id', 'title', 'nominal', 'period', 'deadline']);

        // Tagihan pending (menunggu konfirmasi)
        $pendingPayments = Payment::where('user_id', $user->id)
            ->where('status', 'pending')
            ->with('invoice:id,title,period')
            ->latest()
            ->get();

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
            ->where('status', 'confirmed')
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

        return response()->json([
            'success' => true,
            'data'    => [
                'user'            => [
                    'id'     => $user->id,
                    'name'   => $user->name,
                    'rt_rw'  => $user->rt_rw,
                    'address' => $user->address,
                ],
                'stats' => [
                    'unpaid_count'   => $unpaidInvoices->count(),
                    'pending_count'  => $pendingPayments->count(),
                    'paid_this_year' => $paidThisYear,
                ],
                'unpaid_invoices'  => $unpaidInvoices,
                'pending_payments' => $pendingPayments,
                'recent_payments'  => $recentPayments,
                'upcoming_events'  => $upcomingEvents,
                'announcements'    => $announcements,
            ],
        ]);
    }
}
