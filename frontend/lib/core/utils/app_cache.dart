/// Cache data in-memory sederhana untuk pola "stale-while-revalidate".
///
/// Masalah yang diperbaiki:
/// Sebelumnya SETIAP halaman (dashboard, tagihan, pembayaran, laporan, dst)
/// selalu menampilkan spinner loading dan menunggu response API setiap kali
/// halaman itu dibuka/dibangun ulang oleh Flutter — persis seperti membuka
/// halaman baru dari nol, walau datanya baru saja diambil beberapa detik
/// sebelumnya. Ini yang membuat aplikasi terasa lambat dibanding aplikasi
/// seperti Instagram/Shopee, yang langsung menampilkan data lama sambil
/// diam-diam memuat data terbaru di belakang layar.
///
/// Cara pakai di halaman (lihat contoh penerapan di dashboard_admin_page.dart,
/// dashboard_warga_page.dart, invoices_page.dart, dll):
///
/// ```dart
/// Future<void> _load({bool forceRefresh = false}) async {
///   final cached = AppCache.instance.get<Map<String, dynamic>>('admin_dashboard');
///   if (cached != null && !forceRefresh) {
///     setState(() { _data = cached; _loading = false; }); // tampil instan
///   }
///   if (cached == null) setState(() => _loading = true);
///
///   try {
///     final res = await ApiClient().get('/admin/dashboard');
///     if (res.data['success'] == true) {
///       AppCache.instance.set('admin_dashboard', res.data['data']);
///       if (mounted) setState(() { _data = res.data['data']; _loading = false; });
///     }
///   } catch (e) {
///     if (cached == null && mounted) setState(() => _loading = false);
///     // kalau sudah ada data cache yang tampil, gagal refresh diam-diam
///     // saja tidak perlu menampilkan error mengganggu.
///   }
/// }
/// ```
///
/// Cache ini sengaja disimpan di memori (bukan disk) — hilang saat app
/// benar-benar ditutup, tapi tetap ada selama app berjalan termasuk saat
/// berpindah-pindah tab/halaman. Ini aman karena tidak menyimpan apa pun
/// secara permanen (tidak menyentuh data sensitif di disk) dan cukup untuk
/// menghilangkan loading berulang saat navigasi normal di dalam sesi.
class AppCache {
  AppCache._();
  static final AppCache instance = AppCache._();

  final Map<String, _Entry> _store = {};

  /// Ambil data cache untuk [key]. Mengembalikan null kalau belum pernah
  /// di-set atau sudah lebih tua dari [maxAge] (default 5 menit — cukup
  /// longgar karena "kesegaran" sebenarnya sudah diatur di sisi backend
  /// lewat Cache::remember dengan TTL pendek; cache di sini murni untuk
  /// menghindari tampilan blank/spinner saat berpindah halaman).
  T? get<T>(String key, {Duration maxAge = const Duration(minutes: 5)}) {
    final entry = _store[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.savedAt) > maxAge) return null;
    return entry.value as T;
  }

  void set(String key, dynamic value) {
    _store[key] = _Entry(value, DateTime.now());
  }

  void invalidate(String key) => _store.remove(key);

  /// Hapus semua cache yang key-nya diawali [prefix]. Berguna misalnya
  /// setelah logout, atau setelah aksi yang mengubah banyak data sekaligus.
  void invalidateWhere(bool Function(String key) test) {
    _store.removeWhere((key, _) => test(key));
  }

  void clear() => _store.clear();
}

class _Entry {
  final dynamic value;
  final DateTime savedAt;
  _Entry(this.value, this.savedAt);
}
