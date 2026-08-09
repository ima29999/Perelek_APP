import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class NotificationItem {
  final int id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? meta;
  final bool isAnnouncement; // true = berasal dari announcements table

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.meta,
    this.isAnnouncement = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? json['message'] ?? '',
      type: json['type'] ?? 'system',
      isRead: json['is_read'] == true || json['read_at'] != null,
      createdAt:
          DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      meta: json['data'] as Map<String, dynamic>?,
    );
  }

  factory NotificationItem.fromAnnouncement(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      body: json['content'] ?? '',
      type: 'announcement',
      isRead: true, // pengumuman tidak punya status baca individual
      createdAt:
          DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      meta: {
        'category': json['category'],
        'nominal': json['nominal'],
        'deadline': json['deadline'],
        'is_pinned': json['is_pinned'],
      },
      isAnnouncement: true,
    );
  }

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id,
        title: title,
        body: body,
        type: type,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        meta: meta,
        isAnnouncement: isAnnouncement,
      );
}

class NotificationProvider extends ChangeNotifier {
  List<NotificationItem> _items = [];
  bool _loading = false;
  int _unreadCount = 0;
  DateTime? _lastLoadedAt;

  List<NotificationItem> get items => _items;
  bool get loading => _loading;
  int get unreadCount => _unreadCount;
  bool get hasUnread => _unreadCount > 0;

  Future<void> load({bool force = false}) async {
    // Halaman dashboard admin & warga memanggil load() ini setiap kali
    // dibuka (untuk badge notifikasi), padahal sebelumnya sebenarnya
    // tidak perlu request baru kalau baru saja dimuat beberapa detik lalu.
    // Guard ini menghindari request /notifications + /announcements
    // berulang setiap kali user gonta-ganti tab dashboard dalam waktu
    // singkat. notifications_page.dart tetap memanggil load(force: true)
    // supaya selalu dapat data terbaru saat benar-benar dibuka.
    if (!force &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < const Duration(seconds: 30)) {
      return;
    }

    _loading = true;
    notifyListeners();

    // Sebelumnya 2 request ini dijalankan berurutan (request kedua baru
    // mulai setelah request pertama selesai) — sekarang dijalankan
    // bersamaan dengan Future.wait, total waktu tunggu jadi ~separuhnya
    // (dibatasi oleh request yang paling lambat, bukan jumlah keduanya).
    final results = await Future.wait([
      _fetchSystemNotifications(),
      _fetchAnnouncements(),
    ]);

    final merged = <NotificationItem>[...results[0]];
    final announcements = results[1];
    final existingIds =
        merged.where((n) => n.type == 'announcement').map((n) => n.id).toSet();
    for (final a in announcements) {
      if (!existingIds.contains(a.id)) merged.add(a);
    }

    // Sort: pinned announcement dulu, lalu berdasarkan tanggal terbaru
    merged.sort((a, b) {
      final aPin = a.meta?['is_pinned'] == true ? 0 : 1;
      final bPin = b.meta?['is_pinned'] == true ? 0 : 1;
      if (aPin != bPin) return aPin.compareTo(bPin);
      return b.createdAt.compareTo(a.createdAt);
    });

    _items = merged;
    _unreadCount =
        _items.where((n) => !n.isRead && !n.isAnnouncement).length;
    _loading = false;
    _lastLoadedAt = DateTime.now();
    notifyListeners();
  }

  Future<List<NotificationItem>> _fetchSystemNotifications() async {
    try {
      final res = await ApiClient().get('/notifications');
      if (res.data['success'] == true) {
        final list = (res.data['data'] as List?) ?? [];
        return list.map((j) => NotificationItem.fromJson(j)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<NotificationItem>> _fetchAnnouncements() async {
    try {
      final res = await ApiClient().get('/announcements');
      if (res.data['success'] == true) {
        final raw = res.data['data'];
        final list = (raw is Map ? raw['data'] : raw) as List? ?? [];
        return list.map((j) => NotificationItem.fromAnnouncement(j)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> markRead(int id) async {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    if (_items[idx].isAnnouncement) return; // pengumuman tidak punya read API

    try {
      await ApiClient().patch('/notifications/$id/read');
    } catch (_) {}

    _items[idx] = _items[idx].copyWith(isRead: true);
    _unreadCount = _items.where((n) => !n.isRead && !n.isAnnouncement).length;
    notifyListeners();
  }

  Future<void> markAllRead() async {
    try {
      await ApiClient().patch('/notifications/read-all');
    } catch (_) {}
    _items = _items.map((n) {
      if (n.isAnnouncement) return n;
      return n.copyWith(isRead: true);
    }).toList();
    _unreadCount = 0;
    notifyListeners();
  }
}
