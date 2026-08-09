import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/widgets/common_widgets.dart';

class WargaDetailPage extends StatefulWidget {
  final int userId;
  const WargaDetailPage({super.key, required this.userId});
  @override
  State<WargaDetailPage> createState() => _WargaDetailPageState();
}

class _WargaDetailPageState extends State<WargaDetailPage> {
  Map<String, dynamic>? _user;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Fungsi navigasi kembali dengan fallback ke halaman daftar warga
  void _handleBackNavigation() {
    if (context.canPop()) {
      context.pop(); // Kembali ke halaman sebelum ini secara otomatis
    } else {
      context.go('/admin/warga'); // Fallback menuju WargaListPage
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient().get('/admin/users/${widget.userId}');
      if (res.data['success'] == true)
        setState(() {
          _user = res.data['data'];
          _loading = false;
        });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data warga';
        _loading = false;
      });
    }
  }

  Future<void> _deactivate() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Nonaktifkan Warga',
      message:
          'Akun warga ini akan dinonaktifkan dan tidak dapat login. Lanjutkan?',
      confirmLabel: 'Nonaktifkan',
      isDangerous: true,
    );
    if (!ok) return;
    try {
      await ApiClient().delete('/admin/users/${widget.userId}');
      if (mounted) {
        SnackBarHelper.show(context, 'Warga berhasil dinonaktifkan.',
            isSuccess: true);
        _load();
      }
    } catch (e) {
      if (mounted)
        SnackBarHelper.show(context, 'Gagal menonaktifkan warga.',
            isError: true);
    }
  }

  Future<void> _activate() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Aktifkan Warga',
      message:
          'Akun warga ini akan diaktifkan kembali dan dapat login. Lanjutkan?',
      confirmLabel: 'Aktifkan',
    );
    if (!ok) return;
    try {
      await ApiClient().patch('/admin/users/${widget.userId}/activate');
      if (mounted) {
        SnackBarHelper.show(context, 'Warga berhasil diaktifkan kembali.',
            isSuccess: true);
        _load();
      }
    } catch (e) {
      if (mounted)
        SnackBarHelper.show(context, 'Gagal mengaktifkan warga.',
            isError: true);
    }
  }

  Future<void> _disablePayment() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Nonaktifkan Tombol Bayar',
      message: 'Tombol "Bayar" akan disembunyikan khusus untuk warga ini. '
          'Warga tetap bisa login dan tetap melihat tagihannya seperti '
          'biasa — hanya saja tidak bisa membayar lewat aplikasi sampai '
          'Anda aktifkan kembali. Cocok untuk warga yang sedang kesusahan '
          'dan diberi keringanan sementara. Lanjutkan?',
      confirmLabel: 'Nonaktifkan',
      isDangerous: true,
    );
    if (!ok) return;
    try {
      await ApiClient().patch('/admin/users/${widget.userId}/disable-payment');
      if (mounted) {
        SnackBarHelper.show(
            context, 'Tombol bayar warga ini berhasil dinonaktifkan.',
            isSuccess: true);
        _load();
      }
    } catch (e) {
      if (mounted)
        SnackBarHelper.show(context, 'Gagal menonaktifkan tombol bayar.',
            isError: true);
    }
  }

  Future<void> _enablePayment() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Aktifkan Tombol Bayar',
      message:
          'Tombol "Bayar" akan ditampilkan kembali untuk warga ini. Lanjutkan?',
      confirmLabel: 'Aktifkan',
    );
    if (!ok) return;
    try {
      await ApiClient().patch('/admin/users/${widget.userId}/enable-payment');
      if (mounted) {
        SnackBarHelper.show(
            context, 'Tombol bayar warga ini berhasil diaktifkan kembali.',
            isSuccess: true);
        _load();
      }
    } catch (e) {
      if (mounted)
        SnackBarHelper.show(context, 'Gagal mengaktifkan tombol bayar.',
            isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _user?['is_active'] == true;

    return Scaffold(
      backgroundColor: context.colorBg,
      body: CustomScrollView(slivers: [
        // ✨ Header Baru yang disamakan dengan InvoicesPage (Tanpa AppBar bawaan)
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.fromLTRB(
                12, MediaQuery.of(context).padding.top + 16, 12, 28),
            decoration: BoxDecoration(
              gradient: context.headerGradient,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Action Bar di dalam header (Back, Title, Actions)
                Row(children: [
                  // Menambahkan Tombol Kembali di pojok kiri atas header
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                    onPressed: _handleBackNavigation,
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Detail Warga',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                  ),
                  if (_user != null) ...[
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: Colors.white),
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.18)),
                      onPressed: () =>
                          context.go('/admin/warga/${widget.userId}/edit'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                          isActive
                              ? Icons.person_off_rounded
                              : Icons.person_add_alt_1_rounded,
                          color: Colors.white),
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.18)),
                      onPressed: isActive ? _deactivate : _activate,
                    ),
                  ],
                ]),
                const SizedBox(height: 24),

                // Profil Warga Komponen
                if (_user != null) ...[
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: _user!['profile_photo'] != null
                        ? NetworkImage(_user!['profile_photo'])
                        : null,
                    child: _user!['profile_photo'] == null
                        ? Text(
                            '${(_user!['name'] as String? ?? 'U')[0].toUpperCase()}',
                            style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_user!['name']}',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_user!['rt_rw'] ?? '-'}',
                    style: TextStyle(
                        fontSize: 13, color: Colors.white.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white.withOpacity(0.2)
                          : Colors.red.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isActive ? '● Aktif' : '● Nonaktif',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Konten utama halaman dalam bentuk Slivers
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _error != null
                    ? ErrorState(message: _error!, onRetry: _load)
                    : _buildContent(),
          ),
        ),
      ]),
    );
  }

  Widget _buildContent() {
    final u = _user!;
    // Default true kalau field belum ada di response (aman untuk data lama).
    final canPay = u['can_pay'] != false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pengaturan tombol Bayar (independen dari status aktif akun)
        _card('Pengaturan Pembayaran', [
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tombol Bayar',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.colorTextPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    canPay
                        ? 'Warga ini bisa membayar tagihan seperti biasa.'
                        : 'Tombol Bayar disembunyikan sementara untuk warga ini.',
                    style: TextStyle(
                        fontSize: 11.5, color: context.colorTextSecond),
                  ),
                ],
              ),
            ),
            Switch(
              value: canPay,
              activeColor: AppColors.primary,
              onChanged: (v) => v ? _enablePayment() : _disablePayment(),
            ),
          ]),
          if (!canPay) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Cocok untuk kasus warga yang sedang kesusahan / '
                      'diberi keringanan sementara. Warga tetap bisa login '
                      '& melihat tagihannya, tapi tidak bisa membayar lewat '
                      'aplikasi sampai Anda aktifkan kembali.',
                      style: TextStyle(
                          fontSize: 11,
                          color: context.colorTextSecond,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ]),
        const SizedBox(height: 16),

        // Data diri
        _card('Data Diri', [
          InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: '${u['email'] ?? '-'}'),
          InfoRow(
              icon: Icons.phone_outlined,
              label: 'Nomor HP',
              value: '${u['phone'] ?? '-'}'),
          InfoRow(
              icon: Icons.badge_outlined,
              label: 'NIK',
              value: u['nik'] != null
                  ? '${(u['nik'] as String).replaceRange(4, u['nik'].length - 4, '••••••••')}'
                  : '-'),
          InfoRow(
              icon: Icons.home_outlined,
              label: 'Alamat',
              value: '${u['address'] ?? '-'}'),
          InfoRow(
              icon: Icons.location_on_outlined,
              label: 'RT/RW',
              value: '${u['rt_rw'] ?? '-'}'),
        ]),
        const SizedBox(height: 16),

        // Statistik pembayaran
        if ((u['recent_payments'] as List?)?.isNotEmpty == true ||
            u['payments_count'] != null) ...[
          _card('Riwayat Pembayaran', [
            InfoRow(
                icon: Icons.receipt_long_rounded,
                label: 'Total Transaksi',
                value: '${u['payments_count'] ?? 0} pembayaran'),
            const SizedBox(height: 4),
            ...(u['recent_payments'] as List? ?? []).map((p) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: context.colorSurfaceAlt,
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('${p['invoice'] ?? '-'}',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: context.colorTextPrimary)),
                          Text('${p['payment_date'] ?? '-'}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: context.colorTextSecond)),
                        ])),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(p['amount']),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: context.colorTextPrimary),
                        ),
                        const SizedBox(height: 2),
                        StatusBadge(p['status'] ?? 'unpaid'),
                      ],
                    )
                  ]),
                )),
          ]),
        ],
      ],
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: context.colorSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colorBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: context.colorTextPrimary)),
        Divider(height: 20, color: context.colorBorder),
        ...children,
      ]),
    );
  }
}
