import 'package:dio/dio.dart';

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
      if (token == null) return const AuthResult.fail('Token tidak ditemukan');
      await _storage.saveTokens(accessToken: token, refreshToken: '');
      final user = data['user'] as Map<String, dynamic>?;
      if (user != null) {
        await _storage.saveUserData(user);
      }
      return const AuthResult.ok();
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['error'] ?? e.message)
          : e.message;
      return AuthResult.fail(msg?.toString() ?? 'Gagal login');
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

  Future<Map<String, dynamic>?> getCurrentUser() => _storage.getUserData();

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

  Future<void> logout() async {
    await _storage.clearAll();
  }
}
