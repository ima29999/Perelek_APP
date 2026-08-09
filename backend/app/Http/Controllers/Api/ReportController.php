<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Expense;
use App\Models\Invoice;
use App\Models\Payment;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class ReportController extends Controller
{
    /**
     * Key cache laporan transparansi per tahun — dipakai juga oleh
     * MidtransController & MidtransService supaya begitu ada pembayaran
     * (manual atau Midtrans) yang berubah jadi 'confirmated', angka di
     * halaman "Laporan Keuangan > Transparansi" langsung ikut ter-update,
     * bukan menunggu TTL cache (90 detik) habis sendiri.
     */
    public static function transparencyCacheKey($year): string
    {
        return "reports.transparency.{$year}";
    }

    // -------------------------------------------------------------------------
    // GET /api/admin/reports/financial  - Laporan keuangan admin
    // -------------------------------------------------------------------------
    public function financial(Request $request)
    {
        $from = $request->get('from', date('Y-01-01'));
        $to   = $request->get('to', date('Y-12-31'));

        $income = Payment::where('status', 'confirmated')
            ->whereBetween('payment_date', [$from, $to])
            ->sum('amount');

        $expense = Expense::whereBetween('date', [$from, $to])
            ->sum('nominal');

        $saldo = $income - $expense;

        // Detail pembayaran
        $payments = Payment::with(['user:id,name,rt_rw', 'invoice:id,title,period'])
            ->where('status', 'confirmated')
            ->whereBetween('payment_date', [$from, $to])
            ->orderBy('payment_date')
            ->get()
            ->map(fn($p) => [
                'id'           => $p->id,
                'user'         => $p->user?->name,
                'rt_rw'        => $p->user?->rt_rw,
                'invoice'      => $p->invoice?->title,
                'period'       => $p->invoice?->period,
                'amount'       => $p->amount,
                'method'       => $p->method,
                'payment_date' => $p->payment_date?->format('d/m/Y'),
            ]);

        // Detail pengeluaran
        $expenses = Expense::with('creator:id,name')
            ->whereBetween('date', [$from, $to])
            ->orderBy('date')
            ->get()
            ->map(fn($e) => [
                'id'          => $e->id,
                'title'       => $e->title,
                'category'    => $e->category,
                'nominal'     => $e->nominal,
                'date'        => $e->date?->format('d/m/Y'),
                'description' => $e->description,
            ]);

        // Pemasukan per invoice
        $incomeByInvoice = Payment::selectRaw('invoice_id, SUM(amount) as total, COUNT(*) as count')
            ->where('status', 'confirmated')
            ->whereBetween('payment_date', [$from, $to])
            ->with('invoice:id,title,period')
            ->groupBy('invoice_id')
            ->get();

        // Pengeluaran per kategori
        $expenseByCategory = Expense::selectRaw('category, SUM(nominal) as total, COUNT(*) as count')
            ->whereBetween('date', [$from, $to])
            ->groupBy('category')
            ->orderByDesc('total')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => [
                'period'             => ['from' => $from, 'to' => $to],
                'summary'            => compact('income', 'expense', 'saldo'),
                'payments'           => $payments,
                'expenses'           => $expenses,
                'income_by_invoice'  => $incomeByInvoice,
                'expense_by_category' => $expenseByCategory,
            ],
        ]);
    }

    // -------------------------------------------------------------------------
    // GET /api/admin/reports/arrears  - Laporan tunggakan
    // -------------------------------------------------------------------------
    public function arrears(Request $request)
    {
        $invoiceId = $request->get('invoice_id');

        $query = Invoice::where('is_active', true)
            ->with(['payments' => fn($q) => $q->where('status', 'confirmated')]);

        if ($invoiceId) {
            $query->where('id', $invoiceId);
        }

        $invoices = $query->get();

        $allWarga = User::where('role', 'user')
            ->where('is_active', true)
            ->get(['id', 'name', 'rt_rw', 'address']);

        $arrearsData = [];

        foreach ($invoices as $invoice) {
            $paidUserIds = $invoice->payments->pluck('user_id')->toArray();

            $unpaidWarga = $allWarga->filter(fn($w) =>
                !in_array($w->id, $paidUserIds)
            );

            $arrearsData[] = [
                'invoice_id'    => $invoice->id,
                'invoice_title' => $invoice->title,
                'period'        => $invoice->period,
                'nominal'       => $invoice->nominal,
                'deadline'      => $invoice->deadline?->format('d/m/Y'),
                'total_warga'   => $allWarga->count(),
                'paid_count'    => count($paidUserIds),
                'unpaid_count'  => $unpaidWarga->count(),
                'unpaid_warga'  => $unpaidWarga->values(),
            ];
        }

        return response()->json([
            'success' => true,
            'data'    => $arrearsData,
        ]);
    }

    // -------------------------------------------------------------------------
    // GET /api/reports/personal  - Laporan personal warga
    // -------------------------------------------------------------------------
    public function personal(Request $request)
    {
        $user = $request->user();
        $year = $request->get('year', date('Y'));

        $payments = Payment::where('user_id', $user->id)
            ->whereYear('payment_date', $year)
            ->with('invoice:id,title,period,nominal')
            ->orderBy('payment_date')
            ->get()
            ->map(fn($p) => [
                'id'           => $p->id,
                'invoice'      => $p->invoice?->title,
                'period'       => $p->invoice?->period,
                'nominal'      => $p->invoice?->nominal,
                'amount'       => $p->amount,
                'status'       => $p->status,
                'method'       => $p->method,
                'payment_date' => $p->payment_date?->format('d M Y'),
                'proof_url'    => $p->proof_path ? url('storage/payment_proofs/' . $p->proof_path) : null,
            ]);

        $totalPaid = $payments->where('status', 'confirmated')->sum('amount');

        // Tagihan yang belum dibayar
        $unpaidInvoices = Invoice::where('is_active', true)
            ->whereDoesntHave('payments', fn($q) =>
                $q->where('user_id', $user->id)
                  ->whereIn('status', ['confirmated', 'pending'])
            )
            ->get(['id', 'title', 'period', 'nominal', 'deadline']);

        return response()->json([
            'success' => true,
            'data'    => [
                'user'           => ['id' => $user->id, 'name' => $user->name, 'rt_rw' => $user->rt_rw],
                'year'           => $year,
                'total_paid'     => $totalPaid,
                'payments'       => $payments,
                'unpaid_invoices' => $unpaidInvoices,
            ],
        ]);
    }

    // -------------------------------------------------------------------------
    // GET /api/admin/reports/transparency  - Transparansi anggaran publik
    // -------------------------------------------------------------------------
    public function transparency(Request $request)
    {
        $year = $request->get('year', date('Y'));

        $data = Cache::remember("reports.transparency.{$year}", 90, function () use ($year) {
            $monthlyData = [];
            $monthNames  = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];

            // Sebelumnya loop 1..12 menjalankan 2 query SUM terpisah per bulan
            // (total 24 query). Sekarang cukup 2 query ter-group by bulan,
            // hasilnya dicocokkan di memori — pola yang sama seperti yang sudah
            // dipakai dengan benar di DashboardController::admin().
            $incomeByMonth = Payment::selectRaw('MONTH(payment_date) as month, SUM(amount) as total')
                ->where('status', 'confirmated')
                ->whereYear('payment_date', $year)
                ->groupBy('month')
                ->pluck('total', 'month');

            $expenseByMonth = Expense::selectRaw('MONTH(date) as month, SUM(nominal) as total')
                ->whereYear('date', $year)
                ->groupBy('month')
                ->pluck('total', 'month');

            for ($m = 1; $m <= 12; $m++) {
                $income  = (float) ($incomeByMonth[$m] ?? 0);
                $expense = (float) ($expenseByMonth[$m] ?? 0);

                $monthlyData[] = [
                    'month'   => $monthNames[$m - 1],
                    'income'  => $income,
                    'expense' => $expense,
                    'surplus' => $income - $expense,
                ];
            }

            $expenseByCategory = Expense::selectRaw('category, SUM(nominal) as total')
                ->whereYear('date', $year)
                ->groupBy('category')
                ->orderByDesc('total')
                ->get();

            // Dihitung dari data bulanan yang sudah diambil di atas, tidak perlu
            // 2 query SUM tambahan untuk total tahunan.
            $totalIncome  = (float) $incomeByMonth->sum();
            $totalExpense = (float) $expenseByMonth->sum();

            return [
                'year'          => $year,
                'total_income'  => $totalIncome,
                'total_expense' => $totalExpense,
                'saldo'         => $totalIncome - $totalExpense,
                'monthly_data'  => $monthlyData,
                'expense_by_category' => $expenseByCategory,
            ];
        });

        return response()->json(['success' => true, 'data' => $data]);
    }
}
