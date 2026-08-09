import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final _storage = const FlutterSecureStorage();
  late final Dio _dio;

  Dio get dio => _dio;

  Future<void> init() async {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        return handler.next(e);
      },
    ));

    // Logging body request/response penuh HANYA aktif saat debug (dijalankan
    // dari `flutter run`). Sebelumnya interceptor ini selalu aktif, termasuk
    // di build release yang di-install user — menambah overhead I/O pada
    // SETIAP request dan berpotensi membocorkan data sensitif ke log device.
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }
  }

  // Shortcuts
  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  Future<Response> upload(String path, FormData formData,
          {void Function(int, int)? onSendProgress}) =>
      _dio.post(path,
          data: formData,
          options: Options(contentType: 'multipart/form-data'),
          onSendProgress: onSendProgress);

  Future<String?> getToken() => _storage.read(key: AppConstants.tokenKey);
  Future<void> setToken(String token) =>
      _storage.write(key: AppConstants.tokenKey, value: token);
  Future<void> clearToken() => _storage.delete(key: AppConstants.tokenKey);
}

// Ignore for web compat
void debugPrint(String msg) {
  // ignore: avoid_print
  print(msg);
}
