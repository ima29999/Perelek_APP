class AppConstants {
  // API
  static const String baseUrl = 'http://localhost:8000/api/';
  // Storage keys
  static const String tokenKey = 'user_token';
  static const String userKey = 'user_data';

  // Roles
  static const String roleAdmin = 'admin';
  static const String roleUser = 'user';

  // Payment methods
  static const List<Map<String, String>> paymentMethods = [
    {'value': 'transfer', 'label': 'Transfer Bank'},
    {'value': 'tunai', 'label': 'Tunai'},
    {'value': 'qris', 'label': 'QRIS'},
    {'value': 'other', 'label': 'Lainnya'},
  ];

  // Payment statuses
  // 'pending'    -> internal state sementara saat transaksi Midtrans belum final.
  //                 Di UI, status ini dipetakan ke 'Belum Bayar' dan tidak
  //                 diperlakukan sebagai fitur terpisah.
  // 'confirmated'-> sudah terkonfirmasi & masuk otomatis, baik dari webhook
  //                 Midtrans maupun submit pembayaran manual.
  static const Map<String, String> paymentStatusLabel = {
    'pending': 'Belum Bayar',
    'confirmated': 'Telah Dibayar',
    'rejected': 'Ditolak',
    'unpaid': 'Belum Bayar',
  };

  static const Map<String, String> paymentStatusColor = {
    'pending': 'orange',
    'confirmated': 'green',
    'rejected': 'red',
    'unpaid': 'grey',
  };

  // Midtrans payment gateway
  // Potongan URL yang dipakai untuk mendeteksi kapan transaksi Snap selesai
  // di dalam WebView. Harus sama dengan MIDTRANS_FINISH_URL di backend (.env).
  static const String midtransFinishUrlMarker = 'payment/finish';
}
