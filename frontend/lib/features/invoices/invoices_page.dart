import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_cache.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/utils/snackbar_helper.dart';
import '../auth/auth_provider.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});
  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  List<dynamic> _invoices = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  String? _statusFilter;
  int _page = 1;
  bool _hasMore = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Fungsi navigasi kembali berdasarkan role
  void _handleBackNavigation() {
    final isAdmin = context.read<AuthProvider>().isAdmin;
    if (isAdmin) {
      context.go('/admin/dashboard');
    } else {
      context.go('/warga/dashboard');
    }
  }

  Future<void> _load({bool reset = true, bool forceRefresh = false}) async {
    final isAdmin = context.read<AuthProvider>().isAdmin;
    // Cache hanya dipakai untuk tampilan awal polos (halaman 1, tanpa
    // pencarian) — kasus paling umum saat tab "Tagihan" baru dibuka.
    // Pencarian & "muat lebih banyak" tetap selalu ke server seperti biasa.
    final cacheKey = 'invoices_${isAdmin ? 'admin' : 'warga'}';
    final useCache = reset && _search.isEmpty;

    if (useCache && !forceRefresh) {
      final cached = AppCache.instance.get<List<dynamic>>(cacheKey);
      if (cached != null) {
        setState(() {
          _invoices = cached;
          _loading = false;
        });
      } else if (reset) {
        setState(() {
          _loading = true;
          _page = 1;
          _invoices = [];
          _error = null;
        });
      }
    } else if (reset) {
      setState(() {
        _loading = true;
        _page = 1;
        _invoices = [];
        _error = null;
      });
    }
    try {
      final endpoint = isAdmin ? '/admin/invoices' : '/invoices';
      final params = <String, dynamic>{'page': _page, 'per_page': 20};
      if (_search.isNotEmpty) params['search'] = _search;
      final res = await ApiClient().get(endpoint, params: params);
      if (res.data['success'] == true) {
        final data = res.data['data'];
        final items = (data['data'] as List?) ?? [];
        final newList = reset ? items : [..._invoices, ...items];
        if (useCache) AppCache.instance.set(cacheKey, newList);
        if (!mounted) return;
        setState(() {
          _invoices = newList;
          _hasMore = _page < (data['last_page'] ?? 1);
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (!useCache || AppCache.instance.get<List<dynamic>>(cacheKey) == null) {
        setState(() {
          _error = 'Gagal memuat tagihan';
          _loading = false;
        });
      }
    }
  }

  List<dynamic> get _filtered {
    if (_statusFilter == null) return _invoices;
    return _invoices.where((i) {
      final status = i['payment_status'] as String? ??
          (i['is_active'] == true ? 'unpaid' : 'inactive');
      return status == _statusFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;
    // Default true kalau field belum ada di response (aman untuk data lama).
    final canPay = auth.user?['can_pay'] != false;
    return Scaffold(
      backgroundColor: context.colorBg,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.fromLTRB(
                12,
                MediaQuery.of(context).padding.top + 8,
                20,
                22), // Padding disesuaikan untuk tombol back
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
                Expanded(
                  child: Text(isAdmin ? 'Kelola Tagihan' : 'Tagihan Saya',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.18)),
                    onPressed: () => _showAddSheet(context),
                  ),
              ]),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(
                    left: 48.0), // Meluruskan teks deskripsi dengan judul utama
                child: Text('Kelola dan pantau status pembayaranmu',
                    style: TextStyle(
                        fontSize: 12.5, color: Colors.white.withOpacity(0.85))),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Cari tagihan...',
                      hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.7), fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: Colors.white.withOpacity(0.85), size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 14),
                    ),
                    onChanged: (v) {
                      _search = v;
                      if (v.length >= 2 || v.isEmpty) _load();
                    },
                  ),
                ),
              ),
            ]),
          ),
        ),
        if (!isAdmin)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _pill('Semua', Icons.apps_rounded, null),
                    const SizedBox(width: 10),
                    _pill('Belum Bayar', Icons.receipt_long_rounded, 'unpaid'),
                    const SizedBox(width: 10),
                    _pill('Lunas', Icons.check_circle_rounded, 'confirmated'),
                  ],
                ),
              ),
            ),
          ),
        if (_loading)
          const SliverToBoxAdapter(
              child: Padding(padding: EdgeInsets.all(16), child: ShimmerList()))
        else if (_error != null)
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ErrorState(message: _error!, onRetry: _load)))
        else if (_filtered.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: EmptyState(
                  icon: Icons.receipt_long_rounded,
                  title: 'Tidak ada tagihan',
                  subtitle: isAdmin
                      ? 'Tap + untuk membuat tagihan baru'
                      : 'Semua tagihan sudah dilunasi!',
                  action: isAdmin
                      ? ElevatedButton.icon(
                          onPressed: () => _showAddSheet(context),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Buat Tagihan'),
                          style: ElevatedButton.styleFrom(
                              minimumSize: const Size(160, 44)))
                      : null),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  if (i == _filtered.length)
                    return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                            child: OutlinedButton(
                                onPressed: () {
                                  _page++;
                                  _load(reset: false);
                                },
                                child: const Text('Muat Lebih'))));
                  return _invoiceCard(_filtered[i],
                      isAdmin: isAdmin, canPay: canPay);
                },
                childCount: _filtered.length + (_hasMore ? 1 : 0),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _pill(String label, IconData icon, String? value) {
    final s = _statusFilter == value;
    return CategoryPill(
      label: label,
      icon: icon,
      selected: s,
      onTap: () => setState(() => _statusFilter = value),
    );
  }

  Widget _invoiceCard(Map<String, dynamic> inv,
      {required bool isAdmin, bool canPay = true}) {
    final status = inv['payment_status'] as String? ?? 'unpaid';
    final isOnlinePending =
        status == 'pending' && inv['payment_channel'] == 'midtrans';
    final nominal = double.tryParse(inv['nominal']?.toString() ?? '') ?? 0.0;
    final isActive = inv['is_active'] == true;
    final accent = status == 'confirmated'
        ? AppColors.confirmatedText
        : AppColors.unpaidText;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.colorSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colorBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(context.isDarkMode ? 0.18 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: accent.withOpacity(context.isDarkMode ? 0.18 : 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Image.asset('assets/images/kantong-uang.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.receipt_long_rounded, color: accent)),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('${inv['title']}',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.colorTextPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  if (inv['period'] != null)
                    Text('Periode: ${inv['period']}',
                        style: TextStyle(
                            fontSize: 12, color: context.colorTextSecond)),
                  if (inv['deadline'] != null)
                    Text('Deadline: ${inv['deadline']}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.error)),
                ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(CurrencyFormatter.format(nominal),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.colorTextPrimary)),
              const SizedBox(height: 6),
              if (!isAdmin) StatusBadge(status, isProcessing: isOnlinePending),
              if (isAdmin)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.confirmatedBg
                          : AppColors.unpaidBg,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(isActive ? 'Aktif' : 'Nonaktif',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? AppColors.confirmatedText
                              : AppColors.unpaidText)),
                ),
            ]),
          ]),
        ),
        if (!isAdmin && status == 'unpaid' && isActive && canPay) ...[
          Divider(height: 1, color: context.colorBorder),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton(
              onPressed: () =>
                  context.go('/warga/payments/submit/${inv['id']}'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40)),
              child: const Text('Bayar Sekarang'),
            ),
          ),
        ],
        // Tombol Bayar dinonaktifkan sementara oleh admin untuk warga ini
        // (lihat UserController::disablePayment) — beri tahu kenapa,
        // jangan biarkan tagihan ini terlihat "hilang" begitu saja.
        if (!isAdmin && status == 'unpaid' && isActive && !canPay) ...[
          Divider(height: 1, color: context.colorBorder),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pembayaran untuk akun Anda sedang dinonaktifkan '
                    'sementara oleh admin. Hubungi admin RT untuk info '
                    'lebih lanjut.',
                    style: TextStyle(
                        fontSize: 11.5,
                        color: context.colorTextSecond,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
        // Kalau ada pembayaran online yang masih menunggu konfirmasi
        // Midtrans untuk tagihan ini, tombol "Bayar Sekarang" sengaja
        // disembunyikan (supaya tidak dobel bayar) — tapi beri tahu warga
        // kenapa, dan kasih jalan pintas untuk cek statusnya langsung,
        // alih-alih terlihat seperti tagihan ini "hilang begitu saja".
        if (!isAdmin && isOnlinePending) ...[
          Divider(height: 1, color: context.colorBorder),
          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton.icon(
              onPressed: () =>
                  context.go('/warga/payments/${inv['payment_id']}'),
              icon: const Icon(Icons.hourglass_top_rounded, size: 16),
              label: const Text('Menunggu konfirmasi — lihat status'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40)),
            ),
          ),
        ],
        if (isAdmin) ...[
          Divider(height: 1, color: context.colorBorder),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (inv['paid_count'] != null)
                Text('${inv['paid_count']} lunas',
                    style: TextStyle(
                        fontSize: 12, color: context.colorTextSecond)),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  onPressed: () => _showAddSheet(context, invoice: inv),
                  color: context.colorTextSecond,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints()),
              const SizedBox(width: 16),
              IconButton(
                  icon: const Icon(Icons.delete_rounded, size: 18),
                  onPressed: () => _deleteInvoice(inv['id']),
                  color: AppColors.error,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints()),
            ]),
          ),
        ],
      ]),
    );
  }

  Future<void> _deleteInvoice(int id) async {
    final ok = await showConfirmDialog(context,
        title: 'Hapus Tagihan',
        message: 'Tagihan ini akan dihapus.',
        isDangerous: true);
    if (!ok) return;
    try {
      await ApiClient().delete('/admin/invoices/$id');
      _load();
    } catch (_) {}
  }

  void _showAddSheet(BuildContext context, {Map<String, dynamic>? invoice}) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _InvoiceFormSheet(invoice: invoice, onSaved: _load));
  }
}

class _InvoiceFormSheet extends StatefulWidget {
  final Map<String, dynamic>? invoice;
  final VoidCallback onSaved;
  const _InvoiceFormSheet({this.invoice, required this.onSaved});
  @override
  State<_InvoiceFormSheet> createState() => _InvoiceFormSheetState();
}

class _InvoiceFormSheetState extends State<_InvoiceFormSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _nominalCtrl = TextEditingController();
  final _periodCtrl = TextEditingController();
  final _deadlineCtrl = TextEditingController();
  bool _saving = false;
  bool get isEdit => widget.invoice != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final inv = widget.invoice!;
      _titleCtrl.text = inv['title'] ?? '';
      _descCtrl.text = inv['description'] ?? '';

      // ✨ Konversi aman dari String desimal Laravel ke int lalu ke String form input
      final nominalDouble =
          double.tryParse(inv['nominal']?.toString() ?? '') ?? 0.0;
      _nominalCtrl.text =
          nominalDouble > 0 ? nominalDouble.toInt().toString() : '';

      _periodCtrl.text = inv['period'] ?? '';
      _deadlineCtrl.text = inv['deadline'] ?? '';
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.isEmpty || _nominalCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      final data = {
        'title': _titleCtrl.text,
        'description': _descCtrl.text,
        'nominal':
            double.parse(_nominalCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')),
        if (_periodCtrl.text.isNotEmpty) 'period': _periodCtrl.text,
        if (_deadlineCtrl.text.isNotEmpty) 'deadline': _deadlineCtrl.text,
        'is_active': true,
      };
      isEdit
          ? await ApiClient()
              .put('/admin/invoices/${widget.invoice!['id']}', data: data)
          : await ApiClient().post('/admin/invoices', data: data);
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (_) {
      if (mounted)
        SnackBarHelper.show(context, 'Gagal menyimpan.', isError: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 70),
      decoration: BoxDecoration(
          color: context.colorSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: context.colorBorder,
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(isEdit ? 'Edit Tagihan' : 'Buat Tagihan Baru',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.colorTextPrimary)),
            const SizedBox(height: 16),
            TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                    labelText: 'Judul Tagihan *',
                    prefixIcon: Icon(Icons.receipt_long_rounded, size: 20))),
            const SizedBox(height: 10),
            TextField(
                controller: _nominalCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Nominal (Rp) *',
                    prefixIcon: Icon(Icons.attach_money_rounded, size: 20))),
            const SizedBox(height: 10),
            TextField(
                controller: _periodCtrl,
                decoration: const InputDecoration(
                    labelText: 'Periode (mis: Januari 2025)',
                    prefixIcon: Icon(Icons.calendar_today_rounded, size: 20))),
            const SizedBox(height: 10),
            TextField(
              controller: _deadlineCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                  labelText: 'Deadline',
                  prefixIcon: Icon(Icons.event_rounded, size: 20),
                  suffixIcon: Icon(Icons.arrow_drop_down)),
              onTap: () async {
                final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030));
                if (d != null)
                  setState(() => _deadlineCtrl.text =
                      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
              },
            ),
            const SizedBox(height: 10),
            TextField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Deskripsi (opsional)',
                    prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: Icon(Icons.notes_rounded, size: 20)))),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(isEdit ? 'Simpan Perubahan' : 'Buat Tagihan'),
            ),
          ]),
    );
  }
}
