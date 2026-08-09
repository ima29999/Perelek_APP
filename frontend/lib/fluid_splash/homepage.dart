import 'package:flutter/material.dart';
import 'fluid_card.dart';
import 'fluid_carousel.dart';

// NOTE: Agr apko ye onboarding screen use krni hain to ap nechy text ko change kr skty hain
class Showcase extends StatefulWidget {
  const Showcase({super.key, required this.title, this.onFinish});

  final String title;

  /// Dipanggil saat tombol "Mulai Sekarang" di halaman terakhir ditekan.
  /// Diisi dari luar (misalnya di router) supaya widget ini tetap
  /// reusable dan tidak perlu tahu soal navigasi/route.
  final VoidCallback? onFinish;

  @override
  State<Showcase> createState() => _ShowcaseState();
}

class _ShowcaseState extends State<Showcase> {
  // Index halaman yang sedang aktif (0 = halaman 1, dst).
  int _currentPage = 0;

  static const List<Map<String, dynamic>> _cards = [
    {
      'color': 'Red',
      'altColor': Color(0xFF4259B2),
      'title': "Kelola Warga RT\nLebih Mudah",
      'subtitle':
          "Satu aplikasi untuk manajemen data warga, tagihan, dan kegiatan lingkungan.",
    },
    {
      'color': 'Yellow',
      'altColor': Color(0xFF904E93),
      'title': "Hidup Bersih & Harmonis",
      'subtitle':
          "Informasi kegiatan warga, pengumuman RT, dan tanya-jawab lewat Asisten AI.",
    },
    {
      'color': 'Blue',
      'altColor': Color(0xFFFFB138),
      'title': "Transparansi Kas RT",
      'subtitle':
          "Pantau pemasukan, pengeluaran, dan laporan keuangan RT secara real-time.",
    },
  ];

  // Tombol "Mulai Sekarang" hanya muncul di halaman terakhir (halaman ke-3).
  bool get _isLastPage => _currentPage == _cards.length - 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          FluidCarousel(
            onIndexChanged: (index) {
              setState(() => _currentPage = index);
            },
            children: _cards
                .map((c) => FluidCard(
                      color: c['color'] as String,
                      altColor: c['altColor'] as Color,
                      title: c['title'] as String,
                      subtitle: c['subtitle'] as String,
                    ))
                .toList(),
          ),

          // Tombol "Mulai Sekarang" - selalu di-build, tapi disembunyikan
          // (opacity 0 + IgnorePointer) selama bukan di halaman terakhir,
          // supaya transisinya halus dan tidak bisa kepencet diam-diam.
          Positioned(
            left: 24,
            right: 24,
            bottom: 20,
            child: AnimatedOpacity(
              opacity: _isLastPage ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_isLastPage,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onFinish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Mulai Sekarang',
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
