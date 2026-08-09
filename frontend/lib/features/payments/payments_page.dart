import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import 'path_to_your_auth_provider.dart'; // Silakan sesuaikan import AuthProvider Anda di sini
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_cache.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/common_widgets.dart';

// ── Warga: riwayat pembayaran ─────────────────────────────────────────────────
class PaymentsWargaPage extends StatefulWidget {
  const PaymentsWargaPage({super.key});
  @override
  State<PaymentsWargaPage> createState() => _PaymentsWargaPageState();
}

class _PaymentsWargaPageState extends State<PaymentsWargaPage> {
  List<dynamic> _payments = [];
  bool _loading = true;
  String? _error;
  String? _statusFilter;
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Fungsi navigasi kembali ke dashboard
  void _handleBackNavigation() {
    // Jika Anda menggunakan provider, pastikan package 'provider' sudah diimport
    // final isAdmin = context.read<AuthProvider>().isAdmin;
    // Karena ini halaman Warga, langsung arahkan ke dashboard warga
    context.go('/warga/dashboard');
  }

  Future<void> _load({bool reset = true, bool forceRefresh = false}) async {
    const cacheKey = 'payments_warga';
    final useCache = reset && _statusFilter == null;

    if (useCache && !forceRefresh) {
      final cached = AppCache.instance.get<List<dynamic>>(cacheKey);
      if (cached != null) {
        setState(() {
          _payments = cached;
          _loading = false;
        });
      } else {
        setState(() {
          _loading = true;
          _page = 1;
          _payments = [];
          _error = null;
        });
      }
    } else if (reset) {
      setState(() {
        _loading = true;
        _page = 1;
        _payments = [];
        _error = null;
      });
    }
    try {
      final params = <String, dynamic>{'page': _page, 'per_page': 20};
      if (_statusFilter != null) params['status'] = _statusFilter;
      final res = await ApiClient().get('/payments/my', params: params);
      if (res.data['success'] == true) {
        final data = res.data['data'];
        final items = (data['data'] as List?) ?? [];
        final lastPg = data['last_page'] ?? 1;

        List<dynamic> combinedList = reset ? items : [..._payments, ...items];

        combinedList.sort((a, b) {
          DateTime dateA =
              DateTime.tryParse(a['payment_date']?.toString() ?? '') ??
                  DateTime(1970);
          DateTime dateB =
              DateTime.tryParse(b['payment_date']?.toString() ?? '') ??
                  DateTime(1970);
          return dateB.compareTo(dateA);
        });

        if (useCache) AppCache.instance.set(cacheKey, combinedList);
        if (!mounted) return;
        setState(() {
          _payments = combinedList;
          _hasMore = _page < lastPg;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (!useCache || AppCache.instance.get<List<dynamic>>(cacheKey) == null) {
        setState(() {
          _error = 'Gagal memuat riwayat';
          _loading = false;
        });
      }
    }
  }

  double get _totalPaid {
    double total = 0;
    for (final p in _payments) {
      if (p['status'] == 'confirmated') {
        total += double.tryParse(p['amount']?.toString() ?? '') ?? 0.0;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorBg,
      body: RefreshIndicator(
        onRefresh: () => _load(forceRefresh: true),
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  12,
                  MediaQuery.of(context).padding.top + 8,
                  20,
                  22), // padding disesuaikan untuk tombol back
              decoration: BoxDecoration(
                gradient: context.headerGradient,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Baris Judul + Tombol Back
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white),
                          onPressed: _handleBackNavigation,
                        ),
                        const Text('Riwayat Pembayaran',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 40.0), // Menyamakan alignment dengan teks atas
                      child: Text(
                          'Semua transaksi pembayaranmu tercatat di sini',
                          style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.white.withOpacity(0.85))),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: AppGradients.promo,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('TOTAL DIBAYAR',
                                    style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                        color: Colors.white.withOpacity(0.75))),
                                const SizedBox(height: 6),
                                Text(CurrencyFormatter.format(_totalPaid),
                                    style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white)),
                              ],
                            ),
                          ),
                          Image.asset('assets/images/uang-bersayap.png',
                              width: 52,
                              height: 52,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.payments_rounded,
                                  color: Colors.white,
                                  size: 40)),
                        ]),
                      ),
                    ),
                  ]),
            ),
          ),
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
                    _pill('Telah Membayar', Icons.check_circle_rounded,
                        'confirmated'),
                  ],
                ),
              ),
            ),
          ),
          if (_loading)
            const SliverToBoxAdapter(
                child:
                    Padding(padding: EdgeInsets.all(16), child: ShimmerList()))
          else if (_error != null)
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ErrorState(message: _error!, onRetry: _load)))
          else if (_payments.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'Belum ada riwayat pembayaran',
                    subtitle: 'Pembayaran yang Anda kirim akan muncul di sini'),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    if (i == _payments.length)
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                            child: OutlinedButton(
                                onPressed: () {
                                  _page++;
                                  _load(reset: false);
                                },
                                child: const Text('Muat Lebih Banyak'))),
                      );
                    return _paymentCard(_payments[i]);
                  },
                  childCount: _payments.length + (_hasMore ? 1 : 0),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _pill(String label, IconData icon, String? value) {
    final selected = _statusFilter == value;
    return CategoryPill(
      label: label,
      icon: icon,
      selected: selected,
      onTap: () {
        setState(() => _statusFilter = value);
        _load();
      },
    );
  }

  Widget _paymentCard(Map<String, dynamic> p) {
    final status = p['status'] ?? 'unpaid';
    final accent = status == 'confirmated'
        ? AppColors.confirmatedText
        : status == 'rejected'
            ? AppColors.rejectedText
            : AppColors.unpaidText;
    return PopularStyleCard(
      imageAsset: 'assets/images/uang-bersayap.png',
      title: '${p['invoice']?['title'] ?? '-'}',
      subtitle:
          '${p['payment_date'] ?? '-'} • ${p['channel'] == 'midtrans' ? 'Online (Midtrans)' : (p['method'] ?? '-')}',
      trailingTop: CurrencyFormatter.format(p['amount']),
      trailingBottom: StatusBadge(status,
          isProcessing: status == 'pending' && p['channel'] == 'midtrans'),
      accentColor: accent,
      onTap: () => context.go('/warga/payments/${p['id']}'),
    );
  }
}

// ── Admin: semua pembayaran ───────────────────────────────────────────────────
class PaymentsAdminPage extends StatefulWidget {
  const PaymentsAdminPage({super.key});
  @override
  State<PaymentsAdminPage> createState() => _PaymentsAdminPageState();
}

class _PaymentsAdminPageState extends State<PaymentsAdminPage> {
  List<dynamic> _payments = [];
  bool _loading = true;
  String? _error;
  String? _statusFilter;
  String _search = '';
  int _page = 1;
  bool _hasMore = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Fungsi navigasi kembali ke dashboard admin
  void _handleBackNavigation() {
    context.go('/admin/dashboard');
  }

  Future<void> _load({bool reset = true, bool forceRefresh = false}) async {
    const cacheKey = 'payments_admin';
    final useCache = reset && _statusFilter == null && _search.isEmpty;

    if (useCache && !forceRefresh) {
      final cached = AppCache.instance.get<List<dynamic>>(cacheKey);
      if (cached != null) {
        setState(() {
          _payments = cached;
          _loading = false;
        });
      } else {
        setState(() {
          _loading = true;
          _page = 1;
          _payments = [];
          _error = null;
        });
      }
    } else if (reset) {
      setState(() {
        _loading = true;
        _page = 1;
        _payments = [];
        _error = null;
      });
    }
    try {
      final params = <String, dynamic>{'page': _page, 'per_page': 20};
      if (_statusFilter != null) params['status'] = _statusFilter;
      if (_search.isNotEmpty) params['search'] = _search;
      final res = await ApiClient().get('/admin/payments', params: params);
      if (res.data['success'] == true) {
        final data = res.data['data'];
        final items = (data['data'] as List?) ?? [];

        List<dynamic> combinedList = reset ? items : [..._payments, ...items];

        combinedList.sort((a, b) {
          DateTime dateA =
              DateTime.tryParse(a['payment_date']?.toString() ?? '') ??
                  DateTime(1970);
          DateTime dateB =
              DateTime.tryParse(b['payment_date']?.toString() ?? '') ??
                  DateTime(1970);
          return dateB.compareTo(dateA);
        });

        if (useCache) AppCache.instance.set(cacheKey, combinedList);
        if (!mounted) return;
        setState(() {
          _payments = combinedList;
          _hasMore = _page < (data['last_page'] ?? 1);
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (!useCache || AppCache.instance.get<List<dynamic>>(cacheKey) == null) {
        setState(() {
          _error = 'Gagal memuat';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorBg,
      body: RefreshIndicator(
        onRefresh: () => _load(forceRefresh: true),
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  12,
                  MediaQuery.of(context).padding.top + 8,
                  20,
                  22), // padding disesuaikan untuk tombol back
              decoration: BoxDecoration(
                gradient: context.headerGradient,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baris Judul + Tombol Back
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white),
                        onPressed: _handleBackNavigation,
                      ),
                      const Text(
                        'Daftar Pembayaran',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 40.0), // Menyamakan alignment teks deskripsi
                    child: Text(
                      'Pantau seluruh transaksi pembayaran warga (otomatis terkonfirmasi)',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white.withOpacity(0.85)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Cari nama warga...',
                          hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: Colors.white.withOpacity(0.85), size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 14),
                        ),
                        onChanged: (v) {
                          _search = v;
                          if (v.length >= 3 || v.isEmpty) _load();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _chip('Semua', null),
                  const SizedBox(width: 8),
                  _chip('Telah Membayar', 'confirmated'),
                ]),
              ),
            ),
          ),
          if (_loading)
            const SliverToBoxAdapter(
                child:
                    Padding(padding: EdgeInsets.all(16), child: ShimmerList()))
          else if (_error != null)
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ErrorState(message: _error!, onRetry: _load)))
          else if (_payments.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'Tidak ada pembayaran'),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    if (i == _payments.length)
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: OutlinedButton(
                            onPressed: () {
                              _page++;
                              _load(reset: false);
                            },
                            child: const Text('Muat Lebih Banyak'),
                          ),
                        ),
                      );
                    return _adminPaymentCard(_payments[i]);
                  },
                  childCount: _payments.length + (_hasMore ? 1 : 0),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _chip(String label, String? value) {
    final s = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: s,
      onSelected: (_) {
        setState(() => _statusFilter = value);
        _load();
      },
      selectedColor: AppColors.primary.withOpacity(0.15),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: s ? AppColors.primary : context.colorTextSecond),
    );
  }

  Widget _adminPaymentCard(Map<String, dynamic> p) {
    return InkWell(
      onTap: () => context.go('/admin/payments/${p['id']}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colorSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colorBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.receipt_rounded,
                    size: 20, color: AppColors.primary)),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('${p['user']?['name'] ?? '-'}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.colorTextPrimary)),
                  Text('${p['user']?['rt_rw'] ?? '-'}',
                      style: TextStyle(
                          fontSize: 11, color: context.colorTextSecond)),
                ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                CurrencyFormatter.format(p['amount']),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.colorTextPrimary),
              ),
              const SizedBox(height: 4),
              StatusBadge(p['status'] ?? 'unpaid',
                  isProcessing:
                      p['status'] == 'pending' && p['channel'] == 'midtrans'),
            ]),
          ]),
          const SizedBox(height: 8),
          Divider(height: 1, color: context.colorBorder),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${p['invoice']?['title'] ?? '-'}',
                style: TextStyle(fontSize: 12, color: context.colorTextSecond)),
            Text('${p['payment_date'] ?? '-'}',
                style: TextStyle(fontSize: 12, color: context.colorTextSecond)),
          ]),
        ]),
      ),
    );
  }
}
