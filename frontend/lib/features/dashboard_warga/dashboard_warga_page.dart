import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_cache.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/common_widgets.dart';
import '../auth/auth_provider.dart';
import '../notifications/notification_provider.dart';

class DashboardWargaPage extends StatefulWidget {
  const DashboardWargaPage({super.key});
  @override
  State<DashboardWargaPage> createState() => _DashboardWargaPageState();
}

class _DashboardWargaPageState extends State<DashboardWargaPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().load();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    final cached =
        AppCache.instance.get<Map<String, dynamic>>('warga_dashboard');
    if (cached != null && !forceRefresh) {
      setState(() {
        _data = cached;
        _loading = false;
      });
      _animCtrl.forward(from: 0);
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final res = await ApiClient()
          .get('/dashboard', params: forceRefresh ? {'fresh': 1} : null);
      if (res.data['success'] == true) {
        AppCache.instance.set('warga_dashboard', res.data['data']);
        if (!mounted) return;
        setState(() {
          _data = res.data['data'];
          _loading = false;
        });
        _animCtrl.forward(from: 0);
      }
    } catch (e) {
      if (!mounted) return;
      if (cached == null) {
        setState(() {
          _error = 'Gagal memuat dashboard';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final screenW = MediaQuery.of(context).size.width;
    final isTablet = screenW >= 600;

    return Scaffold(
      backgroundColor: context.colorBg,
      body: RefreshIndicator(
        onRefresh: () => _load(forceRefresh: true),
        color: AppColors.primary,
        child: CustomScrollView(slivers: [
          // ── Header gaya "food delivery" — gradasi hangat + foto profil ──
          SliverAppBar(
            expandedHeight: isTablet ? 230 : 208,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: context.isDarkMode
                ? const Color(0xFF17110E)
                : AppColors.primary,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.blurBackground],
              background:
                  _WargaHeader(user: user, loading: _loading, data: _data),
            ),
          ),

          // ── Body ────────────────────────────────────────────
          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                  padding: EdgeInsets.all(16), child: ShimmerList(count: 5)),
            ),
          if (_error != null)
            SliverToBoxAdapter(
                child: ErrorState(message: _error!, onRetry: _load)),
          if (!_loading && _data != null)
            SliverFadeTransition(
              opacity: _fadeAnim,
              sliver: SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24 : 16,
                  vertical: 18,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Kartu ringkasan saldo (gaya banner promo) ──
                    _PaidThisYearCard(data: _data!),
                    const SizedBox(height: 22),

                    // ── Layanan — gaya chip "All / Burger / Sushi" ─
                    const SectionHeaderX(title: 'Layanan'),
                    const SizedBox(height: 12),
                    _buildServiceChips(context),
                    const SizedBox(height: 22),

                    // ── Tagihan urgent (gaya "Popular Now") ────────
                    _UnpaidSection(data: _data!),

                    // ── Kegiatan mendatang ─────────────────
                    if ((_data!['upcoming_events'] as List?)?.isNotEmpty ==
                        true) ...[
                      SectionHeaderX(
                          title: 'Kegiatan Mendatang',
                          actionLabel: 'Lihat',
                          onAction: () => context.go('/warga/events')),
                      const SizedBox(height: 10),
                      ...(_data!['upcoming_events'] as List)
                          .map((e) => _EventCard(e: e)),
                      const SizedBox(height: 20),
                    ],

                    const SizedBox(height: 16),
                  ]),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildServiceChips(BuildContext context) {
    final items = [
      _SvcItem('assets/images/kantong-uang.png', Icons.receipt_rounded,
          'Tagihan', '/warga/invoices', AppColors.primary),
      _SvcItem('assets/images/coin.png', Icons.account_balance_rounded,
          'Keuangan RT', '/warga/reports', const Color(0xFFDB2777)),
      _SvcItem('assets/images/uang-bersayap.png', Icons.payment_rounded,
          'Riwayat Bayar', '/warga/payments', AppColors.accent),
      _SvcItem('assets/images/kalender.png', Icons.calendar_month_rounded,
          'Kegiatan', '/warga/events', AppColors.info),
      _SvcItem('assets/images/analisis-grafik-bar.png', Icons.bar_chart_rounded,
          'Laporan', '/warga/reports', AppColors.error),
    ];

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) =>
            _ServiceChipCard(item: items[i], index: i, highlighted: i == 0),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────

class _WargaHeader extends StatelessWidget {
  final Map<String, dynamic>? user;
  final bool loading;
  final Map<String, dynamic>? data;
  const _WargaHeader(
      {required this.user, required this.loading, required this.data});

  @override
  Widget build(BuildContext context) {
    final unpaid =
        int.tryParse(data?['stats']?['unpaid_count']?.toString() ?? '') ?? 0;
    final dark = context.isDarkMode;
    final photo = user?['profile_photo'] as String?;

    return Container(
      decoration: BoxDecoration(gradient: context.headerGradient),
      child: Stack(
        children: [
          // dekorasi lingkaran lembut
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(dark ? 0.04 : 0.12),
              ),
            ),
          ),
          Positioned(
            right: 50,
            bottom: -10,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(dark ? 0.03 : 0.09),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 50,
                      height: 50,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: photo != null
                            ? Image.network(photo,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
                                    'assets/images/avatar-profil.png',
                                    fit: BoxFit.cover))
                            : Image.asset('assets/images/avatar-profil.png',
                                fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.location_on_rounded,
                                size: 12, color: Colors.white70),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text('${user?['rt_rw'] ?? 'Warga RT'}',
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ]),
                          const SizedBox(height: 2),
                          Text('${user?['name'] ?? 'Warga'} ',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Consumer<NotificationProvider>(
                        builder: (ctx, notifProv, _) => GestureDetector(
                          onTap: () => ctx.go('/notifications'),
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              const Icon(Icons.notifications_outlined,
                                  color: Colors.white, size: 22),
                              if (notifProv.hasUnread)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF3B30),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 1.5),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]),
                  if (!loading && data != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(dark ? 0.08 : 0.92),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(children: [
                        Icon(Icons.home,
                            size: 18,
                            color: dark ? Colors.white60 : AppColors.textHint),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                              'Selamat datang ${user?['name'] ?? 'Warga'}!',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  color: dark
                                      ? Colors.white60
                                      : AppColors.textHint)),
                        ),
                        _Pill(
                          icon: Icons.warning_amber_rounded,
                          label: 'Belum Bayar',
                          value: '$unpaid',
                          color: unpaid > 0
                              ? AppColors.primaryDark
                              : AppColors.success,
                        ),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _Pill(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 13),
        const SizedBox(width: 5),
        Text(value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ]),
    );
  }
}

class _PaidThisYearCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PaidThisYearCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
      decoration: BoxDecoration(
        gradient: AppGradients.promo,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 18,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('✓ LUNAS TAHUN INI',
                    style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3)),
              ),
              const SizedBox(height: 12),
              const Text('Total Dibayar',
                  style: TextStyle(fontSize: 12.5, color: Colors.white70)),
              const SizedBox(height: 2),
              Text(
                CurrencyFormatter.format(data['stats']['paid_this_year']),
                style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => context.go('/warga/payments'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Lihat Riwayat',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 14, color: AppColors.primaryDark),
                  ]),
                ),
              ),
            ],
          ),
        ),
        Image.asset('assets/images/grafik-naik-dan-berjabat-tangan.png',
            width: 96, height: 96, fit: BoxFit.contain),
      ]),
    );
  }
}

class _UnpaidSection extends StatelessWidget {
  final Map<String, dynamic> data;
  const _UnpaidSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final rawUnpaid = (data['unpaid_invoices'] as List?) ?? [];
    if (rawUnpaid.isEmpty) return const SizedBox.shrink();

    // 🌟 URUTKAN DARI TERBARU DISIMPAN (ID Terbesar) DI PALING ATAS
    // Salin list terlebih dahulu agar tidak memodifikasi data cache secara tidak sengaja (unmodifiable list)
    final unpaid = List<dynamic>.from(rawUnpaid);
    unpaid.sort((a, b) {
      final idA = int.tryParse(a['id']?.toString() ?? '') ?? 0;
      final idB = int.tryParse(b['id']?.toString() ?? '') ?? 0;
      return idB.compareTo(idA);
    });

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeaderX(
          title: 'Tagihan Belum Dibayar',
          actionLabel: 'Semua',
          onAction: () => context.go('/warga/invoices')),
      const SizedBox(height: 10),
      ...unpaid.take(3).map((inv) => _InvoiceTile(inv: inv)),
      const SizedBox(height: 14),
    ]);
  }
}

class _InvoiceTile extends StatelessWidget {
  final Map<String, dynamic> inv;
  const _InvoiceTile({required this.inv});

  @override
  Widget build(BuildContext context) {
    // Default true kalau field belum ada di response (aman untuk data lama).
    final canPay = context.watch<AuthProvider>().user?['can_pay'] != false;

    return PopularStyleCard(
      imageAsset: 'assets/images/pembayaran-telat.png',
      title: '${inv['title']}',
      subtitle: inv['deadline'] != null ? 'Deadline: ${inv['deadline']}' : '-',
      badgeIcon: Icons.schedule_rounded,
      accentColor: AppColors.warning,
      trailingTop: CurrencyFormatter.format(inv['nominal']),
      // Kalau admin menonaktifkan tombol Bayar untuk warga ini, ganti
      // tombol "Bayar" dengan indikator terkunci alih-alih menyembunyikannya
      // begitu saja, supaya warga tahu ini disengaja bukan bug.
      trailingBottom: canPay
          ? GestureDetector(
              onTap: () => context.go('/warga/payments/submit/${inv['id']}'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppGradients.brand,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Bayar',
                    style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  size: 14, color: AppColors.warning),
            ),
    );
  }
}

class _SvcItem {
  final String image;
  final IconData icon;
  final String label;
  final String path;
  final Color color;
  const _SvcItem(this.image, this.icon, this.label, this.path, this.color);
}

class _ServiceChipCard extends StatefulWidget {
  final _SvcItem item;
  final int index;
  final bool highlighted;
  const _ServiceChipCard(
      {required this.item, required this.index, this.highlighted = false});

  @override
  State<_ServiceChipCard> createState() => _ServiceChipCardState();
}

class _ServiceChipCardState extends State<_ServiceChipCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _ctrl;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim = Tween<double>(begin: 16, end: 0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.item.color;
    final highlighted = widget.highlighted;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _slideAnim.value),
        child: Opacity(opacity: _ctrl.value, child: child),
      ),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          context.go(widget.item.path);
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 110),
          child: Container(
            width: 78,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              gradient: highlighted ? AppGradients.brand : null,
              color: highlighted ? null : context.colorSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color:
                      highlighted ? Colors.transparent : context.colorBorder),
              boxShadow: [
                BoxShadow(
                    color: highlighted
                        ? AppColors.primary.withOpacity(0.3)
                        : Colors.black
                            .withOpacity(context.isDarkMode ? 0.2 : 0.03),
                    blurRadius: highlighted ? 12 : 6,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: highlighted
                        ? Colors.white.withOpacity(0.25)
                        : c.withOpacity(context.isDarkMode ? 0.18 : 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Image.asset(widget.item.image, fit: BoxFit.contain),
                ),
                const SizedBox(height: 6),
                Text(widget.item.label,
                    style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: highlighted
                            ? Colors.white
                            : context.colorTextSecond),
                    textAlign: TextAlign.center,
                    maxLines: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Map<String, dynamic> e;
  const _EventCard({required this.e});

  @override
  Widget build(BuildContext context) {
    final colorHex = e['color'] as String? ?? '#3B82F6';
    Color color;
    try {
      color = Color(int.parse('0xFF${colorHex.replaceAll('#', '')}'));
    } catch (_) {
      color = AppColors.primary;
    }
    return PopularStyleCard(
      imageAsset: 'assets/images/kalender.png',
      title: '${e['title']}',
      subtitle: e['location'] != null ? '${e['location']}' : 'Kegiatan RT',
      badgeIcon: Icons.location_on_rounded,
      accentColor: color,
      trailingTop: e['start_date'] != null
          ? '${(e['start_date'] as String).substring(0, 10)}'
          : '-',
    );
  }
}
