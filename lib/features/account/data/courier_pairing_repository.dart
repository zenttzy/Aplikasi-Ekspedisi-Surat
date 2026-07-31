import 'package:dio/dio.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/network/dio_client.dart';

class CourierPairingResult {
  final String tuName;
  final String? tuEmail;
  final String divisionName;
  final String? divisionCode;

  const CourierPairingResult({
    required this.tuName,
    required this.divisionName,
    this.tuEmail,
    this.divisionCode,
  });

  factory CourierPairingResult.fromJson(Map<String, dynamic> json) {
    final tu = json['tu'] as Map<String, dynamic>?;
    if (tu == null) {
      throw const FormatException('Data Tata Usaha tidak ditemukan.');
    }

    return CourierPairingResult(
      tuName: tu['nama_lengkap']?.toString() ?? 'Tata Usaha',
      tuEmail: tu['email']?.toString(),
      divisionName: tu['divisi_nama']?.toString() ?? 'Divisi belum tersedia',
      divisionCode: tu['divisi_kode']?.toString(),
    );
  }
}

class CourierPairingException implements Exception {
  final String message;

  const CourierPairingException(this.message);

  @override
  String toString() => message;
}

class CourierPairingRepository {
  final Dio _dio;

  CourierPairingRepository(DioClient dioClient) : _dio = dioClient.build();

  Future<CourierPairingResult> claimQrPayload(String rawValue) async {
    final token = _extractToken(rawValue);
    if (token == null) {
      throw const CourierPairingException(
        'QR tidak dikenali. Pastikan QR dibuat dari menu Hubungkan Kurir pada website.',
      );
    }

    try {
      final response = await _dio.post(
        AppConstants.epPairingClaim,
        data: {'token': token},
      );
      return CourierPairingResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      final responseData = error.response?.data;
      final message = responseData is Map
          ? responseData['error']?.toString()
          : null;
      throw CourierPairingException(
        message ?? 'Gagal menghubungkan kurir. Periksa internet lalu coba lagi.',
      );
    } on FormatException catch (error) {
      throw CourierPairingException(error.message);
    }
  }

  String? _extractToken(String rawValue) {
    final uri = Uri.tryParse(rawValue.trim());
    if (uri == null ||
        uri.scheme != 'ekspedisi-surat' ||
        uri.host != 'pair') {
      return null;
    }

    final token = uri.queryParameters['token']?.trim();
    if (token == null || token.length < 20) return null;
    return token;
  }
}
