<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Standardisasi nilai kolom `status` pada tabel payments.
 *
 * Sebelumnya sebagian kode memakai kata 'confirmed' dan sebagian lagi
 * 'confirmated' untuk arti yang sama (pembayaran sudah sukses/lunas),
 * sisa dari proses migrasi alur pembayaran yang belum selesai. Migration
 * ini menyeragamkan SEMUA data lama ke 'confirmated', supaya konsisten
 * dengan penamaan yang dipakai di seluruh controller & service setelah
 * alur "menunggu konfirmasi admin" dihapus:
 *
 * - Pembayaran manual (upload bukti) & pembayaran Midtrans SAMA-SAMA
 *   langsung berstatus 'confirmated' begitu berhasil, tanpa ada langkah
 *   admin mengonfirmasi secara manual di mana pun.
 * - Status 'pending' hanya dipakai sesaat selagi transaksi online masih
 *   diproses oleh Midtrans (menunggu pembayaran VA/QRIS/dll selesai),
 *   BUKAN menunggu tindakan admin.
 *
 * Migration ini tidak mengubah struktur kolom, hanya memperbaiki data.
 */
return new class extends Migration
{
    public function up(): void
    {
        DB::table('payments')
            ->where('status', 'confirmed')
            ->update(['status' => 'confirmated']);
    }

    public function down(): void
    {
        DB::table('payments')
            ->where('status', 'confirmated')
            ->update(['status' => 'confirmed']);
    }
};
