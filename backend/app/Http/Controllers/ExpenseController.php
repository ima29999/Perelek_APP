<?php

namespace App\Http\Controllers;

use App\Models\Expense;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Http\JsonResponse;

class ExpenseController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Expense::query();

        if (! $request->user()->isAdmin()) {
            $query->whereNotNull('id');
        }

        $expenses = $query->orderByDesc('expense_date')->paginate(50);

        return response()->json($expenses);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'category' => 'required|string|max:255',
            'description' => 'nullable|string',
            'amount' => 'required|numeric|min:0',
            'expense_date' => 'required|date',
            'receipt' => 'nullable|image|mimes:jpg,jpeg,png|max:5120',
        ]);

        if ($request->hasFile('receipt')) {
            $data['receipt_path'] = $request->file('receipt')->store('expense_receipts', 'public');
        }

        $data['created_by'] = $request->user()->id;

        $expense = Expense::create($data);

        return response()->json($expense, 201);
    }

    public function show(Expense $expense): JsonResponse
    {
        return response()->json($expense);
    }

    public function update(Request $request, Expense $expense): JsonResponse
    {
        $data = $request->validate([
            'category' => 'sometimes|required|string|max:255',
            'description' => 'sometimes|nullable|string',
            'amount' => 'sometimes|required|numeric|min:0',
            'expense_date' => 'sometimes|required|date',
            'receipt' => 'sometimes|nullable|image|mimes:jpg,jpeg,png|max:5120',
        ]);

        if ($request->hasFile('receipt')) {
            Storage::disk('public')->delete($expense->receipt_path);
            $data['receipt_path'] = $request->file('receipt')->store('expense_receipts', 'public');
        }

        $expense->update($data);

        return response()->json($expense);
    }

    public function destroy(Expense $expense): JsonResponse
    {
        Storage::disk('public')->delete($expense->receipt_path);
        $expense->delete();

        return response()->json(['message' => 'Pengeluaran berhasil dihapus.']);
    }
}
