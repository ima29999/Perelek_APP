<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Expense;
use App\Models\Invoice;
use App\Models\Payment;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    // -------------------------------------------------------------------------
    // GET /api/admin/reports/financial  - Laporan keuangan admin
    // -------------------------------------------------------------------------
    public function financial(Request $request)
    {
        $from = $request->get('from', date('Y-01-01'));
        $to   = $request->get('to', date('Y-12-31'));

        $income = Payment::where('status', 'confirmed')
            ->whereBetween('payment_date', [$from, $to])
            ->sum('amount');

        $expense = Expense::whereBetween('date', [$from, $to])
            ->sum('nominal');

        $saldo = $income - $expense;

        // Detail pembayaran
        $payments = Payment::with(['user:id,name,rt_rw', 'invoice:id,title,period'])
            ->where('status', 'confirmed')
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
            ->where('status', 'confirmed')
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
            ->with(['payments' => fn($q) => $q->whereIn('status', ['confirmed', 'pending'])]);

        if ($invoiceId) {
            $query->where('id', $invoiceId);
        }

        $invoices = $query->get();

        $allWarga = User::where('role', 'user')
            ->where('is_active', true)
            ->get(['id', 'name', 'rt_rw', 'address']);

        $arrearsData = [];

        foreach ($invoices as $invoice) {
            $paidUserIds    = $invoice->payments->where('status', 'confirmed')->pluck('user_id')->toArray();
            $pendingUserIds = $invoice->payments->where('status', 'pending')->pluck('user_id')->toArray();

            $unpaidWarga = $allWarga->filter(fn($w) =>
                !in_array($w->id, $paidUserIds) && !in_array($w->id, $pendingUserIds)
            );

            $arrearsData[] = [
                'invoice_id'    => $invoice->id,
                'invoice_title' => $invoice->title,
                'period'        => $invoice->period,
                'nominal'       => $invoice->nominal,
                'deadline'      => $invoice->deadline?->format('d/m/Y'),
                'total_warga'   => $allWarga->count(),
                'paid_count'    => count($paidUserIds),
                'pending_count' => count($pendingUserIds),
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

        $totalPaid = $payments->where('status', 'confirmed')->sum('amount');

        // Tagihan yang belum dibayar
        $unpaidInvoices = Invoice::where('is_active', true)
            ->whereDoesntHave('payments', fn($q) =>
                $q->where('user_id', $user->id)
                  ->whereIn('status', ['confirmed', 'pending'])
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

        $monthlyData = [];
        $monthNames  = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];

        for ($m = 1; $m <= 12; $m++) {
            $income  = Payment::where('status', 'confirmed')
                ->whereYear('payment_date', $year)
                ->whereMonth('payment_date', $m)
                ->sum('amount');

            $expense = Expense::whereYear('date', $year)
                ->whereMonth('date', $m)
                ->sum('nominal');

            $monthlyData[] = [
                'month'   => $monthNames[$m - 1],
                'income'  => (float) $income,
                'expense' => (float) $expense,
                'surplus' => (float) ($income - $expense),
            ];
        }

        $expenseByCategory = Expense::selectRaw('category, SUM(nominal) as total')
            ->whereYear('date', $year)
            ->groupBy('category')
            ->orderByDesc('total')
            ->get();

        $totalIncome  = Payment::where('status', 'confirmed')->whereYear('payment_date', $year)->sum('amount');
        $totalExpense = Expense::whereYear('date', $year)->sum('nominal');

        return response()->json([
            'success' => true,
            'data'    => [
                'year'          => $year,
                'total_income'  => $totalIncome,
                'total_expense' => $totalExpense,
                'saldo'         => $totalIncome - $totalExpense,
                'monthly_data'  => $monthlyData,
                'expense_by_category' => $expenseByCategory,
            ],
        ]);
    }
}
