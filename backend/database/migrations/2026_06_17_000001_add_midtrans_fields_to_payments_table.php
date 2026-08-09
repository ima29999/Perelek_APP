<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // proof_path hanya wajib untuk pembayaran manual (upload bukti transfer).
        // Untuk pembayaran online via Midtrans tidak ada file yang diupload,
        // jadi kolom ini diubah menjadi nullable.
        // Pakai raw SQL (bukan ->change()) agar tidak perlu install doctrine/dbal.
        DB::statement('ALTER TABLE payments MODIFY proof_path VARCHAR(255) NULL');

        Schema::table('payments', function (Blueprint $table) {
            // Channel pembayaran: 'manual' (upload bukti) atau 'midtrans' (online)
            $table->string('channel')->default('manual')->after('method');

            // Order ID unik yang dikirim ke Midtrans, dipakai untuk mencocokkan
            // notifikasi webhook dengan record payment ini.
            $table->string('order_id')->nullable()->unique()->after('channel');

            // Snap token dari Midtrans, dipakai frontend untuk membuka halaman Snap.
            $table->string('snap_token')->nullable()->after('order_id');

            // Status transaksi mentah dari Midtrans:
            // pending / settlement / capture / deny / cancel / expire
            $table->string('gateway_status')->nullable()->after('snap_token');

            // Waktu pembayaran online dikonfirmasi sukses oleh webhook Midtrans.
            $table->timestamp('paid_at')->nullable()->after('gateway_status');
        });
    }

    public function down(): void
    {
        Schema::table('payments', function (Blueprint $table) {
            $table->dropColumn(['channel', 'order_id', 'snap_token', 'gateway_status', 'paid_at']);
        });

        DB::statement('ALTER TABLE payments MODIFY proof_path VARCHAR(255) NOT NULL');
    }
};
