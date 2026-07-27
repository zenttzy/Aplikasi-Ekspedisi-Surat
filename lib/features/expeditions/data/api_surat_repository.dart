import 'dart:io';
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
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
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
    return list
        .map((json) =>
            Expedition.fromServerJson(json as Map<String, dynamic>))
        .toList();
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

  /// Upload bukti foto + GPS + nama penerima ke endpoint
  /// POST /api/surat/:uuid/bukti  (multipart)
  Future<bool> uploadBukti({
    required String uuid,
    required File foto,
    required double lat,
    required double lng,
    required String namaPenerima,
    String? fotoHash,
  }) async {
    final formData = FormData.fromMap({
      'foto': await MultipartFile.fromFile(
        foto.path,
        filename: 'bukti_$uuid.jpg',
      ),
      'lat': lat.toString(),
      'long': lng.toString(),
      'nama_penerima': namaPenerima,
      if (fotoHash != null) 'foto_hash': fotoHash,
    });

    await _dio.post(
      '${AppConstants.epSurat}/$uuid/bukti',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return true;
  }
}
