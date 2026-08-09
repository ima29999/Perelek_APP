import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

/// Halaman WebView yang menampilkan halaman pembayaran Snap Midtrans
/// (kartu, Virtual Account, QRIS, e-wallet semua tersedia dalam 1 popup).
///
/// Ketika transaksi selesai (sukses/gagal/dibatalkan), Midtrans akan
/// mengarahkan WebView ke `finish_url` yang kita set di backend
/// (lihat config/services.php -> 'midtrans' -> 'finish_url').
/// Kita "menangkap" navigasi ke URL itu sebelum benar-benar dimuat,
/// lalu menutup halaman ini dan mengembalikan nilai boolean ke pemanggil.
class MidtransWebviewPage extends StatefulWidget {
  final String redirectUrl;
  const MidtransWebviewPage({super.key, required this.redirectUrl});

  @override
  State<MidtransWebviewPage> createState() => _MidtransWebviewPageState();
}

class _MidtransWebviewPageState extends State<MidtransWebviewPage> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onNavigationRequest: (request) {
            final url = request.url;

            // 1. Jika user membatalkan pembayaran di tengah jalan (klik back/cancel di Snap)
            if (url.contains('payment/unfinish') ||
                url.contains('payment/error')) {
              Navigator.of(context)
                  .pop(false); // Kembalikan false karena batal/gagal
              return NavigationDecision.prevent;
            }

            // 2. Jika diarahkan ke finish_url (Misal: localhost:8000/payment/finish?...)
            if (url.contains(AppConstants.midtransFinishUrlMarker)) {
              // Cek parameter dari Midtrans. Jika berisi status_code=201, artinya pending
              // alias user mengklik tombol silang (X) "Kembali ke aplikasi" sebelum bayar.
              if (url.contains('status_code=201')) {
                Navigator.of(context)
                    .pop(false); // Dianggap gagal/batal karena belum bayar
              } else {
                Navigator.of(context).pop(true); // Sukses (status_code=200)
              }
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pembayaran Online'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Tutup',
          // Jika user menutup paksa lewat tombol AppBar, anggap batal (false)
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}
