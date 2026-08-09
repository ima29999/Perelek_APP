import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_constants.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _loading = false;
  String? _error;

  Map<String, dynamic>? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?['role'] == AppConstants.roleAdmin;

  final _api = ApiClient();

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(AppConstants.userKey);
    final token = await _api.getToken();
    if (userData != null && token != null) {
      _user = jsonDecode(userData);
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.post('/auth/login',
          data: {'email': email, 'password': password});
      final data = res.data;

      if (data['success'] == true) {
        final token = data['data']['token'] as String;
        final user  = data['data']['user'] as Map<String, dynamic>;

        await _api.setToken(token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.userKey, jsonEncode(user));

        _user = user;
        _loading = false;
        notifyListeners();
        return true;
      }

      _error = data['message'] ?? 'Login gagal.';
    } catch (e) {
      _error = _parseError(e);
    }

    _loading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {}
    await _api.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userKey);
    _user = null;
    notifyListeners();
  }

  Future<void> refreshMe() async {
    try {
      final res = await _api.get('/auth/me');
      if (res.data['success'] == true) {
        _user = res.data['data'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.userKey, jsonEncode(_user));
        notifyListeners();
      }
    } catch (_) {}
  }

  String _parseError(dynamic e) {
    try {
      final data = (e as dynamic).response?.data;
      return data?['message'] ?? 'Terjadi kesalahan. Periksa koneksi Anda.';
    } catch (_) {
      return 'Terjadi kesalahan. Periksa koneksi Anda.';
    }
  }
}
