<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\Payment;
use App\Models\Expense;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class PublicController extends Controller
{
    /**
     * GET /public/transparency
     * Statistik keuangan & komunitas yang bisa dilihat publik.
     */
    public function transparency(): JsonResponse
    {
        // Data publik yang sama untuk semua pengunjung -> aman di-cache 2 menit,
        // mengurangi beban query agregat ini dipanggil berkali-kali.
        $year = now()->year;
        $data = Cache::remember("public.transparency.{$year}", 120, function () use ($year) {
            $totalIncome = Payment::where('status', 'confirmated')
                ->whereYear('payment_date', $year)
                ->sum('amount');

            $totalExpense = Expense::whereYear('date', $year)->sum('nominal');
            $saldo = $totalIncome - $totalExpense;

            $wargaCount = User::where('is_active', true)
                ->where('role', 'user')
                ->count();

            return [
                'year'          => $year,
                'total_income'  => $totalIncome,
                'total_expense' => $totalExpense,
                'saldo'         => $saldo,
                'warga_count'   => $wargaCount,
            ];
        });

        return response()->json(['success' => true, 'data' => $data]);
    }

    /**
     * GET /public/events
     * Kegiatan mendatang yang bersifat publik.
     */
    public function events(Request $request): JsonResponse
    {
        $events = Cache::remember('public.events.upcoming', 60, function () {
            return Event::where('start_date', '>=', now())
                ->orderBy('start_date')
                ->take(10)
                ->get(['id', 'title', 'description', 'start_date', 'location', 'color']);
        });

        return response()->json([
            'success' => true,
            'data'    => $events,
        ]);
    }

    
}
