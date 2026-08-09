import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_cache.dart'; // Ditambahkan untuk mendukung caching
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/common_widgets.dart';
import '../auth/auth_provider.dart';
import '../notifications/notification_provider.dart';

class DashboardAdminPage extends StatefulWidget {
  const DashboardAdminPage({super.key});
  @override
  State<DashboardAdminPage> createState() => _DashboardAdminPageState();
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

class _DashboardAdminPageState extends State<DashboardAdminPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
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
        AppCache.instance.get<Map<String, dynamic>>('admin_dashboard');
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
          .get('/admin/dashboard', params: forceRefresh ? {'fresh': 1} : null);
      if (res.data['success'] == true) {
        AppCache.instance.set('admin_dashboard', res.data['data']);
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
        child: CustomScrollView(
          slivers: [
            // ── Header gaya "food delivery" — gradasi hangat + foto profil asli ──
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
                    _AdminHeader(user: user, loading: _loading, data: _data),
              ),
            ),

            // ── Body ──────────────────────────────────────────────
            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: ShimmerList(count: 6),
                ),
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
                      SlideTransition(
                        position: _slideAnim,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Kartu Premium Kas Saldo (Gaya Banner Promo Warga) ──
                            _AdminTotalSaldoCard(data: _data!),
                            const SizedBox(height: 22),

                            // ── Menu Cepat (Gaya Chips Horizontal Scrolling) ──
                            _buildQuickMenu(context, isTablet),
                            const SizedBox(height: 22),

                            // ── Grid Statistik Pendukung (Menggunakan Ikon Premium Report) ──
                            _finCard(
                                'Pemasukan',
                                double.tryParse(_data!['stats']['total_income']
                                        .toString()) ??
                                    0,
                                AppColors.success,
                                'assets/images/profit-naik.png'), // Ikon baru disesuaikan dengan report
                            const SizedBox(height: 10),
                            _finCard(
                                'Pengeluaran',
                                double.tryParse(_data!['stats']['total_expense']
                                        .toString()) ??
                                    0,
                                AppColors.error,
                                'assets/images/budget.png'), // Ikon baru disesuaikan dengan report
                            const SizedBox(height: 22),

                            // ── Tren Keuangan Chart ──
                            _buildTrendChart(),
                            const SizedBox(height: 22),

                            // ── Pembayaran Terbaru ──
                            SectionHeaderX(
                              title: '💳 Pembayaran Terbaru',
                              actionLabel: 'Semua',
                              onAction: () => context.go('/admin/payments'),
                            ),
                            const SizedBox(height: 10),
                            ..._buildRecentPayments(),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Menu Cepat (Horizontal Chips Gaya Warga) ──────────────────
  Widget _buildQuickMenu(BuildContext context, bool isTablet) {
    final items = [
      _SvcItem('assets/images/orang-komunitas.png', Icons.people_alt_rounded,
          'Kelola Warga', '/admin/warga', AppColors.primary),
      _SvcItem(
          'assets/images/uang-bersayap.png',
          Icons.account_balance_wallet_rounded,
          'Pengeluaran',
          '/admin/expenses',
          const Color(0xFF7C3AED)),
      _SvcItem('assets/images/kalender.png', Icons.calendar_month_rounded,
          'Kegiatan', '/admin/events', const Color(0xFF0EA5E9)),
      _SvcItem('assets/images/kantong-uang.png', Icons.receipt_long_rounded,
          'Pembayaran', '/admin/payments', AppColors.accent),
      _SvcItem('assets/images/analisis-grafik-bar.png', Icons.bar_chart_rounded,
          'Laporan', '/admin/reports', AppColors.info),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeaderX(title: 'Menu Cepat'),
        const SizedBox(height: 12),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _ServiceChipCard(
              item: items[i],
              index: i,
              highlighted: i == 0,
            ),
          ),
        ),
      ],
    );
  }

  // Modifikasi desain kartu statistik keuangan agar bergaya premium seperti report_page
  Widget _finCard(String title, double value, Color color, String imageAsset) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colorSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.colorTextSecond,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.compact(value),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // Sisi Kanan: Kontainer berlatar warna transparan tipis membungkus gambar premium
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              imageAsset,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                title.contains('Pemasukan')
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: color,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    final trend = (_data!['trend_data'] as List?) ?? [];
    if (trend.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colorBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(context.isDarkMode ? 0.18 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tren Keuangan',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.colorTextPrimary)),
                Text('Pemasukan vs Pengeluaran',
                    style: TextStyle(
                        fontSize: 12, color: context.colorTextSecond)),
              ],
            ),
          ),
          Row(children: [
            _Legend(color: AppColors.success, label: 'Masuk'),
            const SizedBox(width: 12),
            _Legend(color: AppColors.error, label: 'Keluar'),
          ]),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 500000,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: context.colorBorder, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= trend.length) return const SizedBox();
                      final month = trend[i]['month'] as String;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(month.substring(0, 3),
                            style: TextStyle(
                                fontSize: 10, color: context.colorTextHint)),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 500000,
                    reservedSize: 44,
                    getTitlesWidget: (v, _) => Text(
                        CurrencyFormatter.compact(v),
                        style: TextStyle(
                            fontSize: 9, color: context.colorTextHint)),
                  ),
                ),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) =>
                      context.colorTextPrimary.withOpacity(0.85),
                  getTooltipItems: (spots) => spots.map((s) {
                    final label = s.barIndex == 0 ? 'Masuk' : 'Keluar';
                    return LineTooltipItem(
                      '$label\n${CurrencyFormatter.format(s.y)}',
                      const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: [
                _chartBar(trend, 'income', AppColors.success),
                _chartBar(trend, 'expense', AppColors.error),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  LineChartBarData _chartBar(List trend, String key, Color color) =>
      LineChartBarData(
        spots: List.generate(
          trend.length,
          (i) => FlSpot(
            i.toDouble(),
            double.tryParse(trend[i][key]?.toString() ?? '') ?? 0.0,
          ),
        ),
        isCurved: true,
        color: color,
        barWidth: 2.5,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
            radius: 3,
            color: color,
            strokeWidth: 1.5,
            strokeColor: Colors.white,
          ),
        ),
        belowBarData: BarAreaData(
          show: true,
          color: color.withOpacity(0.07),
        ),
      );

  List<Widget> _buildRecentPayments() {
    final payments = (_data!['recent_payments'] as List?) ?? [];
    if (payments.isEmpty) {
      return [
        const EmptyState(
            icon: Icons.receipt_long_rounded, title: 'Belum ada pembayaran')
      ];
    }
    return payments.take(5).map((p) => _PaymentTile(p: p)).toList();
  }
}

// ─────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────

class _AdminHeader extends StatelessWidget {
  final Map<String, dynamic>? user;
  final bool loading;
  final Map<String, dynamic>? data;
  const _AdminHeader(
      {required this.user, required this.loading, required this.data});

  @override
  Widget build(BuildContext context) {
    final totalWarga = data?['stats']?['total_warga'] ?? 0;
    final dark = context.isDarkMode;
    final photo = user?['profile_photo'] as String?;

    return Container(
      decoration: BoxDecoration(gradient: context.headerGradient),
      child: Stack(
        children: [
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
                          // SESUDAH (PERBAIKAN)
                          Row(children: [
                            const Icon(Icons.shield_rounded,
                                size: 12, color: Colors.white70),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text('Administrator RT',
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ]),
                          const SizedBox(height: 2),
                          const Text('Halo, Admin ARUSKAS RT',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Consumer<NotificationProvider>(
                      builder: (ctx, notifProv, _) => GestureDetector(
                        onTap: () => ctx.go('/notifications'),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(13),
                          ),
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
                        Icon(Icons.analytics_rounded,
                            size: 18,
                            color: dark ? Colors.white60 : AppColors.textHint),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Warga terdaftar: $totalWarga jiwa',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: dark
                                      ? Colors.white
                                      : AppColors.primaryDark)),
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

class _AdminTotalSaldoCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AdminTotalSaldoCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final saldoRaw =
        double.tryParse(data['stats']['saldo']?.toString() ?? '') ?? 0.0;
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
                child: const Text('💰 TOTAL KAS RT',
                    style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3)),
              ),
              const SizedBox(height: 12),
              const Text('Saldo Kas Saat Ini',
                  style: TextStyle(fontSize: 12.5, color: Colors.white70)),
              const SizedBox(height: 2),
              Text(
                CurrencyFormatter.format(saldoRaw),
                style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => context.go('/admin/reports'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Lihat Laporan Buku',
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

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 12,
            height: 3,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(fontSize: 11, color: context.colorTextSecond)),
      ]);
}

class _PaymentTile extends StatelessWidget {
  final Map<String, dynamic> p;
  const _PaymentTile({required this.p});

  @override
  Widget build(BuildContext context) {
    return PopularStyleCard(
      imageAsset: 'assets/images/kantong-uang.png',
      title: '${p['user'] ?? '-'}',
      subtitle: '${p['invoice'] ?? '-'} · ${p['rt_rw'] ?? '-'}',
      trailingTop: CurrencyFormatter.format(
          double.tryParse(p['amount']?.toString() ?? '') ?? 0.0),
      trailingBottom: StatusBadge(p['status'] ?? 'unpaid'),
      accentColor: AppColors.primary,
    );
  }
}
