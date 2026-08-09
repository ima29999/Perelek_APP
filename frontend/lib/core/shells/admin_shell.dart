import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../theme/app_theme.dart';
import '../../features/ai_chat/ai_chat_page.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  static const _tabs = [
    _TabItem(
        icon: Icons.dashboard_rounded,
        label: 'Dashboard',
        path: '/admin/dashboard'),
    _TabItem(
        icon: Icons.people_alt_rounded, label: 'Warga', path: '/admin/warga'),
    _TabItem(
        icon: Icons.receipt_long_rounded,
        label: 'Tagihan',
        path: '/admin/invoices'),
    _TabItem(
        icon: Icons.bar_chart_rounded,
        label: 'Laporan',
        path: '/admin/reports'),
    _TabItem(
        icon: Icons.person_rounded, label: 'Profil', path: '/admin/profile'),
  ];

  int _selectedIndex(String location) {
    if (location.startsWith('/admin/warga')) return 1;
    if (location.startsWith('/admin/invoices')) return 2;
    if (location.startsWith('/admin/payments')) return 2;
    if (location.startsWith('/admin/reports')) return 3;
    if (location.startsWith('/admin/events')) return 3;
    if (location.startsWith('/admin/expenses')) return 3;
    if (location.startsWith('/admin/faq')) return 3;
    if (location.startsWith('/admin/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _selectedIndex(location);

    return Scaffold(
      // extendBody diaktifkan agar konten memanjang ke bawah lekukan bar secara smooth
      extendBody: true,
      body: child,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        // Padding disesuaikan menjadi 76 agar FAB mengambang pas di atas lengkungan bar
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
            .transparent, // Transparan agar sisi luar lengkungan menyatu dengan konten belakang
        color: AppColors.surface, // Warna background bar utama
        buttonBackgroundColor:
            AppColors.primary, // Warna lingkaran aktif yang melompat naik
        animationDuration: const Duration(milliseconds: 300),
        animationCurve: Curves.easeInOut,
        items: _tabs.map((tab) {
          final isSelected = _tabs.indexOf(tab) == idx;
          return Icon(
            tab.icon,
            size: 26,
            color: isSelected ? Colors.white : AppColors.textHint,
          );
        }).toList(),
        onTap: (index) {
          // Navigasi dialihkan ke path utama menu tab yang bersangkutan
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
