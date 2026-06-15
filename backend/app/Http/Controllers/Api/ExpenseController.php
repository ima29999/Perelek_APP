<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Expense;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ExpenseController extends Controller
{
    public function index(Request $request)
    {
        $query = Expense::with('creator:id,name');

        if ($category = $request->get('category')) {
            $query->where('category', $category);
        }

        if ($from = $request->get('from')) {
            $query->where('date', '>=', $from);
        }

        if ($to = $request->get('to')) {
            $query->where('date', '<=', $to);
        }

        if ($search = $request->get('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%")
                  ->orWhere('category', 'like', "%{$search}%");
            });
        }

        $expenses = $query->orderByDesc('date')
            ->paginate($request->get('per_page', 20));

        // Total untuk periode yang difilter
        $totalQuery = Expense::query();
        if ($from) $totalQuery->where('date', '>=', $from);
        if ($to)   $totalQuery->where('date', '<=', $to);
        $total = $totalQuery->sum('nominal');

        return response()->json([
            'success' => true,
            'data'    => $expenses,
            'summary' => ['total' => $total],
        ]);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'title'       => 'required|string|max:255',
            'category'    => 'required|string|max:100',
            'nominal'     => 'required|numeric|min:1',
            'description' => 'nullable|string',
            'date'        => 'required|date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal.',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $expense = Expense::create([
            'title'       => $request->title,
            'category'    => $request->category,
            'nominal'     => $request->nominal,
            'description' => $request->description,
            'date'        => $request->date,
            'created_by'  => $request->user()->id,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Pengeluaran berhasil dicatat.',
            'data'    => $expense->load('creator:id,name'),
        ], 201);
    }

    public function show(Expense $expense)
    {
        return response()->json([
            'success' => true,
            'data'    => $expense->load('creator:id,name'),
        ]);
    }

    public function update(Request $request, Expense $expense)
    {
        $validator = Validator::make($request->all(), [
            'title'       => 'sometimes|string|max:255',
            'category'    => 'sometimes|string|max:100',
            'nominal'     => 'sometimes|numeric|min:1',
            'description' => 'nullable|string',
            'date'        => 'sometimes|date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal.',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $expense->update($request->only('title', 'category', 'nominal', 'description', 'date'));

        return response()->json([
            'success' => true,
            'message' => 'Pengeluaran berhasil diperbarui.',
            'data'    => $expense->fresh()->load('creator:id,name'),
        ]);
    }

    public function destroy(Expense $expense)
    {
        $expense->delete();

        return response()->json([
            'success' => true,
            'message' => 'Pengeluaran berhasil dihapus.',
        ]);
    }
}
