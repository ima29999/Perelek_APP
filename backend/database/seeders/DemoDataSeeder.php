<?php

namespace Database\Seeders;

use App\Models\Event;
use App\Models\Expense;
use App\Models\Faq;
use App\Models\Invoice;
use App\Models\Payment;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DemoDataSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::where('email', 'admin@perelek.local')->first();

        $wargas = [
            ['name' => 'Budi Santoso',  'email' => 'budi@example.com',    'rt_rw' => 'RT 01/RW 05', 'address' => 'Jl. Mawar No. 12'],
            ['name' => 'Siti Rahayu',   'email' => 'siti@example.com',    'rt_rw' => 'RT 01/RW 05', 'address' => 'Jl. Mawar No. 14'],
            ['name' => 'Ahmad Fauzi',   'email' => 'ahmad@example.com',   'rt_rw' => 'RT 01/RW 05', 'address' => 'Jl. Melati No. 3'],
            ['name' => 'Dewi Kusuma',   'email' => 'dewi@example.com',    'rt_rw' => 'RT 01/RW 05', 'address' => 'Jl. Melati No. 5'],
            ['name' => 'Hendra Wijaya', 'email' => 'hendra@example.com',  'rt_rw' => 'RT 01/RW 05', 'address' => 'Jl. Anggrek No. 8'],
            ['name' => 'Rina Wati',     'email' => 'rina@example.com',    'rt_rw' => 'RT 01/RW 05', 'address' => 'Jl. Anggrek No. 10'],
            ['name' => 'Joko Susanto',  'email' => 'joko@example.com',    'rt_rw' => 'RT 01/RW 05', 'address' => 'Jl. Dahlia No. 2'],
            ['name' => 'Lestari Indah', 'email' => 'lestari@example.com', 'rt_rw' => 'RT 01/RW 05', 'address' => 'Jl. Dahlia No. 4'],
        ];

        $createdWargas = [];
        foreach ($wargas as $wdata) {
            $createdWargas[] = User::firstOrCreate(
                ['email' => $wdata['email']],
                array_merge($wdata, [
                    'password'  => Hash::make('password123'),
                    'role'      => 'user',
                    'phone'     => '08' . rand(100000000, 999999999),
                    'nik'       => '3204' . rand(100000000000, 999999999999),
                    'is_active' => true,
                ])
            );
        }

        $bulan = [
            ['nama' => 'Januari', 'num' => '01'],
            ['nama' => 'Februari','num' => '02'],
            ['nama' => 'Maret',   'num' => '03'],
            ['nama' => 'April',   'num' => '04'],
            ['nama' => 'Mei',     'num' => '05'],
            ['nama' => 'Juni',    'num' => '06'],
        ];

        $invoices = [];
        foreach ($bulan as $b) {
            $invoices[] = Invoice::firstOrCreate(
                ['title' => 'Iuran Keamanan ' . $b['nama'] . ' 2025'],
                [
                    'description' => 'Iuran keamanan lingkungan RT bulan ' . $b['nama'],
                    'nominal'     => 50000,
                    'period'      => $b['nama'] . ' 2025',
                    'deadline'    => '2025-' . $b['num'] . '-10',
                    'created_by'  => $admin->id,
                    'is_active'   => true,
                ]
            );
        }

        $invoices[] = Invoice::firstOrCreate(
            ['title' => 'Iuran Kebersihan Q1 2025'],
            ['description' => 'Triwulan 1', 'nominal' => 75000, 'period' => 'Q1 2025',
             'deadline' => '2025-03-31', 'created_by' => $admin->id, 'is_active' => true]
        );

        $invoices[] = Invoice::firstOrCreate(
            ['title' => 'Kas RT Tahunan 2025'],
            ['description' => 'Kas tahunan', 'nominal' => 150000, 'period' => 'Tahunan 2025',
             'deadline' => '2025-01-31', 'created_by' => $admin->id, 'is_active' => true]
        );

        $methods  = ['transfer', 'tunai', 'qris'];
        $statuses = ['confirmed', 'confirmed', 'confirmed', 'pending', 'rejected'];

        foreach ($createdWargas as $warga) {
            foreach (array_slice($invoices, 0, 5) as $invoice) {
                if (rand(0, 10) > 2) {
                    $status = $statuses[array_rand($statuses)];
                    Payment::firstOrCreate(
                        ['invoice_id' => $invoice->id, 'user_id' => $warga->id],
                        [
                            'amount'       => $invoice->nominal,
                            'payment_date' => now()->subDays(rand(1, 60))->format('Y-m-d'),
                            'method'       => $methods[array_rand($methods)],
                            'proof_path'   => 'demo_' . $warga->id . '_' . $invoice->id . '.jpg',
                            'status'       => $status,
                            'verified_by'  => in_array($status, ['confirmed','rejected']) ? $admin->id : null,
                            'notes'        => $status === 'rejected' ? 'Bukti tidak jelas' : null,
                        ]
                    );
                }
            }
        }

        $expenseData = [
            ['title' => 'Pengecatan Pos Ronda',     'category' => 'Keamanan',     'nominal' => 350000,  'date' => '2025-01-15'],
            ['title' => 'Lampu Jalan Baru',         'category' => 'Infrastruktur','nominal' => 850000,  'date' => '2025-02-01'],
            ['title' => 'Alat Kebersihan',          'category' => 'Kebersihan',   'nominal' => 120000,  'date' => '2025-02-10'],
            ['title' => 'Kegiatan 17 Agustus',      'category' => 'Kegiatan',     'nominal' => 1200000, 'date' => '2025-08-10'],
            ['title' => 'Bensin Genset',            'category' => 'Operasional',  'nominal' => 200000,  'date' => '2025-03-05'],
            ['title' => 'ATK Administrasi RT',      'category' => 'Administrasi', 'nominal' => 85000,   'date' => '2025-03-20'],
            ['title' => 'Perbaikan Jalan Berlubang','category' => 'Infrastruktur','nominal' => 500000,  'date' => '2025-04-12'],
            ['title' => 'Hadiah Lomba Anak',        'category' => 'Kegiatan',     'nominal' => 300000,  'date' => '2025-08-17'],
        ];

        foreach ($expenseData as $exp) {
            Expense::firstOrCreate(
                ['title' => $exp['title'], 'date' => $exp['date']],
                array_merge($exp, ['created_by' => $admin->id])
            );
        }

        $eventData = [
            ['title' => 'Rapat RT Bulanan',       'description' => 'Rapat koordinasi bulanan', 'location' => 'Balai RT',       'start_date' => now()->addDays(5)->format('Y-m-d H:i:s'),  'color' => '#3B82F6'],
            ['title' => 'Kerja Bakti Lingkungan', 'description' => 'Gotong royong kebersihan',  'location' => 'Seluruh area RT','start_date' => now()->addDays(12)->format('Y-m-d H:i:s'), 'color' => '#10B981'],
            ['title' => 'Posyandu Rutin',         'description' => 'Posyandu balita dan lansia','location' => 'Rumah Bu PKK',   'start_date' => now()->addDays(20)->format('Y-m-d H:i:s'), 'color' => '#F59E0B'],
            ['title' => 'Lomba 17 Agustus',       'description' => 'Lomba HUT RI',              'location' => 'Lapangan RT',    'start_date' => now()->addMonths(2)->format('Y-m-17 08:00:00'), 'color' => '#EF4444'],
        ];

        foreach ($eventData as $ev) {
            Event::firstOrCreate(
                ['title' => $ev['title']],
                array_merge($ev, ['created_by' => $admin->id])
            );
        }

        $faqData = [
            ['question' => 'Bagaimana cara membayar iuran RT?',     'answer' => 'Bayar via aplikasi dengan upload bukti transfer, atau langsung ke bendahara RT. Metode: transfer bank, tunai, QRIS.', 'category' => 'Pembayaran', 'order' => 1],
            ['question' => 'Kapan batas waktu pembayaran iuran?',    'answer' => 'Batas waktu umumnya tanggal 10 setiap bulan. Lihat deadline di detail masing-masing tagihan.',                      'category' => 'Pembayaran', 'order' => 2],
            ['question' => 'Bagaimana jika pembayaran saya ditolak?','answer' => 'Anda mendapat notifikasi beserta alasan. Kirim ulang bukti yang lebih jelas atau hubungi admin RT.',               'category' => 'Pembayaran', 'order' => 3],
            ['question' => 'Bagaimana cara mendaftar akun?',         'answer' => 'Akun dibuat oleh admin RT. Hubungi ketua atau sekretaris RT untuk mendaftar dan mendapatkan akses login.',          'category' => 'Akun',       'order' => 4],
            ['question' => 'Bagaimana cara reset password?',         'answer' => 'Klik "Lupa Password" di halaman login, masukkan email, ikuti instruksi yang dikirim ke email Anda.',               'category' => 'Akun',       'order' => 5],
            ['question' => 'Apakah data saya aman?',                 'answer' => 'Ya. Data sensitif (NIK, nomor HP) dienkripsi AES-256. Kami menjaga privasi seluruh warga.',                        'category' => 'Keamanan',   'order' => 6],
            ['question' => 'Bagaimana melihat transparansi keuangan?','answer' => 'Buka menu Laporan Keuangan untuk melihat ringkasan pemasukan dan pengeluaran RT secara transparan.',              'category' => 'Keuangan',   'order' => 7],
        ];

        foreach ($faqData as $faq) {
            Faq::firstOrCreate(
                ['question' => $faq['question']],
                array_merge($faq, ['is_active' => true])
            );
        }
    }
}
