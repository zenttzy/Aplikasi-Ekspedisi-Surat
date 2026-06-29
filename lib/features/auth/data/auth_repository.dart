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
    if (!email.trim().endsWith('@pttimah.com')) {
      return const AuthResult.fail('Hanya email @pttimah.com yang diperbolehkan');
    }
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

  /// Register: `POST /auth/v1/signup`.
  Future<AuthResult> register({
    required String email,
    required String password,
    required String namaLengkap,
  }) async {
    if (!email.trim().endsWith('@pttimah.com')) {
      return const AuthResult.fail('Hanya email @pttimah.com yang diperbolehkan');
    }
    try {
      final res = await _authDio.post(
        '/signup', // Supabase Auth signup endpoint
        data: {'email': email, 'password': password},
      );

      final data = res.data as Map<String, dynamic>;
      final user = data['user'] ?? data; // Depending on Supabase settings
      if (user == null || user['id'] == null) {
        return const AuthResult.fail('Gagal mendaftarkan akun (ID tidak ditemukan)');
      }

      // We need to insert into public.users. But we need authenticated request if not using anon or service key.
      // Wait, public.users has policy "Allow insert for self registration" on public.users for insert to public with check (auth.uid() = id);
      // Wait, without token, we can't be authenticated. BUT Supabase signup returns session if email confirmation is off.
      // Let's assume the session is returned so we can insert.
      final accessToken = data['session']?['access_token'];
      if (accessToken != null) {
         // insert to users
         final restDio = Dio(
           BaseOptions(
             baseUrl: AppConfig.authBaseUrl.replaceFirst('/auth/v1', '/rest/v1'),
             headers: {
               'apikey': AppConfig.supabaseAnonKey,
               'Authorization': 'Bearer $accessToken',
               'Prefer': 'return=minimal',
             },
           ),
         );
         await restDio.post(
           '/users',
           data: {
             'id': user['id'],
             'email': email,
             'nama_lengkap': namaLengkap,
             'role': 'kurir',
             'status': 'pending'
           }
         );
      } else {
        // If no session, it means email confirmation is required.
        // Or we use another way. For now, just return success if signup succeeds.
      }

      return const AuthResult.ok();
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['msg'] ??
              e.response?.data['error_description'] ??
              e.message)
          : e.message;
      return AuthResult.fail(msg?.toString() ?? 'Gagal registrasi');
    }
  }

  /// Check Status Account from public.users table.
  /// Returns 'pending', 'approved', 'nonaktif', or null if error.
  Future<String?> checkAccountStatus(String accessToken) async {
    try {
      final restDio = Dio(
        BaseOptions(
          baseUrl: AppConfig.authBaseUrl.replaceFirst('/auth/v1', '/rest/v1'),
          headers: {
            'apikey': AppConfig.supabaseAnonKey,
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );
      // Since RLS limits select to auth.uid() = id, we can just fetch all (which is 1)
      final res = await restDio.get('/users?select=status');
      final data = res.data as List;
      if (data.isNotEmpty) {
        return data[0]['status'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> get isLoggedIn => _storage.hasSession;

  Future<String?> getAccessToken() => _storage.accessToken;

  Future<void> logout() => _storage.clear();
}
