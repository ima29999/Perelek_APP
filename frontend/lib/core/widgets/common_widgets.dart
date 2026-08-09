import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  // Saat true (pembayaran online yang masih 'pending'), tampilkan label
  // "Menunggu Konfirmasi" alih-alih "Belum Bayar". Keduanya secara teknis
  // memakai status 'pending' yang sama, tapi artinya beda: yang ini berarti
  // warga SUDAH mencoba membayar dan sistem masih menunggu konfirmasi
  // otomatis dari Midtrans — bukan warga belum bayar sama sekali.
  final bool isProcessing;
  const StatusBadge(this.status, {super.key, this.isProcessing = false});

  static const _labels = {
    'pending': 'Belum Bayar',
    'confirmated': 'Telah Membayar',
    'rejected': 'Ditolak',
    'unpaid': 'Belum Bayar',
  };

  @override
  Widget build(BuildContext context) {
    Color bg, text;
    switch (status) {
      case 'confirmated':
        bg = AppColors.confirmatedBg;
        text = AppColors.confirmatedText;
        break;
      case 'rejected':
        bg = AppColors.rejectedBg;
        text = AppColors.rejectedText;
        break;
      case 'pending':
        bg = AppColors.unpaidBg;
        text = AppColors.unpaidText;
        break;
      default:
        bg = AppColors.unpaidBg;
        text = AppColors.unpaidText;
    }
    final label = isProcessing && status == 'pending'
        ? 'Menunggu Konfirmasi'
        : (_labels[status] ?? status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: text)),
    );
  }
}

class ShimmerCard extends StatelessWidget {
  final double height;
  const ShimmerCard({super.key, this.height = 90});

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkMode;
    return Shimmer.fromColors(
      baseColor: dark ? const Color(0xFF26282E) : const Color(0xFFE5E7EB),
      highlightColor: dark ? const Color(0xFF323540) : const Color(0xFFF3F4F6),
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
            color: context.colorSurface,
            borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class ShimmerList extends StatelessWidget {
  final int count;
  final double itemHeight;
  const ShimmerList({super.key, this.count = 5, this.itemHeight = 90});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (_, __) => ShimmerCard(height: itemHeight),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      this.subtitle,
      this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: context.colorSurfaceAlt,
                  borderRadius: BorderRadius.circular(24)),
              child: Icon(icon, size: 38, color: context.colorTextHint),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.colorTextPrimary),
                textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!,
                  style:
                      TextStyle(fontSize: 13, color: context.colorTextSecond),
                  textAlign: TextAlign.center)
            ],
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 56, color: context.colorTextHint),
            const SizedBox(height: 16),
            Text(message,
                style: TextStyle(fontSize: 14, color: context.colorTextSecond),
                textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Coba Lagi'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(160, 44))),
            ],
          ],
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isCurrency;
  const StatCard(
      {super.key,
      required this.label,
      required this.value,
      required this.icon,
      required this.color,
      this.isCurrency = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colorBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(context.isDarkMode ? 0.18 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: color.withOpacity(context.isDarkMode ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 22, color: color)),
          const SizedBox(height: 12),
          Text(
            isCurrency
                ? CurrencyFormatter.format(double.tryParse(value) ?? 0)
                : value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.colorTextPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(fontSize: 12, color: context.colorTextSecond)),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeader(
      {super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: Text(actionLabel!,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

class GradientSliverAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool pinned;
  const GradientSliverAppBar(
      {super.key,
      required this.title,
      this.subtitle,
      this.actions,
      this.pinned = true});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: subtitle != null ? 130 : 100,
      floating: false,
      pinned: pinned,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            if (subtitle != null)
              Text(subtitle!,
                  style: TextStyle(
                      fontSize: 11, color: Colors.white.withOpacity(0.8))),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
          ),
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const InfoRow(
      {super.key,
      required this.icon,
      required this.label,
      required this.value,
      this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: context.colorTextSecond),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12, color: context.colorTextSecond)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: valueColor ?? context.colorTextPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> showConfirmDialog(BuildContext context,
    {required String title,
    required String message,
    String confirmLabel = 'Ya',
    String cancelLabel = 'Batal',
    bool isDangerous = false}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogCtx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      content: Text(message,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecond)),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(cancelLabel,
                style: const TextStyle(color: AppColors.textSecond))),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogCtx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDangerous ? AppColors.error : AppColors.primary,
            minimumSize: const Size(80, 40),
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

// ─────────────────────────────────────────────────────────────
// Widget tambahan untuk desain baru bergaya "food delivery app":
// chip kategori berbentuk pil, kartu gaya "Popular Now", dan kartu
// pemilih mode tampilan (Daylight / Midnight). Semua sadar tema
// (otomatis menyesuaikan Daylight/Midnight lewat AppColorsX).
// ─────────────────────────────────────────────────────────────

/// Chip kategori bergaya pil dengan ikon (mis. ikon atau gambar aset),
/// terinspirasi filter "All / Burger / Sushi" pada aplikasi pesan-antar.
class CategoryPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const CategoryPill({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? AppGradients.brand : null,
          color: selected ? null : context.colorSurface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: selected ? Colors.transparent : context.colorBorder),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: AppColors.primary.withOpacity(0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 16,
              color: selected ? Colors.white : context.colorTextSecond),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : context.colorTextSecond)),
        ]),
      ),
    );
  }
}

/// Kartu bergaya "Popular Now": gambar bulat-kotak di kiri, judul +
/// keterangan di tengah, dan nilai/aksi di kanan. Dipakai ulang untuk
/// tagihan, riwayat bayar, dan daftar lain agar tampil seperti contoh.
class PopularStyleCard extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String subtitle;
  final String trailingTop;
  final Widget? trailingBottom;
  final Color accentColor;
  final VoidCallback? onTap;
  final IconData? badgeIcon;
  const PopularStyleCard({
    super.key,
    required this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.trailingTop,
    this.trailingBottom,
    this.accentColor = AppColors.primary,
    this.onTap,
    this.badgeIcon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.colorSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.colorBorder),
          boxShadow: [
            BoxShadow(
                color:
                    Colors.black.withOpacity(context.isDarkMode ? 0.18 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(context.isDarkMode ? 0.16 : 0.09),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Image.asset(imageAsset, fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: context.colorTextPrimary)),
                const SizedBox(height: 3),
                Row(children: [
                  if (badgeIcon != null) ...[
                    Icon(badgeIcon, size: 12, color: accentColor),
                    const SizedBox(width: 3),
                  ],
                  Expanded(
                    child: Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11.5, color: context.colorTextSecond)),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(trailingTop,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.colorTextPrimary)),
              if (trailingBottom != null) ...[
                const SizedBox(height: 6),
                trailingBottom!,
              ],
            ],
          ),
        ]),
      ),
    );
  }
}

/// Kartu pemilih mode tampilan Daylight / Midnight, sesuai contoh desain.
class AppearanceModeCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isDarkPreview;
  final bool selected;
  final VoidCallback onTap;
  const AppearanceModeCard({
    super.key,
    required this.label,
    required this.subtitle,
    required this.isDarkPreview,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final previewBg = isDarkPreview ? const Color(0xFF1B1C20) : Colors.white;
    final previewLine = isDarkPreview
        ? Colors.white.withOpacity(0.65)
        : const Color(0xFF1F1A17);
    final previewLine2 = isDarkPreview
        ? Colors.white.withOpacity(0.35)
        : const Color(0xFFAFA59C);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colorSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: selected ? AppColors.primary : context.colorBorder,
              width: selected ? 1.6 : 1),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: AppColors.primary.withOpacity(0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]
              : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: 64,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: previewBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDarkPreview
                      ? Colors.white.withOpacity(0.08)
                      : const Color(0xFFEDE3DB)),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  width: 34,
                  height: 5,
                  decoration: BoxDecoration(
                      color: previewLine,
                      borderRadius: BorderRadius.circular(3))),
              const SizedBox(height: 6),
              Container(
                  width: 22,
                  height: 4,
                  decoration: BoxDecoration(
                      color: previewLine2,
                      borderRadius: BorderRadius.circular(3))),
              const Spacer(),
              Row(children: [
                Container(
                    width: 20,
                    height: 9,
                    decoration: BoxDecoration(
                        gradient: AppGradients.brand,
                        borderRadius: BorderRadius.circular(6))),
              ]),
            ]),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Icon(
                isDarkPreview
                    ? Icons.dark_mode_rounded
                    : Icons.wb_sunny_rounded,
                size: 14,
                color: selected ? AppColors.primary : context.colorTextSecond),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.colorTextPrimary)),
            const Spacer(),
            Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 17,
                color: selected ? AppColors.primary : context.colorTextHint),
          ]),
          const SizedBox(height: 2),
          Text(subtitle,
              style: TextStyle(fontSize: 10.5, color: context.colorTextSecond)),
        ]),
      ),
    );
  }
}

/// Header bagian dengan judul + aksi opsional, sadar mode Daylight/Midnight.
class SectionHeaderX extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeaderX(
      {super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.colorTextPrimary)),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: Text(actionLabel!,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}
