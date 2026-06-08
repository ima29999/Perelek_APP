<?php

namespace App\Http\Controllers;

use App\Models\Expense;
use App\Models\Invoice;
use App\Models\Payment;
use App\Models\Event;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class DashboardController extends Controller
{
    public function admin(Request $request): JsonResponse
    {
        $totalUsers = 
            \App\Models\User::count();
        $totalIncome = Payment::where('status', 'lunas')->sum('amount');
        $totalExpenses = Expense::sum('amount');
        $pendingPayments = Payment::where('status', 'pending')->count();
        $cashBalance = $totalIncome - $totalExpenses;
        $monthlyPayments = Payment::where('status', 'lunas')
            ->whereYear('payment_date', now()->year)
            ->selectRaw('MONTH(payment_date) as month, SUM(amount) as total')
            ->groupBy('month')
            ->orderBy('month')
            ->get();
        $recentPayments = Payment::with('user')->latest()->take(5)->get();

        return response()->json([
            'total_users' => $totalUsers,
            'total_income' => $totalIncome,
            'total_expenses' => $totalExpenses,
            'cash_balance' => $cashBalance,
            'pending_payments' => $pendingPayments,
            'monthly_payments' => $monthlyPayments,
            'recent_payments' => $recentPayments,
        ]);
    }

    public function user(Request $request): JsonResponse
    {
        $user = $request->user();
        $pending = Payment::where('user_id', $user->id)->where('status', 'pending')->count();
        $lastPayments = Payment::where('user_id', $user->id)->latest('payment_date')->take(5)->get();
        $unpaidInvoices = Invoice::where('is_active', true)
            ->whereDoesntHave('payments', function ($query) use ($user) {
                $query->where('user_id', $user->id)->where('status', 'lunas');
            })
            ->get();
        $events = Event::where('is_active', true)->orderBy('event_date')->take(5)->get();

        return response()->json([
            'user' => $user,
            'pending_payments' => $pending,
            'recent_payments' => $lastPayments,
            'unpaid_invoices' => $unpaidInvoices,
            'events' => $events,
        ]);
    }
}
