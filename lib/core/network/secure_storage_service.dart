import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_constants.dart';

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
    await _storage.write(key: AppConstants.keyAccessToken, value: accessToken);
  }

  Future<String?> get accessToken =>
      _storage.read(key: AppConstants.keyAccessToken);

  Future<bool> get hasSession async => (await accessToken) != null;

  Future<void> saveUserData(Map<String, dynamic> user) async {
    await _storage.write(
        key: AppConstants.keyUserData, value: jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final raw = await _storage.read(key: AppConstants.keyUserData);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
