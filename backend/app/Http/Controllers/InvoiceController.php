<?php

namespace App\Http\Controllers;

use App\Models\Invoice;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class InvoiceController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Invoice::query();

        if (! $request->user()->isAdmin()) {
            $query->where('is_active', true);
        }

        $invoices = $query->orderByDesc('deadline')->paginate(50);

        return response()->json($invoices);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'nominal' => 'required|numeric|min:0',
            'period' => 'nullable|string|max:255',
            'deadline' => 'nullable|date',
            'is_active' => 'boolean',
        ]);

        $data['created_by'] = $request->user()->id;
        $data['is_active'] = $request->boolean('is_active', true);

        $invoice = Invoice::create($data);

        return response()->json($invoice, 201);
    }

    public function show(Invoice $invoice): JsonResponse
    {
        return response()->json($invoice);
    }

    public function update(Request $request, Invoice $invoice): JsonResponse
    {
        $data = $request->validate([
            'title' => 'sometimes|required|string|max:255',
            'description' => 'sometimes|nullable|string',
            'nominal' => 'sometimes|required|numeric|min:0',
            'period' => 'sometimes|nullable|string|max:255',
            'deadline' => 'sometimes|nullable|date',
            'is_active' => 'sometimes|boolean',
        ]);

        $invoice->update($data);

        return response()->json($invoice);
    }

    public function destroy(Invoice $invoice): JsonResponse
    {
        $invoice->delete();

        return response()->json(['message' => 'Tagihan berhasil dihapus.']);
    }
}
