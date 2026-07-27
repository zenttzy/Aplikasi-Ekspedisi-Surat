import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'secure_storage_service.dart';

class DioClient {
  final SecureStorageService _storage;

  DioClient(this._storage);

  Dio build() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
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
          handler.next(error);
        },
      ),
    );

    return dio;
  }
}
