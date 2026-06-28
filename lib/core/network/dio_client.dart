import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../config/app_constants.dart';
import 'secure_storage_service.dart';

/// Membangun instance [Dio] yang sudah dikonfigurasi untuk Supabase:
/// menyisipkan header `apikey` + `Authorization: Bearer`, serta menangani
/// refresh token otomatis saat menerima 401.
class DioClient {
  final SecureStorageService _storage;

  DioClient(this._storage);

  /// Dio untuk Edge Functions (`<supabaseUrl>/functions/v1`).
  Dio build() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.functionsBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'apikey': AppConfig.supabaseAnonKey},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Coba refresh sekali saat 401 (token kedaluwarsa).
          if (error.response?.statusCode == 401 &&
              !_isRetry(error.requestOptions)) {
            final refreshed = await _tryRefreshToken();
            if (refreshed) {
              final cloned = await _retry(dio, error.requestOptions);
              return handler.resolve(cloned);
            }
          }
          handler.next(error);
        },
      ),
    );

    return dio;
  }

  bool _isRetry(RequestOptions options) =>
      options.extra['__is_retry'] == true;

  /// Memanggil endpoint refresh token Supabase Auth dan menyimpan token baru.
  Future<bool> _tryRefreshToken() async {
    final refreshToken = await _storage.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      // Auth pakai base URL terpisah (GoTrue), bukan functions.
      final authDio = Dio(
        BaseOptions(
          baseUrl: AppConfig.authBaseUrl,
          headers: {'apikey': AppConfig.supabaseAnonKey},
        ),
      );
      final res = await authDio.post(
        AppConstants.epAuthToken,
        queryParameters: {'grant_type': 'refresh_token'},
        data: {'refresh_token': refreshToken},
      );

      final data = res.data as Map<String, dynamic>;
      final newAccess = data['access_token'] as String?;
      final newRefresh = data['refresh_token'] as String?;
      if (newAccess == null || newRefresh == null) return false;

      await _storage.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Mengulang request asli dengan token yang sudah diperbarui.
  Future<Response<dynamic>> _retry(Dio dio, RequestOptions req) {
    final options = Options(
      method: req.method,
      headers: req.headers,
      extra: {...req.extra, '__is_retry': true},
    );
    return dio.request(
      req.path,
      data: req.data,
      queryParameters: req.queryParameters,
      options: options,
    );
  }
}
