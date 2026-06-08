<?php

namespace App\Http\Controllers;

use App\Models\Expense;
use App\Models\Invoice;
use App\Models\Payment;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class ReportController extends Controller
{
    public function financial(Request $request): JsonResponse
    {
        $period = $request->validate([
            'from' => 'sometimes|date',
            'to' => 'sometimes|date|after_or_equal:from',
        ]);

        $from = $period['from'] ?? now()->startOfYear()->toDateString();
        $to = $period['to'] ?? now()->endOfYear()->toDateString();

        $income = Payment::where('status', 'lunas')
            ->whereBetween('payment_date', [$from, $to])
            ->sum('amount');

        $expenses = Expense::whereBetween('expense_date', [$from, $to])->sum('amount');
        $balance = $income - $expenses;

        $payments = Payment::with('user', 'invoice')
            ->where('status', 'lunas')
            ->whereBetween('payment_date', [$from, $to])
            ->paginate(50);

        return response()->json([
            'from' => $from,
            'to' => $to,
            'income' => $income,
            'expenses' => $expenses,
            'balance' => $balance,
            'payments' => $payments,
        ]);
    }

    public function arrears(): JsonResponse
    {
        $users = User::where('role', 'user')
            ->with(['payments' => function ($query) {
                $query->where('status', 'pending');
            }])
            ->whereHas('payments', function ($query) {
                $query->where('status', 'pending');
            })
            ->paginate(50);

        return response()->json($users);
    }

    public function personal(Request $request): JsonResponse
    {
        $user = $request->user();

        $payments = Payment::with('invoice')
            ->where('user_id', $user->id)
            ->orderByDesc('payment_date')
            ->paginate(50);

        return response()->json([
            'user' => $user,
            'payments' => $payments,
        ]);
    }
}
