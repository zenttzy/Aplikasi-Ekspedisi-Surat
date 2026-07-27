import 'dart:convert';
import 'package:dio/dio.dart';

import '../../core/config/app_constants.dart';
import '../../features/expeditions/data/expedition_model.dart';
import '../../features/expeditions/data/expedition_repository.dart';
import 'sync_prefs.dart';

/// Hasil satu siklus sinkronisasi (untuk ditampilkan/di-log di UI).
class SyncResult {
  final int downloaded;
  final int uploaded;
  final int failed;
  final String? error;

  const SyncResult({
    this.downloaded = 0,
    this.uploaded = 0,
    this.failed = 0,
    this.error,
  });

  bool get isSuccess => error == null;
}

/// Mengelola sinkronisasi dua arah antara SQLite lokal dan server.
///
/// - Download: tarik surat baru dari server, upsert ke SQLite.
/// - Upload: dorong bukti foto + metadata surat yang `needsUpload`.
///
/// Catatan: layer transport (Dio) di-inject agar mudah di-test dan
/// di-stub saat Edge Functions belum siap.
class SyncManager {
  final Dio _dio;
  final ExpeditionRepository _repository;
  final SyncPrefs _prefs;

  SyncManager({
    required Dio dio,
    required ExpeditionRepository repository,
    required SyncPrefs prefs,
  })  : _dio = dio,
        _repository = repository,
        _prefs = prefs;

  /// Tarik data baru dari Supabase REST API dan upsert ke SQLite.
  Future<int> download() async {
    // Membangun URL REST API Supabase secara absolut agar mengabaikan baseUrl Edge Function
    final String restUrl = '${_dio.options.baseUrl.replaceFirst('/functions/v1', '/rest/v1')}/surat_ekspedisi';

    final res = await _dio.get(
      restUrl,
      queryParameters: {
        'select': 'uuid,nomor_surat,perihal,status,tanggal_penerimaan,nama_penerima,kurir_id,divisi_pengirim:divisi_pengirim_id(nama_divisi),divisi_tujuan:divisi_tujuan_id(nama_divisi)',
      },
    );

    final rawList = res.data as List;
    final items = rawList
        .map((e) => Expedition.fromServerJson(e as Map<String, dynamic>))
        .toList();

    await _repository.upsertAll(items);

    // Tandai waktu sinkronisasi terakhir
    await _prefs.setLastSyncAt(DateTime.now().toUtc().toIso8601String());
    return items.length;
  }

  /// Unggah semua surat yang `needsUpload` (bukti foto + metadata).
  Future<({int uploaded, int failed})> upload() async {
    final pending = await _repository.getPendingUpload();
    var uploaded = 0;
    var failed = 0;

    for (final exp in pending) {
      try {
        await _uploadOne(exp);
        await _repository.markSynced(exp.uuid);
        uploaded++;
      } catch (_) {
        failed++;
      }
    }
    return (uploaded: uploaded, failed: failed);
  }

  Future<void> _uploadOne(Expedition exp) async {
    // Sesuai API contract: multipart/form-data ke Edge Function /functions/v1/sync-proof.
    // surat_id dikirim sebagai field form data.
    final formData = FormData.fromMap({
      'surat_id': exp.uuid,
      if (exp.fotoPath != null)
        'file': await MultipartFile.fromFile(exp.fotoPath!),
      'penerima': exp.penerima,
      'tanggal_diterima': exp.tanggalDiterima,
      'lat': exp.lat,
      'lon': exp.lng,
      'hash': exp.fotoHash,
    });

    await _dio.post(
      AppConstants.epSurat + "/" + exp.uuid + "/bukti",
      data: formData,
    );
  }

  String _getUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return '';
      String payload = parts[1];
      String normalized = base64Url.normalize(payload);
      String resp = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(resp)['sub'] ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Klaim surat yang berstatus draft menjadi tugas kurir (dikirim).
  Future<bool> takeSurat(String uuid) async {
    try {
      // Get auth token from interceptor or storage
      final authHeader = _dio.options.headers['Authorization'] ?? '';
      final token = authHeader.toString().replaceFirst('Bearer ', '');
      final myUid = _getUserIdFromToken(token);

      if (myUid.isEmpty) return false;

      final String restUrl = '${_dio.options.baseUrl.replaceFirst('/functions/v1', '/rest/v1')}/surat_ekspedisi';
      
      await _dio.patch(
        '$restUrl?uuid=eq.$uuid',
        data: {
          'status': 'dikirim',
          'kurir_id': myUid,
        },
      );
      
      // Update local db
      await _repository.updateStatusAndKurir(uuid, 'dikirim', myUid);
      // SyncManager is usually followed by UI refresh
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Siklus penuh: download lalu upload.
  Future<SyncResult> syncAll() async {
    try {
      final downloaded = await download();
      final up = await upload();
      return SyncResult(
        downloaded: downloaded,
        uploaded: up.uploaded,
        failed: up.failed,
      );
    } on DioException catch (e) {
      return SyncResult(error: e.message ?? 'Gagal sinkronisasi');
    } catch (e) {
      return SyncResult(error: e.toString());
    }
  }
}
