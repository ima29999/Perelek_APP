import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mengatur & menyimpan preferensi tampilan pengguna: Daylight (terang)
/// atau Midnight (gelap). Tersedia di seluruh aplikasi lewat Provider.
class ThemeProvider extends ChangeNotifier {
  static const _prefsKey = 'app_appearance_mode';

  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  ThemeProvider() {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved == 'dark') {
        _mode = ThemeMode.dark;
        notifyListeners();
      }
    } catch (_) {
      // Biarkan default Daylight jika gagal membaca preferensi
    }
  }

  Future<void> setDark(bool dark) async {
    if (_mode == (dark ? ThemeMode.dark : ThemeMode.light)) return;
    _mode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, dark ? 'dark' : 'light');
    } catch (_) {}
  }

  Future<void> toggle() => setDark(!isDark);
}
