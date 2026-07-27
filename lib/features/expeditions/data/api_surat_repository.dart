import 'package:dio/dio.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/network/secure_storage_service.dart';
import '../../../core/config/app_config.dart';
import 'expedition_model.dart';

class ApiSuratRepository {
  final SecureStorageService _storage;
  late final Dio _dio;

  ApiSuratRepository(this._storage) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.accessToken;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  Future<List<Expedition>> fetchSurat() async {
    final res = await _dio.get(AppConstants.epSurat);
    final list = res.data as List<dynamic>;
    return list.map((json) => Expedition.fromServerJson(json as Map<String, dynamic>)).toList();
  }

  Future<bool> ambilSurat(String uuid) async {
    final userData = await _storage.getUserData();
    final kurirId = userData?['id'] as String?;
    if (kurirId == null) return false;
    await _dio.put('${AppConstants.epSurat}/$uuid', data: {
      'status': ExpeditionStatus.dikirim,
      'kurir_id': kurirId,
    });
    return true;
  }
}
