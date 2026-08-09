<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Migration khusus performa: menambahkan index pada kolom-kolom yang
 * sering dipakai untuk WHERE / ORDER BY / GROUP BY di seluruh controller
 * (DashboardController, ReportController, InvoiceController, PaymentController,
 * PublicController, UserController) tapi belum punya index sebelumnya.
 * Tidak mengubah data atau struktur kolom apa pun — murni menambah index,
 * jadi 100% aman dan tidak mengubah fungsi aplikasi.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('payments', function (Blueprint $table) {
            // Dipakai di hampir semua query: where('status', ...) pada
            // dashboard, laporan, daftar pembayaran, dsb.
            $table->index('status');
            // Dipakai untuk whereYear/whereMonth/whereBetween pada tren &
            // laporan keuangan (dashboard, reports/financial, transparency).
            $table->index('payment_date');
            // Kombinasi yang sering dipakai bersama: riwayat pembayaran warga
            // tertentu difilter berdasarkan status (mis. dashboard warga).
            $table->index(['user_id', 'status']);
            // Dipakai InvoiceController::index untuk mengambil status bayar
            // per invoice pada satu warga (setelah perbaikan N+1).
            $table->index(['invoice_id', 'user_id']);
            // Dipakai MidtransController & PaymentController::adminIndex.
            $table->index('channel');
        });

        Schema::table('invoices', function (Blueprint $table) {
            // Dipakai di hampir semua query invoice aktif (dashboard, daftar
            // tagihan, laporan tunggakan).
            $table->index('is_active');
            // Dipakai untuk sort/filter jatuh tempo.
            $table->index('deadline');
        });

        Schema::table('users', function (Blueprint $table) {
            // Dipakai untuk hitung/list warga (role=user, is_active=true)
            // di hampir setiap endpoint dashboard & admin/warga.
            $table->index(['role', 'is_active']);
        });

        Schema::table('expenses', function (Blueprint $table) {
            // Dipakai untuk grouping kategori pengeluaran & filter tanggal
            // pada dashboard dan laporan keuangan.
            $table->index('category');
            $table->index('date');
        });
    }

    public function down(): void
    {
        Schema::table('payments', function (Blueprint $table) {
            $table->dropIndex(['status']);
            $table->dropIndex(['payment_date']);
            $table->dropIndex(['user_id', 'status']);
            $table->dropIndex(['invoice_id', 'user_id']);
            $table->dropIndex(['channel']);
        });

        Schema::table('invoices', function (Blueprint $table) {
            $table->dropIndex(['is_active']);
            $table->dropIndex(['deadline']);
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropIndex(['role', 'is_active']);
        });

        Schema::table('expenses', function (Blueprint $table) {
            $table->dropIndex(['category']);
            $table->dropIndex(['date']);
        });
    }
};
