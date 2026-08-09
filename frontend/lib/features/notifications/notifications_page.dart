import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import 'notification_provider.dart';
import '../auth/auth_provider.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().load(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final items = provider.items;

    return Scaffold(
      backgroundColor: context.colorBg,
      body: CustomScrollView(slivers: [
        // ── Header ──
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.fromLTRB(
                4, MediaQuery.of(context).padding.top + 12, 16, 16),
            decoration: BoxDecoration(
              gradient: context.headerGradient,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    final auth = context.read<AuthProvider>();
                    context.go(
                        auth.isAdmin ? '/admin/dashboard' : '/warga/dashboard');
                  }
                },
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pemberitahuan',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      if (provider.hasUnread)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text('${provider.unreadCount} belum dibaca',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.8))),
                        ),
                    ]),
              ),
              if (provider.hasUnread)
                TextButton(
                  onPressed: provider.markAllRead,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withOpacity(0.18),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Tandai Semua',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ),
            ]),
          ),
        ),

        // ── Loading ──
        if (provider.loading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),

        // ── Empty ──
        if (!provider.loading && items.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: context.colorSurfaceAlt,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(Icons.notifications_none_rounded,
                        size: 40, color: context.colorTextHint),
                  ),
                  const SizedBox(height: 16),
                  Text('Belum ada pemberitahuan',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.colorTextPrimary)),
                  const SizedBox(height: 8),
                  Text('Notifikasi akan muncul di sini.',
                      style: TextStyle(
                          fontSize: 13, color: context.colorTextSecond),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),

        // ── List ──
        if (!provider.loading && items.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Semua Notifikasi',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.colorTextSecond)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _NotifTile(
                  item: items[i],
                  onTap: () => provider.markRead(items[i].id),
                ),
                childCount: items.length,
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;
  const _NotifTile({required this.item, required this.onTap});

  IconData _icon() {
    switch (item.type) {
      case 'payment':
        return Icons.payments_rounded;
      case 'invoice':
        return Icons.receipt_long_rounded;
      case 'event':
        return Icons.event_rounded;
      case 'report':
        return Icons.flag_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _color() {
    switch (item.type) {
      case 'payment':
        return AppColors.success;
      case 'invoice':
        return AppColors.primary;

      case 'event':
        return AppColors.info;
      case 'report':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  String _assetImage() {
    switch (item.type) {
      case 'payment':
        return 'assets/images/uang-bersayap.png';
      case 'invoice':
        return 'assets/images/kantong-uang.png';

      case 'event':
        return 'assets/images/kalender.png';
      case 'report':
        return 'assets/images/laporan.png';
      default:
        return 'assets/images/robot-cerdas.png';
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  /// Format ISO 8601 'reported_at' menjadi dd/MM/yyyy HH:mm,
  /// dengan fallback null jika data tidak valid.
  String? _formatReportedAt(String? iso) {
    if (iso == null) return null;
    final dt = DateTime.tryParse(iso);
    if (dt == null) return null;
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final isPinned = item.meta?['is_pinned'] == true;
    final nominal =
        double.tryParse(item.meta?['nominal']?.toString() ?? '') ?? 0.0;

    // Pembersihan string ISO Date format dari Backend
    final rawDeadline = item.meta?['deadline'] as String?;
    String? deadline = rawDeadline;
    if (rawDeadline != null && rawDeadline.contains('T')) {
      deadline = rawDeadline.split('T').first;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: item.isRead
              ? context.colorSurface
              : color.withOpacity(context.isDarkMode ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPinned
                ? AppColors.warning.withOpacity(0.4)
                : item.isRead
                    ? context.colorBorder
                    : color.withOpacity(0.3),
            width: (isPinned || !item.isRead) ? 1.5 : 1,
          ),
          boxShadow: item.isRead && !isPinned
              ? []
              : [
                  BoxShadow(
                      color: color.withOpacity(0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Image icon
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(context.isDarkMode ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Image.asset(_assetImage(),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        Icon(_icon(), color: color, size: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        if (isPinned)
                          Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: Icon(Icons.push_pin_rounded,
                                size: 12, color: AppColors.warning),
                          ),
                        Expanded(
                          child: Text(item.title,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: item.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                  color: context.colorTextPrimary)),
                        ),
                        if (!item.isRead && !item.isAnnouncement)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle),
                          ),
                      ]),
                      const SizedBox(height: 4),
                      if (item.type == 'report' &&
                          item.meta?['report_title'] != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            '${item.meta?['report_title']}',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: context.colorTextPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Text(item.body,
                          style: TextStyle(
                              fontSize: 12,
                              color: context.colorTextSecond,
                              height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Text(_timeAgo(item.createdAt),
                          style: TextStyle(
                              fontSize: 11, color: context.colorTextHint)),
                    ]),
              ),
            ]),

            // Info pengirim laporan (khusus type == 'report')
            if (item.type == 'report') ...[
              const SizedBox(height: 10),
              Divider(height: 1, color: context.colorBorder),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.person_rounded,
                    size: 13, color: AppColors.warning),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${item.meta?['reporter_name'] ?? 'Warga'} • ${item.meta?['reporter_email'] ?? '-'}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.access_time_rounded,
                    size: 13, color: context.colorTextHint),
                const SizedBox(width: 4),
                Text(
                  _formatReportedAt(item.meta?['reported_at'] as String?) ??
                      _timeAgo(item.createdAt),
                  style: TextStyle(fontSize: 11, color: context.colorTextHint),
                ),
              ]),
            ],

            // Perbaikan layout Nominal & Deadline rapi seperti InvoicesPage
            if (nominal > 0 || deadline != null) ...[
              const SizedBox(height: 10),
              Divider(height: 1, color: context.colorBorder),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (deadline != null)
                    Row(
                      children: [
                        const Icon(Icons.event_rounded,
                            size: 14, color: AppColors.error),
                        const SizedBox(width: 4),
                        Text(
                          'Deadline: $deadline',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    )
                  else
                    const Spacer(),
                  if (nominal > 0)
                    Text(
                      CurrencyFormatter.format(nominal),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.colorTextPrimary,
                      ),
                    ),
                ],
              ),
            ],
          ]),
        ),
      ),
    );
  }
}
