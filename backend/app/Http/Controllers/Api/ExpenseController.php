<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Expense;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;
use Carbon\Carbon;

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

        $totalQuery = Expense::query();
        if ($from) $totalQuery->where('date', '>=', $from);
        if ($to)   $totalQuery->where('date', '<=', $to);
        $total = $totalQuery->sum('nominal');

        return response()->json([
            'success' => true,
            'data'    => $expenses,
            'summary' => [
                'total' => (double) $total
            ]
        ]);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'title'       => 'required|string|max:255',
            'category'    => 'required|string|max:100',
            'nominal'     => 'required|numeric|min:1',
            'description' => 'nullable|string',
            'date'        => 'required|date', // 🌟 DIUBAH: Menggunakan date biasa agar toleran terhadap segala format
            'image'       => 'nullable|image|mimes:jpeg,png,jpg,webp|max:4096',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal.',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $data = $request->only('title', 'category', 'nominal', 'description');
        $data['created_by'] = $request->user()?->id;
        
        // 🌟 Paksa Carbon mengubah string tanggal dari Flutter menjadi format Y-m-d murni
        $data['date'] = Carbon::parse($request->date)->format('Y-m-d');

        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('expenses', 'public');
            $data['image'] = $path;
        }

        $expense = Expense::create($data);

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
            'date'        => 'sometimes|date', // 🌟 DIUBAH: Menggunakan date biasa agar toleran terhadap segala format
            'image'       => 'nullable|image|mimes:jpeg,png,jpg,webp|max:4096',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal.',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $data = $request->only('title', 'category', 'nominal', 'description');

        if ($request->has('date')) {
            // 🌟 Paksa Carbon mengubah string tanggal dari Flutter menjadi format Y-m-d murni
            $data['date'] = Carbon::parse($request->date)->format('Y-m-d');
        }

        if ($request->hasFile('image')) {
            if ($expense->image) {
                Storage::disk('public')->delete($expense->image);
            }
            $path = $request->file('image')->store('expenses', 'public');
            $data['image'] = $path;
        }

        $expense->update($data);

        return response()->json([
            'success' => true,
            'message' => 'Pengeluaran berhasil diperbarui.',
            'data'    => $expense->fresh()->load('creator:id,name'),
        ]);
    }

    public function destroy(Expense $expense)
    {
        if ($expense->image) {
            Storage::disk('public')->delete($expense->image);
        }
        
        $expense->delete();

        return response()->json([
            'success' => true,
            'message' => 'Pengeluaran berhasil dihapus.',
        ]);
    }
}