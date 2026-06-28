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

  /// Tarik data baru dari `/sync/download` dan upsert ke SQLite.
  Future<int> download() async {
    final lastSyncAt = await _prefs.getLastSyncAt();

    final res = await _dio.post(
      AppConstants.epSyncDownload,
      data: {'last_sync_at': lastSyncAt},
    );

    final body = res.data as Map<String, dynamic>;
    final rawList = (body['data'] as List?) ?? const [];
    final items = rawList
        .map((e) => Expedition.fromSyncJson(e as Map<String, dynamic>))
        .toList();

    await _repository.upsertAll(items);

    final serverTime = body['server_time'] as String?;
    if (serverTime != null) {
      await _prefs.setLastSyncAt(serverTime);
    }
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
    // Sesuai API contract: multipart/form-data ke /expeditions/{uuid}/upload-bukti.
    // File foto akan ditambahkan oleh layer kamera saat fitur itu diimplementasi.
    final formData = FormData.fromMap({
      if (exp.fotoPath != null)
        'file_overlay': await MultipartFile.fromFile(exp.fotoPath!),
      'penerima': exp.penerima,
      'tanggal_diterima': exp.tanggalDiterima,
      'lat': exp.lat,
      'long': exp.long,
      'foto_hash': exp.fotoHash,
    });

    await _dio.post(
      AppConstants.epUploadBukti(exp.uuid),
      data: formData,
    );
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
