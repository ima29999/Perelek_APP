<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\Expense;
use App\Models\Faq;
use App\Models\Invoice;
use App\Models\Notification;
use App\Models\Payment;
use App\Models\User;
use App\Services\GroqService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class AiChatController extends Controller
{
    protected GroqService $groq;

    public function __construct(GroqService $groq)
    {
        $this->groq = $groq;
    }

    // -------------------------------------------------------------------------
    // POST /api/ai/chat
    // Stateless: frontend mengirim seluruh riwayat chat setiap kali (tidak
    // disimpan di backend/database), backend menambahkan konteks data user
    // yang sedang login lalu meneruskannya ke Groq API.
    // -------------------------------------------------------------------------
    public function chat(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'message'           => 'required|string|max:2000',
            'history'           => 'nullable|array|max:30',
            'history.*.role'    => 'required_with:history|in:user,assistant',
            'history.*.content' => 'required_with:history|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal.',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $user = $request->user();

        $systemInstruction = $this->buildSystemInstruction($user, (string) $request->input('message', ''));

        try {
            $reply = $this->groq->generateReply(
                $systemInstruction,
                $request->input('history', []),
                $request->input('message')
            );
        } catch (\RuntimeException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Asisten AI sedang tidak bisa dihubungi. Coba lagi sebentar lagi.',
            ], 502);
        }

        return response()->json([
            'success' => true,
            'data'    => ['reply' => $reply],
        ]);
    }

    // =========================================================================
    // SYSTEM INSTRUCTION BUILDER
    // =========================================================================

    /**
     * Susun instruksi sistem + data kontekstual sesuai peran user yang login.
     *
     * @param string $message Pesan/pertanyaan user saat ini. Dipakai untuk mendeteksi
     *                         apakah user menanyakan periode tertentu (nama bulan, tahun,
     *                         "bulan ini", "bulan lalu", "tahun ini", "tahun lalu"), sehingga
     *                         data rincian yang lebih spesifik bisa disiapkan sebagai konteks.
     */
    private function buildSystemInstruction(User $user, string $message = ''): string
    {
        $today = now()->translatedFormat('l, d F Y'); // contoh: Senin, 29 Juni 2026

        $base  = "Kamu adalah **Asisten Perelek**, asisten virtual cerdas untuk aplikasi manajemen iuran warga RT/RW bernama **Perelek**.\n";
        $base .= "Tanggal hari ini: {$today}.\n\n";

        $base .= "### Kepribadian & Gaya Bicara\n";
        $base .= "- Jawab dalam Bahasa Indonesia, singkat, jelas, ramah, dan sopan.\n";
        $base .= "- Gunakan format poin (•) atau penomoran jika menjawab daftar.\n";
        $base .= "- Jika ada angka rupiah, tulis dengan format: Rp 50.000 (titik sebagai pemisah ribuan).\n";
        $base .= "- Jika ada tanggal, tulis dengan format: 10 Januari 2026.\n\n";

        $base .= "### Aturan Ketat Penggunaan Data\n";
        $base .= "- Gunakan **HANYA** data di bagian DATA di bawah untuk menjawab pertanyaan spesifik tentang tagihan, pembayaran, kegiatan, dan keuangan.\n";
        $base .= "- Jika data yang ditanyakan **tidak ada** dalam bagian DATA, katakan jujur bahwa kamu tidak punya datanya. Jangan mengarang angka, tanggal, atau nama.\n";
        $base .= "- Untuk pertanyaan umum tentang cara pakai aplikasi, fitur, atau kebijakan RT, kamu boleh menjawab berdasarkan pengetahuan umum tentang aplikasi ini.\n";
        $base .= "- Untuk pertanyaan rincian keuangan per bulan atau per tahun (contoh: \"berapa pengeluaran bulan Januari\", \"rincian tahun 2025\", \"bandingkan dengan tahun lalu\", \"total pemasukan bulan ini\"), gunakan tabel pada bagian **\"Rincian Keuangan Per Bulan\"**, **\"Rekap Tahunan (Multi-Tahun)\"**, atau **\"Detail Bulan ... (Diminta Spesifik)\"** di bawah. Jumlahkan/pilih baris yang relevan dari tabel tersebut, jangan mengarang.\n";
        $base .= "- Jika user menyebut bulan/tahun yang datanya tidak muncul di bagian DATA (misalnya karena di luar rentang yang disiapkan), sampaikan jujur data itu tidak tersedia dan sarankan user melihat menu Laporan Keuangan di aplikasi untuk rentang tersebut.\n\n";

        $base .= "### Fitur Aplikasi Perelek (Pengetahuan Umum)\n";
        $base .= "- **Warga**: lihat tagihan iuran, bayar via upload bukti/QRIS/transfer, cek riwayat pembayaran, lihat kegiatan, laporan personal, notifikasi.\n";
        $base .= "- **Admin/Pengurus RT**: kelola warga, buat & kelola tagihan, memantau pembayaran (otomatis confirmated oleh sistem/Midtrans, bukan dikonfirmasi manual oleh admin), catat pengeluaran, buat kegiatan, kelola FAQ, lihat laporan keuangan lengkap.\n";
        $base .= "- **Metode Bayar**: transfer bank, tunai ke bendahara, QRIS, atau pembayaran online via Midtrans.\n";
        $base .= "- **Status Pembayaran**: 'confirmated' (terkonfirmasi otomatis oleh sistem, tanpa perlu konfirmasi admin), 'rejected' (ditolak, perlu kirim ulang bukti).\n\n";

        // Gabungkan konteks FAQ yang berlaku untuk semua user
        $base .= $this->buildFaqContext();

        if ($user->role === 'admin') {
            $base .= $this->buildAdminContext($message);
        } else {
            $base .= $this->buildWargaContext($user, $message);
        }

        return $base;
    }

    // =========================================================================
    // SHARED CONTEXT (berlaku untuk admin & warga)
    // =========================================================================

    /**
     * Masukkan FAQ aktif ke dalam konteks agar AI bisa menjawab
     * pertanyaan umum tentang aplikasi dengan akurat.
     */
    private function buildFaqContext(): string
    {
        $faqs = Faq::where('is_active', true)
            ->orderBy('order')
            ->get(['question', 'answer', 'category']);

        if ($faqs->isEmpty()) {
            return '';
        }

        $lines   = [];
        $lines[] = "### FAQ Aplikasi Perelek\n";
        foreach ($faqs as $faq) {
            $lines[] = "**T: {$faq->question}**";
            $lines[] = "J: {$faq->answer}\n";
        }

        return implode("\n", $lines) . "\n";
    }

    // =========================================================================
    // PERIOD DETECTION HELPERS (dipakai konteks Admin & Warga)
    // =========================================================================

    /**
     * Deteksi apakah pesan user menyebut bulan/tahun tertentu, supaya kita bisa
     * menyiapkan data rincian yang lebih spesifik (bukan cuma ringkasan umum).
     * Contoh yang terdeteksi: "Januari", "Jan 2025", "bulan ini", "bulan lalu",
     * "tahun ini", "tahun lalu", "2025".
     *
     * @return array{year: int|null, month: int|null}
     */
    private function detectRequestedPeriod(string $message): array
    {
        $text = mb_strtolower($message);

        $monthAliases = [
            1  => ['januari', 'jan'],
            2  => ['februari', 'feb'],
            3  => ['maret', 'mar'],
            4  => ['april', 'apr'],
            5  => ['mei'],
            6  => ['juni', 'jun'],
            7  => ['juli', 'jul'],
            8  => ['agustus', 'agu', 'ags'],
            9  => ['september', 'sep'],
            10 => ['oktober', 'okt'],
            11 => ['november', 'nov'],
            12 => ['desember', 'des'],
        ];

        $month = null;
        foreach ($monthAliases as $num => $aliases) {
            foreach ($aliases as $alias) {
                if (preg_match('/\b' . preg_quote($alias, '/') . '\b/u', $text)) {
                    $month = $num;
                    break 2;
                }
            }
        }

        $year = null;
        if (preg_match('/\b(20\d{2})\b/', $text, $m)) {
            $year = (int) $m[1];
        }

        // Istilah relatif, hanya dipakai jika belum terdeteksi dari nama eksplisit
        if ($month === null) {
            if (preg_match('/\bbulan\s+ini\b/u', $text)) {
                $month = (int) now()->format('n');
                $year  = $year ?? (int) now()->format('Y');
            } elseif (preg_match('/\bbulan\s+(lalu|kemarin)\b/u', $text)) {
                $prev  = now()->subMonthNoOverflow();
                $month = (int) $prev->format('n');
                $year  = $year ?? (int) $prev->format('Y');
            }
        }

        if ($year === null) {
            if (preg_match('/\btahun\s+(lalu|kemarin)\b/u', $text)) {
                $year = (int) now()->format('Y') - 1;
            } elseif (preg_match('/\btahun\s+ini\b/u', $text)) {
                $year = (int) now()->format('Y');
            }
        }

        return ['year' => $year, 'month' => $month];
    }

    /**
     * Nama bulan dalam Bahasa Indonesia dari angka 1-12.
     */
    private function monthLabel(int $month): string
    {
        $labels = [
            1 => 'Januari', 2 => 'Februari', 3 => 'Maret', 4 => 'April',
            5 => 'Mei', 6 => 'Juni', 7 => 'Juli', 8 => 'Agustus',
            9 => 'September', 10 => 'Oktober', 11 => 'November', 12 => 'Desember',
        ];

        return $labels[$month] ?? (string) $month;
    }

    // =========================================================================
    // WARGA CONTEXT
    // =========================================================================

    private function buildWargaContext(User $user, string $message = ''): string
    {
        $lines   = [];
        $lines[] = "---";
        $lines[] = "## DATA PERSONAL (Peran: Warga)";
        $lines[] = "- Nama: {$user->name}";
        $lines[] = "- Alamat: " . ($user->address ?? '-') . ", " . ($user->rt_rw ?? '-');
        $lines[] = "";

        // --- Tagihan belum dibayar ---
        $unpaidInvoices = Invoice::where('is_active', true)
            ->whereDoesntHave('payments', fn($q) => $q
                ->where('user_id', $user->id)
                ->whereIn('status', ['pending', 'confirmated'])
            )
            ->orderBy('deadline')
            ->get(['id', 'title', 'nominal', 'period', 'deadline', 'description']);

        $lines[] = "### Tagihan Belum Dibayar";
        if ($unpaidInvoices->isEmpty()) {
            $lines[] = "- Semua tagihan sudah lunas. ✅";
        } else {
            foreach ($unpaidInvoices as $inv) {
                $deadline = $inv->deadline ? $inv->deadline->format('d F Y') : 'tanpa jatuh tempo';
                $nominal  = 'Rp ' . number_format((float) $inv->nominal, 0, ',', '.');
                $lines[]  = "• [{$inv->period}] {$inv->title} — {$nominal} — Jatuh tempo: {$deadline}";
            }
        }
        $lines[] = "";

        // --- Pembayaran ditolak (perlu tindak lanjut) ---
        $rejectedPayments = Payment::where('user_id', $user->id)
            ->where('status', 'rejected')
            ->with('invoice:id,title')
            ->latest()
            ->limit(3)
            ->get();

        if ($rejectedPayments->isNotEmpty()) {
            $lines[] = "### Pembayaran Ditolak (Perlu Kirim Ulang)";
            foreach ($rejectedPayments as $p) {
                $lines[] = "• {$p->invoice?->title} — Alasan: " . ($p->notes ?? 'tidak ada keterangan');
            }
            $lines[] = "";
        }

        // --- Riwayat pembayaran terkonfirmasi (5 terakhir) ---
        $recentPayments = Payment::where('user_id', $user->id)
            ->where('status', 'confirmated')
            ->with('invoice:id,title,period')
            ->latest()
            ->limit(5)
            ->get();

        if ($recentPayments->isNotEmpty()) {
            $lines[] = "### Riwayat Pembayaran Terkonfirmasi (5 Terakhir)";
            foreach ($recentPayments as $p) {
                $tgl     = $p->payment_date?->format('d F Y') ?? '-';
                $nominal = 'Rp ' . number_format((float) $p->amount, 0, ',', '.');
                $lines[] = "• {$p->invoice?->title} ({$p->invoice?->period}) — {$nominal} — {$tgl}";
            }
            $lines[] = "";
        }

        // --- Statistik pembayaran tahun ini ---
        $paidThisYear = Payment::where('user_id', $user->id)
            ->where('status', 'confirmated')
            ->whereYear('payment_date', date('Y'))
            ->sum('amount');

        $lines[] = "### Ringkasan Pembayaran Tahun " . date('Y');
        $lines[] = "- Total sudah dibayar: Rp " . number_format((float) $paidThisYear, 0, ',', '.');
        $lines[] = "";

        // --- Kegiatan / Event mendatang ---
        $lines[] = $this->buildUpcomingEventsSection();

        // --- Notifikasi belum dibaca ---
        $unreadNotifs = Notification::forUser($user->id)
            ->unread()
            ->latest()
            ->limit(5)
            ->get(['title', 'body', 'type', 'created_at']);

        if ($unreadNotifs->isNotEmpty()) {
            $lines[] = "### Notifikasi Belum Dibaca";
            foreach ($unreadNotifs as $n) {
                $tgl     = $n->created_at->format('d F Y');
                $lines[] = "• [{$tgl}] {$n->title}: {$n->body}";
            }
            $lines[] = "";
        }

        // --- Rincian pembayaran per bulan (tahun berjalan / tahun yang disebut user) ---
        $period       = $this->detectRequestedPeriod($message);
        $resolvedYear = $period['year'] ?? (int) date('Y');

        $lines[] = $this->buildWargaMonthlyRecapSection($user, $resolvedYear);
        $lines[] = $this->buildWargaYearlyRecapSection($user);

        // --- Jika user menyebut bulan spesifik, siapkan rincian itemized-nya ---
        if ($period['month'] !== null) {
            $lines[] = $this->buildWargaSpecificMonthDetailSection(
                $user,
                $resolvedYear,
                $period['month'],
                $this->monthLabel($period['month'])
            );
        }

        return implode("\n", $lines);
    }

    /**
     * Rincian total pembayaran (confirmated) warga per bulan untuk satu tahun.
     * Menjawab pertanyaan seperti "berapa saya bayar bulan Maret?".
     */
    private function buildWargaMonthlyRecapSection(User $user, int $year): string
    {
        $paymentsByMonth = Payment::where('user_id', $user->id)
            ->where('status', 'confirmated')
            ->whereYear('payment_date', $year)
            ->selectRaw('MONTH(payment_date) as m, SUM(amount) as total, COUNT(*) as cnt')
            ->groupBy('m')
            ->get()
            ->keyBy(fn($row) => (int) $row->m);

        $lines   = [];
        $lines[] = "### Rincian Pembayaran Saya Per Bulan Tahun {$year}";
        $lines[] = "Format: Bulan — Total Dibayar (jumlah transaksi)";

        $totalYear = 0.0;
        for ($m = 1; $m <= 12; $m++) {
            $total = (float) ($paymentsByMonth[$m]->total ?? 0);
            $cnt   = (int) ($paymentsByMonth[$m]->cnt ?? 0);
            $totalYear += $total;
            $lines[] = "• " . $this->monthLabel($m) . " {$year} — Rp " . number_format($total, 0, ',', '.') . " ({$cnt} transaksi)";
        }
        $lines[] = "→ Total Tahun {$year}: Rp " . number_format($totalYear, 0, ',', '.');
        $lines[] = "";

        return implode("\n", $lines);
    }

    /**
     * Rekap total pembayaran (confirmated) warga per tahun, maksimal 6 tahun terakhir
     * yang memiliki data. Menjawab pertanyaan seperti "total saya bayar tahun 2025 berapa?".
     */
    private function buildWargaYearlyRecapSection(User $user): string
    {
        $byYear = Payment::where('user_id', $user->id)
            ->where('status', 'confirmated')
            ->selectRaw('YEAR(payment_date) as y, SUM(amount) as total, COUNT(*) as cnt')
            ->groupBy('y')
            ->get()
            ->keyBy(fn($row) => (int) $row->y)
            ->sortKeysDesc()
            ->take(6);

        if ($byYear->isEmpty()) {
            return '';
        }

        $lines   = [];
        $lines[] = "### Rekap Pembayaran Saya Per Tahun (Multi-Tahun)";
        foreach ($byYear as $y => $row) {
            $lines[] = "• Tahun {$y} — Rp " . number_format((float) $row->total, 0, ',', '.') . " ({$row->cnt} transaksi)";
        }
        $lines[] = "";

        return implode("\n", $lines);
    }

    /**
     * Rincian itemized pembayaran warga untuk satu bulan spesifik yang disebut di pesan user.
     */
    private function buildWargaSpecificMonthDetailSection(User $user, int $year, int $month, string $monthLabel): string
    {
        $payments = Payment::where('user_id', $user->id)
            ->where('status', 'confirmated')
            ->whereYear('payment_date', $year)
            ->whereMonth('payment_date', $month)
            ->with('invoice:id,title')
            ->orderBy('payment_date')
            ->get(['id', 'invoice_id', 'amount', 'payment_date', 'method']);

        $total = $payments->sum(fn($p) => (float) $p->amount);

        $lines   = [];
        $lines[] = "### Detail Pembayaran Saya Bulan {$monthLabel} {$year} (Diminta Spesifik)";
        $lines[] = "Total: Rp " . number_format($total, 0, ',', '.') . " ({$payments->count()} transaksi)";

        if ($payments->isNotEmpty()) {
            foreach ($payments as $p) {
                $tgl     = $p->payment_date?->format('d F Y') ?? '-';
                $nominal = 'Rp ' . number_format((float) $p->amount, 0, ',', '.');
                $judul   = $p->invoice?->title ?? 'Tagihan tidak diketahui';
                $lines[] = "• {$judul} — {$nominal} — {$tgl} — Metode: {$p->method}";
            }
        } else {
            $lines[] = "Tidak ada pembayaran tercatat pada bulan ini.";
        }
        $lines[] = "";

        return implode("\n", $lines);
    }

    // =========================================================================
    // ADMIN CONTEXT
    // =========================================================================

    private function buildAdminContext(string $message = ''): string
    {
        $lines   = [];
        $lines[] = "---";
        $lines[] = "## DATA ADMIN (Peran: Pengurus RT)";
        $lines[] = "";

        $period       = $this->detectRequestedPeriod($message);
        $resolvedYear = $period['year'] ?? (int) date('Y');

        // --- Ringkasan kas RT ---
        $totalIncome  = Payment::where('status', 'confirmated')->sum('amount');
        $totalExpense = Expense::sum('nominal');
        $saldo        = $totalIncome - $totalExpense;
        $totalWarga   = User::where('role', 'user')->where('is_active', true)->count();

        $lines[] = "### Ringkasan Kas & Statistik RT";
        $lines[] = "- Jumlah warga aktif: {$totalWarga} orang";
        $lines[] = "- Total pemasukan (sepanjang waktu): Rp " . number_format((float) $totalIncome, 0, ',', '.');
        $lines[] = "- Total pengeluaran (sepanjang waktu): Rp " . number_format((float) $totalExpense, 0, ',', '.');
        $lines[] = "- Saldo kas saat ini: Rp " . number_format((float) $saldo, 0, ',', '.');
        $lines[] = "";

        // --- Rincian keuangan per bulan (tahun berjalan / tahun yang disebut admin) ---
        $lines[] = $this->buildAdminMonthlyRecapSection($resolvedYear);

        // --- Rekap per tahun (multi-tahun), agar bisa jawab perbandingan/tahun lampau ---
        $lines[] = $this->buildAdminYearlyRecapSection();

        // --- Tagihan aktif ---
        $activeInvoices = Invoice::where('is_active', true)
            ->withCount([
                'payments as paid_count' => fn($q) => $q->where('status', 'confirmated'),
            ])
            ->orderBy('deadline')
            ->limit(10)
            ->get();

        $lines[] = "### Tagihan Aktif";
        if ($activeInvoices->isEmpty()) {
            $lines[] = "- Tidak ada tagihan aktif saat ini.";
        } else {
            foreach ($activeInvoices as $inv) {
                $deadline    = $inv->deadline ? $inv->deadline->format('d F Y') : 'tanpa jatuh tempo';
                $nominal     = 'Rp ' . number_format((float) $inv->nominal, 0, ',', '.');
                $belumBayar  = $totalWarga - $inv->paid_count;
                $lines[]     = "• {$inv->title} ({$inv->period}) — {$nominal} — Jatuh tempo: {$deadline}";
                $lines[]     = "  └ Sudah bayar: {$inv->paid_count} warga | Belum bayar: {$belumBayar} warga";
            }
        }
        $lines[] = "";


        // --- Pengeluaran terbaru ---
        $recentExpenses = Expense::latest('date')
            ->limit(5)
            ->get(['title', 'category', 'nominal', 'date']);

        if ($recentExpenses->isNotEmpty()) {
            $lines[] = "### Pengeluaran Terbaru";
            foreach ($recentExpenses as $exp) {
                $tgl     = $exp->date->format('d F Y');
                $nominal = 'Rp ' . number_format((float) $exp->nominal, 0, ',', '.');
                $lines[] = "• [{$exp->category}] {$exp->title} — {$nominal} — {$tgl}";
            }
            $lines[] = "";
        }

        // --- Warga dengan tunggakan terbanyak ---
        $wargas = User::where('role', 'user')
            ->where('is_active', true)
            ->withCount([
                'payments as confirmated_count' => fn($q) => $q->where('status', 'confirmated'),
            ])
            ->orderBy('confirmated_count')
            ->limit(5)
            ->get(['id', 'name', 'address', 'rt_rw']);

        $totalActiveInvoices = Invoice::where('is_active', true)->count();

        if ($wargas->isNotEmpty() && $totalActiveInvoices > 0) {
            $lines[] = "### Warga dengan Pembayaran Paling Sedikit (Potensial Nunggak)";
            foreach ($wargas as $w) {
                $tunggak = max(0, $totalActiveInvoices - $w->confirmated_count);
                $lines[] = "• {$w->name} ({$w->rt_rw}) — {$w->confirmated_count} tagihan aktif terbayar, estimasi {$tunggak} tunggakan";
            }
            $lines[] = "";
        }

        // --- Kegiatan mendatang ---
        $lines[] = $this->buildUpcomingEventsSection();

        // --- Ringkasan pengeluaran per kategori, mengikuti tahun yang disebut admin ---
        $expensesByCategory = Expense::whereYear('date', $resolvedYear)
            ->selectRaw('category, SUM(nominal) as total')
            ->groupBy('category')
            ->orderByDesc('total')
            ->get();

        if ($expensesByCategory->isNotEmpty()) {
            $lines[] = "### Pengeluaran Per Kategori Tahun {$resolvedYear}";
            foreach ($expensesByCategory as $ec) {
                $total   = 'Rp ' . number_format((float) $ec->total, 0, ',', '.');
                $lines[] = "• {$ec->category}: {$total}";
            }
            $lines[] = "";
        }

        // --- Jika admin menyebut bulan spesifik, siapkan rincian itemized-nya ---
        if ($period['month'] !== null) {
            $lines[] = $this->buildAdminSpecificMonthDetailSection(
                $resolvedYear,
                $period['month'],
                $this->monthLabel($period['month'])
            );
        }

        return implode("\n", $lines);
    }

    /**
     * Rincian pemasukan & pengeluaran RT per bulan untuk satu tahun (12 baris).
     * Menjawab pertanyaan seperti "rincian pengeluaran bulan Januari" atau
     * "gimana keuangan bulan Maret".
     */
    private function buildAdminMonthlyRecapSection(int $year): string
    {
        $incomeByMonth = Payment::where('status', 'confirmated')
            ->whereYear('payment_date', $year)
            ->selectRaw('MONTH(payment_date) as m, SUM(amount) as total')
            ->groupBy('m')
            ->get()
            ->keyBy(fn($row) => (int) $row->m);

        $expenseByMonth = Expense::whereYear('date', $year)
            ->selectRaw('MONTH(date) as m, SUM(nominal) as total')
            ->groupBy('m')
            ->get()
            ->keyBy(fn($row) => (int) $row->m);

        $lines   = [];
        $lines[] = "### Rincian Keuangan Per Bulan Tahun {$year}";
        $lines[] = "Format: Bulan — Pemasukan | Pengeluaran | Selisih";

        $totalIncomeYear  = 0.0;
        $totalExpenseYear = 0.0;

        for ($m = 1; $m <= 12; $m++) {
            $income  = (float) ($incomeByMonth[$m]->total ?? 0);
            $expense = (float) ($expenseByMonth[$m]->total ?? 0);
            $selisih = $income - $expense;

            $totalIncomeYear  += $income;
            $totalExpenseYear += $expense;

            $lines[] = "• " . $this->monthLabel($m) . " {$year} — Pemasukan: Rp " . number_format($income, 0, ',', '.')
                . " | Pengeluaran: Rp " . number_format($expense, 0, ',', '.')
                . " | Selisih: Rp " . number_format($selisih, 0, ',', '.');
        }

        $lines[] = "→ Total Tahun {$year}: Pemasukan Rp " . number_format($totalIncomeYear, 0, ',', '.')
            . " | Pengeluaran Rp " . number_format($totalExpenseYear, 0, ',', '.')
            . " | Selisih Rp " . number_format($totalIncomeYear - $totalExpenseYear, 0, ',', '.');
        $lines[] = "";

        return implode("\n", $lines);
    }

    /**
     * Rekap total pemasukan & pengeluaran RT per tahun, maksimal 6 tahun terakhir
     * yang memiliki data. Menjawab pertanyaan seperti "rincian pengeluaran tahunan"
     * atau "bandingkan keuangan tahun ini dengan tahun lalu".
     */
    private function buildAdminYearlyRecapSection(): string
    {
        $incomeByYear = Payment::where('status', 'confirmated')
            ->selectRaw('YEAR(payment_date) as y, SUM(amount) as total')
            ->groupBy('y')
            ->get()
            ->keyBy(fn($row) => (int) $row->y);

        $expenseByYear = Expense::selectRaw('YEAR(date) as y, SUM(nominal) as total')
            ->groupBy('y')
            ->get()
            ->keyBy(fn($row) => (int) $row->y);

        $years = collect($incomeByYear->keys())
            ->merge($expenseByYear->keys())
            ->unique()
            ->sortDesc()
            ->take(6) // batasi 6 tahun terakhir supaya konteks tidak terlalu panjang
            ->values();

        if ($years->isEmpty()) {
            return '';
        }

        $lines   = [];
        $lines[] = "### Rekap Tahunan (Multi-Tahun)";
        $lines[] = "Format: Tahun — Pemasukan | Pengeluaran | Selisih";
        foreach ($years as $y) {
            $income  = (float) ($incomeByYear[$y]->total ?? 0);
            $expense = (float) ($expenseByYear[$y]->total ?? 0);
            $lines[] = "• Tahun {$y} — Pemasukan: Rp " . number_format($income, 0, ',', '.')
                . " | Pengeluaran: Rp " . number_format($expense, 0, ',', '.')
                . " | Selisih: Rp " . number_format($income - $expense, 0, ',', '.');
        }
        $lines[] = "";

        return implode("\n", $lines);
    }

    /**
     * Rincian itemized pengeluaran & pemasukan RT untuk satu bulan spesifik
     * yang disebut di pesan admin (mis. "rincian pengeluaran bulan Januari").
     */
    private function buildAdminSpecificMonthDetailSection(int $year, int $month, string $monthLabel): string
    {
        $lines   = [];
        $lines[] = "### Detail Bulan {$monthLabel} {$year} (Diminta Spesifik)";

        // --- Pengeluaran ---
        $expenses = Expense::whereYear('date', $year)
            ->whereMonth('date', $month)
            ->orderBy('date')
            ->get(['title', 'category', 'nominal', 'date']);

        $totalExpense = $expenses->sum(fn($e) => (float) $e->nominal);

        $lines[] = "**Pengeluaran {$monthLabel} {$year}** — Total: Rp " . number_format($totalExpense, 0, ',', '.') . " ({$expenses->count()} transaksi)";

        if ($expenses->isNotEmpty()) {
            $byCategory = $expenses->groupBy('category')->map(fn($g) => $g->sum(fn($e) => (float) $e->nominal));
            foreach ($byCategory as $cat => $catTotal) {
                $lines[] = "  └ Kategori {$cat}: Rp " . number_format($catTotal, 0, ',', '.');
            }

            $lines[] = "  Rincian transaksi:";
            foreach ($expenses->take(15) as $e) {
                $tgl     = $e->date->format('d F Y');
                $nominal = 'Rp ' . number_format((float) $e->nominal, 0, ',', '.');
                $lines[] = "  • [{$e->category}] {$e->title} — {$nominal} — {$tgl}";
            }
            if ($expenses->count() > 15) {
                $sisa    = $expenses->count() - 15;
                $lines[] = "  • ... dan {$sisa} transaksi lainnya (sudah termasuk dalam total & kategori di atas)";
            }
        } else {
            $lines[] = "  Tidak ada pengeluaran tercatat pada bulan ini.";
        }
        $lines[] = "";

        // --- Pemasukan ---
        $payments = Payment::where('status', 'confirmated')
            ->whereYear('payment_date', $year)
            ->whereMonth('payment_date', $month)
            ->with('invoice:id,title')
            ->get(['invoice_id', 'amount', 'payment_date']);

        $totalIncome = $payments->sum(fn($p) => (float) $p->amount);

        $lines[] = "**Pemasukan {$monthLabel} {$year}** — Total: Rp " . number_format($totalIncome, 0, ',', '.') . " ({$payments->count()} pembayaran)";

        if ($payments->isNotEmpty()) {
            $byInvoice = $payments->groupBy(fn($p) => $p->invoice?->title ?? 'Lainnya')
                ->map(fn($g) => ['total' => $g->sum(fn($p) => (float) $p->amount), 'count' => $g->count()]);
            foreach ($byInvoice as $title => $data) {
                $lines[] = "  └ {$title}: Rp " . number_format($data['total'], 0, ',', '.') . " ({$data['count']} pembayaran)";
            }
        } else {
            $lines[] = "  Tidak ada pemasukan tercatat pada bulan ini.";
        }
        $lines[] = "";

        return implode("\n", $lines);
    }

    // =========================================================================
    // SHARED SECTION BUILDERS
    // =========================================================================

    /**
     * Daftar kegiatan / event mendatang (berlaku untuk warga & admin).
     */
    private function buildUpcomingEventsSection(): string
    {
        $events = Event::where('start_date', '>=', now())
            ->orderBy('start_date')
            ->limit(5)
            ->get(['title', 'description', 'location', 'start_date', 'end_date']);

        if ($events->isEmpty()) {
            return "### Kegiatan / Agenda Mendatang\n- Tidak ada kegiatan terjadwal dalam waktu dekat.\n\n";
        }

        $lines   = [];
        $lines[] = "### Kegiatan / Agenda Mendatang";
        foreach ($events as $ev) {
            $mulai   = $ev->start_date->translatedFormat('d F Y, H:i');
            $selesai = $ev->end_date ? $ev->end_date->translatedFormat('d F Y, H:i') : 'tidak ditentukan';
            $lokasi  = $ev->location ?? 'tidak disebutkan';
            $lines[] = "• **{$ev->title}**";
            $lines[] = "  └ Waktu: {$mulai} s/d {$selesai}";
            $lines[] = "  └ Lokasi: {$lokasi}";
            if ($ev->description) {
                $lines[] = "  └ Keterangan: {$ev->description}";
            }
        }
        $lines[] = "";

        return implode("\n", $lines) . "\n";
    }
}