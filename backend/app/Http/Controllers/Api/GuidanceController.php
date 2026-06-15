<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class GuidanceController extends Controller
{
    public function index()
    {
        $guides = [
            [
                'id'       => 1,
                'title'    => 'Cara Login',
                'category' => 'Akun',
                'content'  => 'Masukkan email dan password yang telah didaftarkan oleh admin RT. Jika lupa password, gunakan fitur "Lupa Password" untuk reset melalui email.',
                'order'    => 1,
            ],
            [
                'id'       => 2,
                'title'    => 'Cara Bayar Iuran',
                'category' => 'Pembayaran',
                'content'  => "1. Masuk ke menu 'Tagihan'\n2. Pilih tagihan yang ingin dibayar\n3. Klik 'Bayar Sekarang'\n4. Isi form: jumlah, tanggal, metode, dan upload foto bukti transfer\n5. Klik 'Submit' dan tunggu konfirmasi admin",
                'order'    => 2,
            ],
            [
                'id'       => 3,
                'title'    => 'Melihat Riwayat Pembayaran',
                'category' => 'Pembayaran',
                'content'  => "Buka menu 'Riwayat' untuk melihat semua riwayat pembayaran. Status pembayaran:\n- Pending: menunggu konfirmasi admin\n- Confirmed: pembayaran dikonfirmasi\n- Rejected: pembayaran ditolak (cek catatan untuk alasan)",
                'order'    => 3,
            ],
            [
                'id'       => 4,
                'title'    => 'Update Profil',
                'category' => 'Akun',
                'content'  => "Buka menu 'Profil' untuk memperbarui data diri seperti nomor HP, alamat, dan foto profil. Untuk keamanan, NIK hanya bisa diubah oleh admin.",
                'order'    => 4,
            ],
            [
                'id'       => 5,
                'title'    => 'Transparansi Anggaran',
                'category' => 'Keuangan',
                'content'  => "Menu 'Keuangan' menampilkan ringkasan pemasukan dan pengeluaran RT secara transparan. Warga dapat melihat alokasi dana untuk berbagai kebutuhan lingkungan.",
                'order'    => 5,
            ],
            [
                'id'       => 6,
                'title'    => 'Jadwal Kegiatan',
                'category' => 'Komunitas',
                'content'  => "Menu 'Kalender' menampilkan jadwal kegiatan RT seperti rapat, kerja bakti, dan acara komunitas. Klik pada kegiatan untuk melihat detail lokasi dan deskripsi.",
                'order'    => 6,
            ],
        ];

        return response()->json([
            'success' => true,
            'data'    => $guides,
        ]);
    }
}
