import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_cache.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/snackbar_helper.dart';
import '../auth/auth_provider.dart';
import 'midtrans_webview_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

class SubmitPaymentPage extends StatefulWidget {
  final int invoiceId;
  const SubmitPaymentPage({super.key, required this.invoiceId});

  @override
  State<SubmitPaymentPage> createState() => _SubmitPaymentPageState();
}

class _SubmitPaymentPageState extends State<SubmitPaymentPage> {
  Map<String, dynamic>? _invoice;
  bool _loadingInvoice = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  // Fungsi navigasi kembali dengan fallback ke halaman daftar tagihan warga
  void _handleBackNavigation() {
    if (context.canPop()) {
      context.pop(); // Kembali ke halaman sebelum ini secara otomatis
    } else {
      context.go('/warga/invoices'); // Fallback menuju list tagihan
    }
  }

  Future<void> _loadInvoice() async {
    try {
      // Coba load langsung via endpoint detail dulu, lebih efisien dan pasti dapat data yang benar
      try {
        final res = await ApiClient().get('/invoices/${widget.invoiceId}');
        if (res.data['success'] == true && res.data['data'] != null) {
          final inv = Map<String, dynamic>.from(res.data['data']);
          if (inv['nominal'] != null) {
            inv['nominal'] = double.tryParse(inv['nominal'].toString()) ?? 0.0;
          }
          if (mounted) {
            setState(() {
              _invoice = inv;
            });
          }
          return;
        }
      } catch (_) {}

      // Fallback: cari dari list invoices dengan query param langsung di URL string
      final res = await ApiClient().get('/invoices?per_page=100');
      final raw = res.data['data'];
      final invoices =
          (raw is Map ? (raw['data'] as List?) : (raw as List?)) ?? [];

      final inv = invoices.firstWhere(
        // Bandingkan sebagai int agar aman terhadap mismatch tipe String vs int
        (i) =>
            (i['id'] as int? ?? int.tryParse(i['id'].toString()) ?? -1) ==
            widget.invoiceId,
        orElse: () => null,
      );

      if (inv != null) {
        setState(() {
          _invoice = Map<String, dynamic>.from(inv);
          if (_invoice!['nominal'] != null) {
            _invoice!['nominal'] =
                double.tryParse(_invoice!['nominal'].toString()) ?? 0.0;
          }
        });
      } else {
        if (mounted) {
          SnackBarHelper.show(
            context,
            'Tagihan tidak ditemukan pada halaman ini. Hubungi admin jika masalah berlanjut.',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.show(
            context, 'Gagal memuat data tagihan: ${e.toString()}',
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _loadingInvoice = false);
      }
    }
  }

  Future<void> _payWithMidtrans() async {
    setState(() => _submitting = true);
    try {
      final res = await ApiClient().post('/payments/midtrans/charge', data: {
        'invoice_id': widget.invoiceId,
      });

      if (res.data['success'] != true) {
        throw Exception(res.data['message'] ?? 'Gagal membuat transaksi.');
      }

      final data = res.data['data'];
      final redirectUrl = data['redirect_url'] as String;
      final paymentId =
          int.tryParse(data['payment']['id']?.toString() ?? '') ?? 0;

      if (paymentId == 0) {
        throw Exception('ID pembayaran tidak valid.');
      }

      if (!mounted) return;

      if (kIsWeb) {
        // 🌐 JIKA DI WEB: Buka di tab baru browser luar
        final Uri url = Uri.parse(redirectUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);

          // Setelah tab dibuka, langsung arahkan ke pengecekan status di aplikasi Anda
          if (mounted) await _checkMidtransStatus(paymentId);
        } else {
          throw 'Tidak dapat membuka halaman pembayaran.';
        }
      } else {
        // 📱 JIKA DI ANDROID/IOS: Buka via WebView internal aplikasi
        await Navigator.of(context, rootNavigator: true).push<bool>(
          MaterialPageRoute(
            builder: (_) => MidtransWebviewPage(redirectUrl: redirectUrl),
          ),
        );

        if (mounted) {
          await _checkMidtransStatus(paymentId);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.show(context, 'Gagal: ${e.toString()}', isError: true);
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _invalidateCachesAfterPayment() async {
    AppCache.instance.invalidate('payments_warga');
    AppCache.instance.invalidate('payments_admin');
    AppCache.instance.invalidate('warga_dashboard');
    AppCache.instance.invalidate('admin_dashboard');
    // BUG FIX: kunci cache tagihan yang benar adalah 'invoices_warga' dan
    // 'invoices_admin' (lihat InvoicesPage._load), BUKAN 'invoices' —
    // sebelumnya baris ini tidak pernah benar-benar membuang cache apapun,
    // sehingga halaman "Tagihan Saya" sempat menampilkan status lama
    // (tombol/badge basi) sebelum fetch baru selesai di belakang layar.
    AppCache.instance.invalidate('invoices_warga');
    AppCache.instance.invalidate('invoices_admin');
  }

  /// Setelah checkout Midtrans, cek status pembayaran berulang kali sampai
  /// final (confirmated/rejected) atau sampai waktu tunggu habis.
  ///
  /// CATATAN: halaman `/payment/finish` di backend sekarang MEMAKSA sync ke
  /// Midtrans begitu warga sampai di sana (lihat routes/web.php) — jadi
  /// pada saat polling ini mulai, database kemungkinan besar SUDAH sinkron
  /// untuk metode pembayaran yang cepat selesai (QRIS/e-wallet/kartu).
  /// Makanya jendela tunggu di sini tidak perlu lama lagi (dulu sampai 2
  /// menit, sekarang cukup ~16 detik) — kalau belum juga final di rentang
  /// itu, jangan kunci layar warga; arahkan ke halaman detail pembayaran
  /// yang punya tombol "Cek Status Terbaru" + akan otomatis ter-update
  /// sendiri lewat command terjadwal `payments:sync-midtrans`.
  Future<void> _checkMidtransStatus(int paymentId) async {
    if (!mounted) return;
    final currentContext = context;

    const maxAttempts = 8; // ~8 x 2 detik = 16 detik
    const interval = Duration(seconds: 2);

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      await Future.delayed(interval);
      if (!mounted) return;

      try {
        final res =
            await ApiClient().get('/payments/midtrans/$paymentId/status');
        final status = res.data['data']?['status'];

        if (status == 'confirmated') {
          if (!mounted) return;
          await _invalidateCachesAfterPayment();
          SnackBarHelper.show(
              currentContext, 'Pembayaran berhasil. Saldo sudah diperbarui.',
              isSuccess: true);
          currentContext.go('/warga/payments');
          return;
        }
        if (status == 'rejected') {
          if (!mounted) return;
          await _invalidateCachesAfterPayment();
          SnackBarHelper.show(
              currentContext, 'Pembayaran gagal/ditolak oleh Midtrans.',
              isError: true);
          currentContext.go('/warga/payments');
          return;
        }
      } catch (_) {}
    }

    if (!mounted) return;
    await _invalidateCachesAfterPayment();
    setState(() => _submitting = false);
    SnackBarHelper.show(
      currentContext,
      'Midtrans belum mengonfirmasi transaksi ini secara final. Status akan '
      'otomatis terkonfirmasi begitu selesai, atau tekan "Cek Status Terbaru" '
      'di halaman berikut.',
    );
    currentContext.go('/warga/payments/$paymentId');
  }

  @override
  Widget build(BuildContext context) {
    // Default true kalau field belum ada di response (aman untuk data lama).
    final canPay = context.watch<AuthProvider>().user?['can_pay'] != false;

    // Lapis pertahanan kedua (selain tombol yang sudah disembunyikan di
    // InvoicesPage/DashboardWargaPage): kalau admin menonaktifkan tombol
    // Bayar untuk warga ini tapi halaman ini tetap diakses langsung lewat
    // URL, tampilkan pesan blokir alih-alih form pembayaran. Endpoint di
    // backend (PaymentController/MidtransController) juga tetap menolak
    // request ini walau layar ini berhasil dilewati.
    if (!canPay) {
      return Scaffold(
        backgroundColor: context.colorBg,
        appBar: AppBar(
          title: const Text('Submit Pembayaran'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _handleBackNavigation,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline_rounded,
                  size: 48, color: AppColors.warning),
              const SizedBox(height: 16),
              const Text(
                'Pembayaran Dinonaktifkan Sementara',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Fitur pembayaran untuk akun Anda sedang dinonaktifkan '
                'sementara oleh admin. Hubungi admin RT untuk info lebih '
                'lanjut.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecond),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: _handleBackNavigation,
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      );
    }

    // Ambil nominal dengan aman untuk UI, berikan default value 0.0 jika data belum ter-load
    final double invoiceNominal = _invoice?['nominal'] is double
        ? _invoice!['nominal']
        : (double.tryParse(_invoice?['nominal']?.toString() ?? '') ?? 0.0);

    return Scaffold(
      backgroundColor: context.colorBg,
      body: CustomScrollView(slivers: [
        // Header Baru yang disamakan dengan InvoicesPage
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.fromLTRB(
                12, MediaQuery.of(context).padding.top + 16, 20, 22),
            decoration: BoxDecoration(
              gradient: context.headerGradient,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                IconButton(
                  icon:
                      const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: _handleBackNavigation,
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text('Submit Pembayaran',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ]),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(
                    left:
                        48), // Padding disesuaikan agar sejajar teks setelah tombol kembali
                child: Text(
                    'Selesaikan proses transaksi pembayaran tagihan Anda',
                    style: TextStyle(
                        fontSize: 12.5, color: Colors.white.withOpacity(0.85))),
              ),
            ]),
          ),
        ),

        // Konten utama halaman di dalam Slivers
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
          sliver: SliverToBoxAdapter(
            child: _loadingInvoice
                ? const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        if (_invoice != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: AppColors.primary.withOpacity(0.2))),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${_invoice!['title']}',
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary)),
                                  if (_invoice!['period'] != null)
                                    Text('Periode: ${_invoice!['period']}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecond)),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Nominal: ${CurrencyFormatter.format(invoiceNominal)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (_invoice!['deadline'] != null)
                                    Text('Deadline: ${_invoice!['deadline']}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.error)),
                                ]),
                          ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border)),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                    'Anda akan diarahkan ke halaman pembayaran Midtrans untuk membayar dengan kartu, Virtual Account, QRIS, atau e-wallet.',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecond)),
                                const SizedBox(height: 8),
                                Text(
                                  'Total: ${CurrencyFormatter.format(invoiceNominal)}',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary),
                                ),
                              ]),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _submitting ? null : _payWithMidtrans,
                            icon: _submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.lock_rounded, size: 18),
                            label: Text(_submitting
                                ? 'Memproses...'
                                : 'Bayar Sekarang dengan Midtrans'),
                          ),
                        ),
                        if (_submitting) ...[
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  size: 16, color: AppColors.textSecond),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Menunggu konfirmasi dari Midtrans (±15 detik). Kalau metode pembayaran '
                                  'Anda butuh waktu lebih lama (mis. transfer VA), Anda akan diarahkan ke '
                                  'halaman detail pembayaran dan bisa mengecek statusnya lagi dari sana.',
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecond,
                                      height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ]),
          ),
        ),
      ]),
    );
  }
}
