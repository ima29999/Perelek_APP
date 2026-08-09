<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Menambahkan kolom `can_pay` pada tabel users.
 *
 * Beda dengan `is_active` (nonaktifkan akun warga secara total: tidak bisa
 * login, semua tagihan otomatis tidak muncul), `can_pay` dipakai untuk kasus
 * yang lebih spesifik: warga tetap aktif & tetap bisa login serta melihat
 * tagihannya, tapi tombol "Bayar" sengaja disembunyikan sementara oleh admin
 * dari halaman Detail Warga (mis. warga sedang kesusahan / diberi keringanan
 * sementara). Admin bisa mengaktifkannya kembali kapan saja.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->boolean('can_pay')->default(true)->after('is_active');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('can_pay');
        });
    }
};
