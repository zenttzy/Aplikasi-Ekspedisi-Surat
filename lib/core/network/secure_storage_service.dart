import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_constants.dart';

/// Penyimpanan aman untuk token JWT (access & refresh) menggunakan
/// Keychain (iOS) / EncryptedSharedPreferences (Android).
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(
      key: AppConstants.keyAccessToken,
      value: accessToken,
    );
    await _storage.write(
      key: AppConstants.keyRefreshToken,
      value: refreshToken,
    );
  }

  Future<String?> get accessToken =>
      _storage.read(key: AppConstants.keyAccessToken);

  Future<String?> get refreshToken =>
      _storage.read(key: AppConstants.keyRefreshToken);

  Future<bool> get hasSession async => (await accessToken) != null;

  Future<void> clear() async {
    await _storage.delete(key: AppConstants.keyAccessToken);
    await _storage.delete(key: AppConstants.keyRefreshToken);
  }
}
