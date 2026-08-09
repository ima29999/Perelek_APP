<?php

namespace Database\Seeders;

use App\Models\Event;
use App\Models\Expense;
use App\Models\Faq;
use App\Models\Invoice;
use App\Models\Payment;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

/**
 * DemoDataSeeder
 * ---------------------------------------------------------------------
 * Data dummy untuk periode Januari 2024 - Juni 2026 (tidak melebihi
 * kondisi "hari ini", karena tanggal berjalan baru sampai Juli 2026).
 *
 * Ketentuan (sesuai permintaan):
 * - Jumlah warga: 30 (dihitung per Kartu Keluarga, 1 akun = 1 KK).
 * - Nominal tagihan dummy maksimal Rp30.000 (contoh: iuran sampah
 *   mingguan Rp5.000).
 * - SEMUA tagihan pada periode ini sudah LUNAS (status confirmated),
 *   supaya admin bisa menambahkan pembayaran baru secara manual untuk
 *   mensimulasikan tunggakan/pembayaran real.
 *
 * Jenis tagihan yang dibuat:
 * 1. Iuran Sampah      - mingguan  - Rp5.000
 * 2. Iuran Keamanan    - bulanan   - Rp25.000
 * 3. Iuran Kas RT      - bulanan   - Rp15.000
 * 4. Iuran Kebersihan  - triwulan  - Rp30.000
 */
class DemoDataSeeder extends Seeder
{
    private const YEAR_START = 2024;
    private const YEAR_END   = 2026;
    // Data hanya dibuat sampai bulan ini pada YEAR_END, supaya tidak
    // melebihi kondisi "hari ini" (sekarang baru berjalan sampai Juli 2026).
    private const YEAR_END_MONTH = 6; // Juni 2026

    public function run(): void
    {
        $admin = User::where('email', 'admin@gmail.com')->first();

        if (!$admin) {
            $admin = User::firstOrCreate(
                ['email' => 'admin@gmail.com'],
                [
                    'name'      => 'Admin RT',
                    'password'  => Hash::make('password123'),
                    'role'      => 'admin',
                    'phone'     => '081234567890',
                    'nik'       => '3204000000000000',
                    'is_active' => true,
                    'rt_rw'     => 'RT 01/RW 05',
                    'address'   => 'Pos Sekretariat RT',
                ]
            );
        }

        $wargas = $this->createWargas();

        $methods = ['transfer', 'tunai', 'qris'];

        $invoiceRows = [];
        $paymentRows = [];
        $now = Carbon::now();

        for ($year = self::YEAR_START; $year <= self::YEAR_END; $year++) {

            // Bulan terakhir yang dipakai pada tahun berjalan ini (Desember
            // untuk tahun-tahun sebelum YEAR_END, dibatasi ke YEAR_END_MONTH
            // untuk tahun YEAR_END agar tidak melebihi periode berjalan).
            $maxMonth = ($year === self::YEAR_END) ? self::YEAR_END_MONTH : 12;
            $yearCap  = Carbon::create($year, $maxMonth, 1)->endOfMonth();

            // -----------------------------------------------------------
            // 1. IURAN SAMPAH - MINGGUAN - Rp5.000
            // -----------------------------------------------------------
            $weekStart = Carbon::create($year, 1, 1);
            $weekNum = 1;
            while ($weekStart->year === $year && $weekStart->lessThanOrEqualTo($yearCap)) {
                $weekEnd = $weekStart->copy()->addDays(6);

                $title = 'Iuran Sampah Minggu ke-' . $weekNum . ' ' . $year;
                $invoiceRows[] = [
                    'key'         => $title,
                    'title'       => $title,
                    'description' => 'Iuran pengangkutan sampah warga periode ' .
                        $weekStart->format('d M') . ' - ' . $weekEnd->format('d M Y'),
                    'nominal'     => 5000,
                    'period'      => $weekStart->format('d/m/Y') . ' - ' . $weekEnd->format('d/m/Y'),
                    'deadline'    => $weekEnd->format('Y-m-d'),
                    'created_by'  => $admin->id,
                    'is_active'   => $year < self::YEAR_END || $weekStart->lessThanOrEqualTo($now),
                    'created_at'  => $weekStart,
                    'updated_at'  => $weekStart,
                ];

                $weekStart = $weekStart->copy()->addDays(7);
                $weekNum++;
            }

            // -----------------------------------------------------------
            // 2 & 3. IURAN KEAMANAN & KAS RT - BULANAN
            // -----------------------------------------------------------
            for ($month = 1; $month <= $maxMonth; $month++) {
                $bulanCarbon = Carbon::create($year, $month, 1);
                $namaBulan   = $bulanCarbon->translatedFormat('F');
                $deadline    = $bulanCarbon->copy()->endOfMonth()->subDays(2);

                $titleKeamanan = 'Iuran Keamanan ' . $namaBulan . ' ' . $year;
                $invoiceRows[] = [
                    'key'         => $titleKeamanan,
                    'title'       => $titleKeamanan,
                    'description' => 'Iuran keamanan lingkungan RT bulan ' . $namaBulan . ' ' . $year,
                    'nominal'     => 25000,
                    'period'      => $namaBulan . ' ' . $year,
                    'deadline'    => $deadline->format('Y-m-d'),
                    'created_by'  => $admin->id,
                    'is_active'   => true,
                    'created_at'  => $bulanCarbon,
                    'updated_at'  => $bulanCarbon,
                ];

                $titleKas = 'Iuran Kas RT ' . $namaBulan . ' ' . $year;
                $invoiceRows[] = [
                    'key'         => $titleKas,
                    'title'       => $titleKas,
                    'description' => 'Iuran kas RT bulan ' . $namaBulan . ' ' . $year,
                    'nominal'     => 15000,
                    'period'      => $namaBulan . ' ' . $year,
                    'deadline'    => $deadline->format('Y-m-d'),
                    'created_by'  => $admin->id,
                    'is_active'   => true,
                    'created_at'  => $bulanCarbon,
                    'updated_at'  => $bulanCarbon,
                ];
            }

            // -----------------------------------------------------------
            // 4. IURAN KEBERSIHAN - TRIWULAN - Rp30.000
            // -----------------------------------------------------------
            $maxQuarter = intdiv($maxMonth, 3);
            for ($q = 1; $q <= $maxQuarter; $q++) {
                $bulanAkhirQ = $q * 3;
                $deadline    = Carbon::create($year, $bulanAkhirQ, 1)->endOfMonth();

                $titleKebersihan = 'Iuran Kebersihan Q' . $q . ' ' . $year;
                $invoiceRows[] = [
                    'key'         => $titleKebersihan,
                    'title'       => $titleKebersihan,
                    'description' => 'Iuran kebersihan lingkungan triwulan ' . $q . ' tahun ' . $year,
                    'nominal'     => 30000,
                    'period'      => 'Q' . $q . ' ' . $year,
                    'deadline'    => $deadline->format('Y-m-d'),
                    'created_by'  => $admin->id,
                    'is_active'   => true,
                    'created_at'  => $deadline->copy()->subMonths(2)->startOfMonth(),
                    'updated_at'  => $deadline->copy()->subMonths(2)->startOfMonth(),
                ];
            }
        }

        // -----------------------------------------------------------------
        // Insert semua invoice (bulk, chunked) lalu ambil id-nya kembali
        // -----------------------------------------------------------------
        $invoiceKeyToId = [];
        $chunks = array_chunk($invoiceRows, 200);
        foreach ($chunks as $chunk) {
            $insertData = array_map(function ($row) {
                unset($row['key']);
                return $row;
            }, $chunk);
            Invoice::insert($insertData);
        }

        // Ambil ulang semua invoice untuk mapping title -> id (title dibuat unik)
        $allInvoices = Invoice::whereIn('title', array_column($invoiceRows, 'title'))
            ->get(['id', 'title', 'nominal', 'deadline']);
        foreach ($allInvoices as $inv) {
            $invoiceKeyToId[$inv->title] = $inv;
        }

        // -----------------------------------------------------------------
        // Generate pembayaran: SEMUA LUNAS (confirmated) untuk seluruh warga
        // & seluruh tagihan periode 2024 - 2026, agar admin tinggal
        // menambahkan pembayaran baru secara manual dari sini.
        // -----------------------------------------------------------------
        $proofCounter = 1;
        foreach ($invoiceRows as $row) {
            $inv = $invoiceKeyToId[$row['title']] ?? null;
            if (!$inv) {
                continue;
            }

            $deadlineCarbon = Carbon::parse($inv->deadline);

            foreach ($wargas as $warga) {
                $paymentDate = $deadlineCarbon->copy()->subDays(rand(1, 6));

                $paymentRows[] = [
                    'invoice_id'     => $inv->id,
                    'user_id'        => $warga->id,
                    'amount'         => $inv->nominal,
                    'payment_date'   => $paymentDate->format('Y-m-d'),
                    'method'         => $methods[array_rand($methods)],
                    'channel'        => 'manual',
                    'proof_path'     => 'demo_bukti_' . $proofCounter++ . '.jpg',
                    'status'         => 'confirmated',
                    'notes'          => null,
                    'verified_by'    => $admin->id,
                    'created_at'     => $paymentDate,
                    'updated_at'     => $paymentDate->copy()->addHours(rand(1, 20)),
                ];
            }
        }

        foreach (array_chunk($paymentRows, 500) as $chunk) {
            Payment::insert($chunk);
        }

        // -----------------------------------------------------------------
        // 5. PENGELUARAN (EXPENSES) & 6. EVENTS - 2024 s.d. Juni 2026
        // -----------------------------------------------------------------
        $dataCutoff = Carbon::create(self::YEAR_END, self::YEAR_END_MONTH, 1)->endOfMonth();

        for ($year = self::YEAR_START; $year <= self::YEAR_END; $year++) {
            $expenseData = [
                ['title' => 'Pengangkutan & Pengelolaan Sampah ' . $year, 'category' => 'Kebersihan',    'nominal' => rand(150000, 250000), 'date' => $year . '-01-20'],
                ['title' => 'Pengecatan Pos Ronda ' . $year,              'category' => 'Keamanan',      'nominal' => rand(300000, 450000), 'date' => $year . '-02-05'],
                ['title' => 'Lampu Jalan Pemukiman ' . $year,             'category' => 'Infrastruktur', 'nominal' => rand(700000, 900000), 'date' => $year . '-03-01'],
                ['title' => 'Pembelian Alat Kebersihan ' . $year,         'category' => 'Kebersihan',    'nominal' => rand(100000, 150000), 'date' => $year . '-04-10'],
                ['title' => 'Service & Bensin Genset ' . $year,           'category' => 'Operasional',   'nominal' => rand(150000, 250000), 'date' => $year . '-05-15'],
                ['title' => 'ATK dan Cetak Surat RT ' . $year,            'category' => 'Administrasi',  'nominal' => rand(50000, 100000),  'date' => $year . '-06-20'],
                ['title' => 'Semen Tambal Jalan RT ' . $year,             'category' => 'Infrastruktur', 'nominal' => rand(400000, 600000), 'date' => $year . '-07-12'],
                ['title' => 'Subsidi Lomba Kemerdekaan ' . $year,         'category' => 'Kegiatan',      'nominal' => rand(1000000, 1500000), 'date' => $year . '-08-12'],
                ['title' => 'Fogging Nyamuk DBD ' . $year,                'category' => 'Kesehatan',     'nominal' => rand(200000, 350000), 'date' => $year . '-10-05'],
                ['title' => 'Konsumsi Rapat Warga Akhir Tahun ' . $year,  'category' => 'Kegiatan',      'nominal' => rand(300000, 500000), 'date' => $year . '-12-15'],
            ];

            foreach ($expenseData as $exp) {
                if (Carbon::parse($exp['date'])->greaterThan($dataCutoff)) {
                    continue; // lewati data yang jatuh setelah Juni 2026
                }
                Expense::firstOrCreate(
                    ['title' => $exp['title'], 'date' => $exp['date']],
                    array_merge($exp, ['created_by' => $admin->id])
                );
            }

            // -------------------------------------------------------------
            // 6. AGENDA / KEGIATAN (EVENTS)
            // -------------------------------------------------------------
            $eventData = [
                ['title' => 'Rapat Awal Tahun ' . $year,            'description' => 'Musyawarah program kerja RT tahun ' . $year,        'location' => 'Balai RT',           'start_date' => $year . '-01-08 19:30:00', 'color' => '#3B82F6'],
                ['title' => 'Jadwal Pengangkutan Sampah ' . $year,  'description' => 'Sosialisasi jadwal & tarif iuran sampah mingguan',   'location' => 'Pos Ronda',          'start_date' => $year . '-01-15 16:00:00', 'color' => '#84CC16'],
                ['title' => 'Kerja Bakti Masal ' . $year,           'description' => 'Pembersihan saluran air menyambut musim hujan',     'location' => 'Seluruh Area RT',    'start_date' => $year . '-04-12 07:00:00', 'color' => '#10B981'],
                ['title' => 'Festival HUT RI Ke-' . ($year - 1945), 'description' => 'Perayaan perlombaan tradisional warga',              'location' => 'Lapangan RT',        'start_date' => $year . '-08-17 08:00:00', 'color' => '#EF4444'],
                ['title' => 'Fogging Nyamuk DBD ' . $year,          'description' => 'Penyemprotan massal pencegahan demam berdarah',      'location' => 'Rumah Warga RT',     'start_date' => $year . '-10-05 09:00:00', 'color' => '#F59E0B'],
            ];

            foreach ($eventData as $ev) {
                if (Carbon::parse($ev['start_date'])->greaterThan($dataCutoff)) {
                    continue; // lewati data yang jatuh setelah Juni 2026
                }
                Event::firstOrCreate(
                    ['title' => $ev['title'], 'start_date' => $ev['start_date']],
                    array_merge($ev, ['created_by' => $admin->id])
                );
            }
        }

        // -----------------------------------------------------------------
        // 7. FAQ (statis, tidak terikat tahun tertentu)
        // -----------------------------------------------------------------
        $faqData = [
            ['question' => 'Bagaimana cara membayar iuran RT?',      'answer' => 'Bayar via aplikasi dengan upload bukti transfer, atau langsung ke bendahara RT. Metode: transfer bank, tunai, QRIS.', 'category' => 'Pembayaran', 'order' => 1],
            ['question' => 'Kapan batas waktu pembayaran iuran sampah mingguan?', 'answer' => 'Iuran sampah ditagih setiap minggu dengan batas waktu di akhir minggu berjalan (hari Minggu).', 'category' => 'Pembayaran', 'order' => 2],
            ['question' => 'Kapan batas waktu iuran bulanan lainnya?', 'answer' => 'Iuran keamanan dan kas RT ditagih setiap bulan, umumnya jatuh tempo mendekati akhir bulan.', 'category' => 'Pembayaran', 'order' => 3],
            ['question' => 'Bagaimana jika pembayaran saya ditolak?', 'answer' => 'Anda mendapat notifikasi beserta alasan. Kirim ulang bukti yang lebih jelas atau hubungi admin RT.', 'category' => 'Pembayaran', 'order' => 4],
            ['question' => 'Bagaimana cara mendaftar akun?',         'answer' => 'Akun dibuat oleh admin RT per Kartu Keluarga. Hubungi ketua atau sekretaris RT untuk mendaftar dan mendapatkan akses login.', 'category' => 'Akun', 'order' => 5],
            ['question' => 'Bagaimana cara reset password?',         'answer' => 'Klik "Lupa Password" di halaman login, masukkan email, ikuti instruksi yang dikirim ke email Anda.', 'category' => 'Akun', 'order' => 6],
            ['question' => 'Apakah data saya aman?',                 'answer' => 'Ya. Data sensitif (NIK, nomor HP) dienkripsi AES-256. Kami menjaga privasi seluruh warga.', 'category' => 'Keamanan', 'order' => 7],
            ['question' => 'Bagaimana melihat transparansi keuangan?', 'answer' => 'Buka menu Laporan Keuangan untuk melihat ringkasan pemasukan dan pengeluaran RT secara transparan.', 'category' => 'Keuangan', 'order' => 8],
        ];

        foreach ($faqData as $faq) {
            Faq::firstOrCreate(
                ['question' => $faq['question']],
                array_merge($faq, ['is_active' => true])
            );
        }

        $this->command->info('DemoDataSeeder selesai: ' . count($wargas) . ' warga (KK), ' .
            count($invoiceRows) . ' tagihan, ' . count($paymentRows) . ' pembayaran (semua lunas) untuk periode ' .
            'Januari ' . self::YEAR_START . ' - Juni ' . self::YEAR_END . '.');
    }

    /**
     * Membuat 30 akun warga, masing-masing mewakili 1 Kartu Keluarga (KK).
     *
     * @return \Illuminate\Support\Collection<int, User>
     */
    private function createWargas()
    {
        $names = [
            'Naufal Rizqi', 'Keysha Aurelia', 'Dimas Aditya', 'Amanda Putri',
            'Faiz Ibrahim', 'Syifa Salsabila', 'Bintang Ramadhan', 'Naylah Putri',
            'Rian Hidayat', 'Siti Aminah', 'Arif Rahman', 'Dewi Lestari',
            'Eko Prasetyo', 'Fitriani Lestari', 'Gilang Permana', 'Hendra Wijaya',
            'Indah Permatasari', 'Joko Santoso', 'Kartika Sari', 'Lukman Hakim',
            'Maya Anggraini', 'Nur Fadillah', 'Oscar Pratama', 'Putri Wulandari',
            'Qori Ramadhani', 'Rendi Saputra', 'Sri Wahyuni', 'Taufik Hidayat',
            'Umi Kalsum', 'Vino Bastian',
        ];

        $streets = ['Jl. Mawar', 'Jl. Melati', 'Jl. Anggrek', 'Jl. Dahlia', 'Jl. Kenanga', 'Jl. Flamboyan', 'Jl. Cempaka'];
        $rtOptions = ['RT 01/RW 05', 'RT 02/RW 05', 'RT 03/RW 05'];

        $usedEmails = [];
        $usedPhones = [];
        $wargas = collect();

        foreach ($names as $index => $name) {
            $slug = strtolower(str_replace(' ', '.', $name));
            $slug = preg_replace('/[^a-z.]/', '', $slug);
            $email = $slug . '@gmail.com';
            $suffix = 1;
            while (in_array($email, $usedEmails, true)) {
                $email = $slug . $suffix . '@gmail.com';
                $suffix++;
            }
            $usedEmails[] = $email;

            do {
                $phone = '08' . rand(11, 99) . rand(1000000, 9999999);
            } while (in_array($phone, $usedPhones, true));
            $usedPhones[] = $phone;

            $street = $streets[$index % count($streets)];
            $houseNo = ($index % 20) + 1;
            $rtRw = $rtOptions[intdiv($index, 12) % count($rtOptions)];

            $wargas->push(User::firstOrCreate(
                ['email' => $email],
                [
                    'name'      => $name,
                    'password'  => Hash::make('password123'),
                    'role'      => 'user',
                    'phone'     => $phone,
                    'nik'       => '3204' . str_pad((string) (1000000000 + $index * 137), 12, '0', STR_PAD_LEFT),
                    'address'   => $street . ' No. ' . $houseNo,
                    'rt_rw'     => $rtRw,
                    'is_active' => true,
                ]
            ));
        }

        return $wargas;
    }
}
