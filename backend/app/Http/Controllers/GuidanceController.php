<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;

class GuidanceController extends Controller
{
    public function index(): JsonResponse
    {
        return response()->json([
            'title' => 'Panduan Penggunaan Perelek Digital',
            'content' => [
                '1. Login menggunakan email atau nomor HP dan password.',
                '2. Sebagai warga, kirim bukti pembayaran melalui menu Pembayaran.',
                '3. Sebagai admin, verifikasi pembayaran dan catat pengeluaran.',
                '4. Gunakan menu Kalender untuk melihat jadwal kegiatan lingkungan.',
                '5. Buka Laporan untuk melihat ringkasan keuangan dan histori pembayaran.',
            ],
        ]);
    }
}
