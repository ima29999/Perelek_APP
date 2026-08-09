import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; // ✨ Ditambahkan untuk membaca AuthProvider
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_cache.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/widgets/common_widgets.dart';
import '../auth/auth_provider.dart'; // ✨ Ditambahkan untuk mendeteksi role pengguna

class PaymentDetailPage extends StatefulWidget {
  final int paymentId;
  const PaymentDetailPage({super.key, required this.paymentId});
  @override
  State<PaymentDetailPage> createState() => _PaymentDetailPageState();
}

class _PaymentDetailPageState extends State<PaymentDetailPage> {
  Map<String, dynamic>? _payment;
  bool _loading = true;
  bool _syncing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ✨ PERBAIKAN: Fungsi navigasi kembali dengan cek role untuk rute fallback yang tepat
  void _handleBackNavigation() {
    if (context.canPop()) {
      context
          .pop(); // Kembali ke halaman sebelum ini secara otomatis jika ada di stack
    } else {
      final isAdmin = context.read<AuthProvider>().isAdmin;
      if (isAdmin) {
        context.go('/admin/payments'); // Fallback ke riwayat pembayaran Admin
      } else {
        context.go(
            '/warga/payments'); // Fallback ke riwayat pembayaran Warga (sesuaikan rute aplikasi Anda jika berbeda)
      }
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient().get('/payments/${widget.paymentId}');
      if (res.data['success'] == true) {
        setState(() {
          _payment = res.data['data'];
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat detail';
        _loading = false;
      });
    }
  }

  bool get _isPendingOnline =>
      _payment != null &&
      _payment!['channel'] == 'midtrans' &&
      _payment!['status'] == 'pending';

  /// Minta backend mengecek ULANG status pembayaran ini langsung ke
  /// Midtrans (Get Status API) — jaring pengaman manual untuk pembayaran
  /// yang masih 'pending' di sini, mis. karena webhook Midtrans belum/tidak
  /// sampai ke server (umum terjadi saat development di localhost). Tombol
  /// ini memakai endpoint yang sama dengan sinkronisasi otomatis, jadi
  /// tetap 100% terverifikasi ke Midtrans — bukan admin menandai lunas
  /// secara sepihak.
  Future<void> _syncStatus() async {
    setState(() => _syncing = true);
    try {
      final res = await ApiClient()
          .get('/payments/midtrans/${widget.paymentId}/status');
      if (res.data['success'] == true) {
        final newStatus = res.data['data']?['status'];
        AppCache.instance.invalidate('payments_warga');
        AppCache.instance.invalidate('payments_admin');
        AppCache.instance.invalidate('warga_dashboard');
        AppCache.instance.invalidate('admin_dashboard');
        AppCache.instance.invalidate('invoices_warga');
        AppCache.instance.invalidate('invoices_admin');
        if (!mounted) return;
        if (newStatus == 'confirmated') {
          SnackBarHelper.show(
              context, 'Pembayaran terkonfirmasi. Saldo sudah diperbarui.',
              isSuccess: true);
        } else if (newStatus == 'rejected') {
          SnackBarHelper.show(context, 'Pembayaran ditolak oleh Midtrans.',
              isError: true);
        } else {
          SnackBarHelper.show(context,
              'Belum ada perubahan — Midtrans masih memproses pembayaran ini.');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.show(context, 'Gagal mengecek status.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Pembayaran'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _handleBackNavigation,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : _buildDetail(),
    );
  }

  Widget _buildDetail() {
    final p = _payment!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Status banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p['status'] == 'confirmated'
                ? AppColors.confirmatedBg
                : p['status'] == 'rejected'
                    ? AppColors.rejectedBg
                    : AppColors.unpaidBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(
                  p['status'] == 'confirmated'
                      ? Icons.check_circle_rounded
                      : p['status'] == 'rejected'
                          ? Icons.cancel_rounded
                          : Icons.hourglass_empty_rounded,
                  color: p['status'] == 'confirmated'
                      ? AppColors.confirmatedText
                      : p['status'] == 'rejected'
                          ? AppColors.rejectedText
                          : AppColors.unpaidText,
                  size: 22),
              const SizedBox(width: 8),
              StatusBadge(p['status'] ?? 'unpaid',
                  isProcessing: _isPendingOnline),
            ]),
            if (p['notes'] != null && (p['notes'] as String).isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Catatan: ${p['notes']}',
                  style: TextStyle(
                      fontSize: 12,
                      color: p['status'] == 'rejected'
                          ? AppColors.rejectedText
                          : AppColors.unpaidText)),
            ],
            if (_isPendingOnline) ...[
              const SizedBox(height: 8),
              Text(
                'Pembayaran online sedang diproses/menunggu konfirmasi otomatis '
                'dari Midtrans. Ini BUKAN berarti pembayaran gagal — begitu '
                'Midtrans mengonfirmasi, status akan otomatis berubah menjadi '
                '"Telah Membayar" dan saldo langsung bertambah tanpa perlu '
                'tindakan admin apapun.\n\n'
                'Catatan untuk testing di mode Sandbox: beberapa metode (mis. '
                'Virtual Account/transfer bank) baru dianggap "selesai" oleh '
                'Midtrans setelah disimulasikan lunas lewat Midtrans Simulator '
                '(simulator.sandbox.midtrans.com) — sekadar sampai ke halaman '
                '"selesai" di Snap belum tentu berarti Midtrans sudah mencatatnya '
                'sebagai lunas.',
                style: TextStyle(
                    fontSize: 12, color: AppColors.unpaidText, height: 1.4),
              ),
            ],
          ]),
        ),
        if (_isPendingOnline) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _syncing ? null : _syncStatus,
              icon: _syncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                  _syncing ? 'Mengecek ke Midtrans...' : 'Cek Status Terbaru'),
            ),
          ),
        ],
        const SizedBox(height: 20),

        // Info tagihan
        _section('Informasi Tagihan', [
          InfoRow(
              icon: Icons.receipt_rounded,
              label: 'Tagihan',
              value: '${p['invoice']?['title'] ?? '-'}'),
          InfoRow(
              icon: Icons.calendar_today_rounded,
              label: 'Periode',
              value: '${p['invoice']?['period'] ?? '-'}'),

          // ✨ Langsung oper nominal invoice mentah ke formatter
          InfoRow(
            icon: Icons.attach_money_rounded,
            label: 'Nominal Tagihan',
            value: CurrencyFormatter.format(p['invoice']?['nominal']),
          ),
        ]),
        const SizedBox(height: 16),

        // Info pembayaran
        _section('Detail Pembayaran', [
          // ✨ Langsung oper jumlah dibayar mentah ke formatter
          InfoRow(
            icon: Icons.payments_rounded,
            label: 'Jumlah Dibayar',
            value: CurrencyFormatter.format(p['amount']),
            valueColor: AppColors.success,
          ),
          InfoRow(
              icon: Icons.date_range_rounded,
              label: 'Tanggal Bayar',
              value: '${p['payment_date'] ?? '-'}'),
          InfoRow(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Metode',
              value: p['channel'] == 'midtrans'
                  ? 'Midtrans (Online)'
                  : '${p['method'] ?? '-'}'),
        ]),
        const SizedBox(height: 16),

        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _section(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const Divider(height: 20),
        ...rows,
      ]),
    );
  }
}
