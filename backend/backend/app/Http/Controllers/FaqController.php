<?php

namespace App\Http\Controllers;

use App\Models\Faq;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class FaqController extends Controller
{
    public function index(): JsonResponse
    {
        $faqs = Faq::where('is_active', true)->orderBy('id')->get();

        return response()->json($faqs);
    }

    public function show(Faq $faq): JsonResponse
    {
        return response()->json($faq);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'question' => 'required|string|max:1024',
            'answer' => 'required|string|max:2048',
            'is_active' => 'boolean',
        ]);

        $faq = Faq::create([
            'question' => $data['question'],
            'answer' => $data['answer'],
            'is_active' => $request->boolean('is_active', true),
        ]);

        return response()->json($faq, 201);
    }

    public function update(Request $request, Faq $faq): JsonResponse
    {
        $data = $request->validate([
            'question' => 'sometimes|required|string|max:1024',
            'answer' => 'sometimes|required|string|max:2048',
            'is_active' => 'sometimes|boolean',
        ]);

        $faq->update($data);

        return response()->json($faq);
    }

    public function destroy(Faq $faq): JsonResponse
    {
        $faq->delete();

        return response()->json(['message' => 'FAQ berhasil dihapus.']);
    }
}
