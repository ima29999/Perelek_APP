import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../theme/app_theme.dart';
import '../../features/ai_chat/ai_chat_page.dart';

class WargaShell extends StatelessWidget {
  final Widget child;
  const WargaShell({super.key, required this.child});

  static const _tabs = [
    _TabItem(
        icon: Icons.home_rounded, label: 'Beranda', path: '/warga/dashboard'),
    _TabItem(
        icon: Icons.receipt_rounded, label: 'Tagihan', path: '/warga/invoices'),
    _TabItem(
        icon: Icons.payment_rounded, label: 'Riwayat', path: '/warga/payments'),
    _TabItem(
        icon: Icons.calendar_month_rounded,
        label: 'Kegiatan',
        path: '/warga/events'),
    _TabItem(
        icon: Icons.person_rounded, label: 'Profil', path: '/warga/profile'),
  ];

  int _selectedIndex(String location) {
    for (int i = _tabs.length - 1; i >= 0; i--) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _selectedIndex(location);

    return Scaffold(
      // extendBody memastikan konten meluas ke bawah lengkungan bar agar transisinya halus
      extendBody: true,
      body: child,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        // Menyesuaikan padding FAB agar tidak bertumpukan terlalu dekat dengan bar lengkung
        padding: const EdgeInsets.only(bottom: 76),
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          tooltip: 'Tanya Asisten AI',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AiChatPage()),
          ),
          child: const Icon(Icons.auto_awesome_outlined, color: Colors.white),
        ),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: idx,
        height: 60,
        backgroundColor: Colors
            .transparent, // Transparan agar tidak menutupi konten di belakangnya
        color: AppColors.surface, // Warna utama latar bar
        buttonBackgroundColor: AppColors
            .primary, // Warna lingkaran tombol aktif yang melompat naik
        animationDuration: const Duration(milliseconds: 300),
        animationCurve: Curves.easeInOut,
        items: _tabs.map((tab) {
          final isSelected = _tabs.indexOf(tab) == idx;
          return Icon(
            tab.icon,
            size: 26,
            // Jika terpilih, ikon di dalam lingkaran berwarna putih. Jika tidak, warnanya redup.
            color: isSelected ? Colors.white : AppColors.textHint,
          );
        }).toList(),
        onTap: (index) {
          // Navigasi GoRouter dipicu saat tombol ditekan
          context.go(_tabs[index].path);
        },
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  final String path;
  const _TabItem({required this.icon, required this.label, required this.path});
}
