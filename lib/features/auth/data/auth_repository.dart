import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/network/secure_storage_service.dart';

/// Hasil login: sukses menyimpan token, atau membawa pesan error.
class AuthResult {
  final bool success;
  final String? error;

  const AuthResult.ok()
      : success = true,
        error = null;
  const AuthResult.fail(this.error) : success = false;
}

/// Repository autentikasi via Supabase Auth (GoTrue).
///
/// Login email+password (format email: `kodedivisi_namauser@timah.com`),
/// token JWT disimpan aman lewat [SecureStorageService].
class AuthRepository {
  final SecureStorageService _storage;
  final Dio _authDio;

  AuthRepository(this._storage, {Dio? authDio})
      : _authDio = authDio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.authBaseUrl,
                headers: {'apikey': AppConfig.supabaseAnonKey},
              ),
            );

  /// Login: `POST /auth/v1/token?grant_type=password`.
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _authDio.post(
        AppConstants.epAuthToken,
        queryParameters: {'grant_type': 'password'},
        data: {'email': email, 'password': password},
      );

      final data = res.data as Map<String, dynamic>;
      final accessToken = data['access_token'] as String?;
      final refreshToken = data['refresh_token'] as String?;
      if (accessToken == null || refreshToken == null) {
        return const AuthResult.fail('Respons login tidak valid');
      }

      await _storage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      return const AuthResult.ok();
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['error_description'] ??
              e.response?.data['msg'] ??
              e.message)
          : e.message;
      return AuthResult.fail(msg?.toString() ?? 'Gagal login');
    }
  }

  Future<bool> get isLoggedIn => _storage.hasSession;

  Future<void> logout() => _storage.clear();
}
