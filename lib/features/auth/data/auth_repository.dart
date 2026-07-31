import 'package:dio/dio.dart';
import '../../../core/notifications/notification_service.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/network/secure_storage_service.dart';

class AuthResult {
  final bool success;
  final String? error;
  const AuthResult.ok() : success = true, error = null;
  const AuthResult.fail(this.error) : success = false;
}

class AuthRepository {
  final SecureStorageService _storage;
  late final Dio _dio;

  AuthRepository(this._storage) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      headers: {'Content-Type': 'application/json'},
    ));
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        AppConstants.epLogin,
        data: {'email': email, 'password': password},
      );
      final data = res.data as Map<String, dynamic>;
      final token = data['token'] as String?;
      if (token == null) {
        return const AuthResult.fail(
          'Login belum dapat diproses. Silakan coba lagi beberapa saat.',
        );
      }
      await _storage.saveTokens(accessToken: token, refreshToken: '');
      final user = data['user'] as Map<String, dynamic>?;
      if (user != null) {
        await _storage.saveUserData(user);
      }
      // Register FCM device token for push notifications
      _registerFcmToken(token);
      return const AuthResult.ok();
    } on DioException catch (e) {
      return AuthResult.fail(_loginErrorMessage(e));
    }
  }

  Future<AuthResult> register({
    required String email,
    required String password,
    required String namaLengkap,
  }) async {
    try {
      await _dio.post(
        AppConstants.epRegister,
        data: {'email': email, 'password': password, 'nama_lengkap': namaLengkap},
      );
      return const AuthResult.ok();
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['error'] ?? e.message)
          : e.message;
      return AuthResult.fail(msg?.toString() ?? 'Gagal registrasi');
    }
  }

  Future<String?> getAccessToken() => _storage.accessToken;

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final cached = await _storage.getUserData();
    try {
      final token = await _storage.accessToken;
      if (token != null) {
        final res = await _dio.get(
          AppConstants.epMe,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        final data = res.data as Map<String, dynamic>;
        final user = data['user'] as Map<String, dynamic>?;
        if (user != null) {
          await _storage.saveUserData(user);
          return user;
        }
      }
    } catch (_) {}
    return cached;
  }

  Future<String?> checkAccountStatus(String token) async {
    try {
      final res = await _dio.get(
        AppConstants.epMe,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = res.data as Map<String, dynamic>;
      return data['status'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<bool> get isLoggedIn => _storage.hasSession;

  Future<void> logout() async {
    await _storage.clearAll();
  }

  Future<void> _registerFcmToken(String authToken) async {
    try {
      final fcmToken = await NotificationService().getToken();
      if (fcmToken == null) return;
      await _dio.post(
        '/users/device-token',
        data: {'token': fcmToken, 'platform': 'android'},
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );
    } catch (_) {}
  }

  String _loginErrorMessage(DioException exception) {
    final statusCode = exception.response?.statusCode;
    final serverMessage = exception.response?.data is Map
        ? exception.response?.data['error']?.toString().toLowerCase()
        : null;

    if (statusCode == 401 || serverMessage?.contains('invalid credential') == true) {
      return 'Email atau kata sandi tidak sesuai. Periksa kembali lalu coba lagi.';
    }
    if (statusCode == 403) {
      return 'Akun Anda belum dapat digunakan. Hubungi admin untuk memastikan akun sudah disetujui.';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'Layanan sedang mengalami kendala. Silakan coba lagi beberapa saat.';
    }
    if (exception.type == DioExceptionType.connectionTimeout ||
        exception.type == DioExceptionType.sendTimeout ||
        exception.type == DioExceptionType.receiveTimeout ||
        exception.type == DioExceptionType.connectionError) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda lalu coba lagi.';
    }
    return 'Login belum berhasil. Silakan periksa koneksi Anda dan coba lagi.';
  }
}
