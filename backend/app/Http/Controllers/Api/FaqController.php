<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Faq;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class FaqController extends Controller
{
    public function index(Request $request)
    {
        $query = Faq::query();

        if ($request->has('is_active')) {
            $query->where('is_active', (bool) $request->is_active);
        } else {
            // Publik hanya lihat aktif
            if (!$request->user() || $request->user()->role !== 'admin') {
                $query->where('is_active', true);
            }
        }

        if ($category = $request->get('category')) {
            $query->where('category', $category);
        }

        $faqs = $query->orderBy('order')->orderBy('id')->get();

        return response()->json([
            'success' => true,
            'data'    => $faqs,
        ]);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'question' => 'required|string|max:500',
            'answer'   => 'required|string',
            'category' => 'nullable|string|max:100',
            'order'    => 'nullable|integer|min:0',
            'is_active' => 'boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal.',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $faq = Faq::create($request->only('question', 'answer', 'category', 'order', 'is_active'));

        return response()->json([
            'success' => true,
            'message' => 'FAQ berhasil ditambahkan.',
            'data'    => $faq,
        ], 201);
    }

    public function show(Faq $faq)
    {
        return response()->json(['success' => true, 'data' => $faq]);
    }

    public function update(Request $request, Faq $faq)
    {
        $validator = Validator::make($request->all(), [
            'question'  => 'sometimes|string|max:500',
            'answer'    => 'sometimes|string',
            'category'  => 'nullable|string|max:100',
            'order'     => 'nullable|integer|min:0',
            'is_active' => 'boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal.',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $faq->update($request->only('question', 'answer', 'category', 'order', 'is_active'));

        return response()->json([
            'success' => true,
            'message' => 'FAQ berhasil diperbarui.',
            'data'    => $faq->fresh(),
        ]);
    }

    public function destroy(Faq $faq)
    {
        $faq->delete();

        return response()->json([
            'success' => true,
            'message' => 'FAQ berhasil dihapus.',
        ]);
    }
}
