import 'package:sqflite/sqflite.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/database/database_helper.dart';
import 'expedition_model.dart';

/// Repository untuk operasi CRUD surat ekspedisi pada SQLite lokal.
///
/// Semua pembacaan UI menembak repository ini (offline-first). Penulisan
/// dari kurir menandai `needsUpload = true` agar diproses SyncManager.
class ExpeditionRepository {
  final DatabaseHelper _dbHelper;

  ExpeditionRepository(this._dbHelper);

  Future<Database> get _db async => _dbHelper.database;

  /// Ambil semua surat, terbaru di atas (urut by status lalu nomor surat).
  Future<List<Expedition>> getAll() async {
    final db = await _db;
    final rows = await db.query(
      AppConstants.tableExpeditions,
      orderBy: 'status ASC, nomor_surat DESC',
    );
    return rows.map(Expedition.fromDbMap).toList();
  }

  /// Ambil surat berdasarkan status (mis. 'dikirim' untuk daftar surat masuk).
  Future<List<Expedition>> getByStatus(String status) async {
    final db = await _db;
    final rows = await db.query(
      AppConstants.tableExpeditions,
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'nomor_surat DESC',
    );
    return rows.map(Expedition.fromDbMap).toList();
  }

  /// Ambil satu surat by UUID.
  Future<Expedition?> getByUuid(String uuid) async {
    final db = await _db;
    final rows = await db.query(
      AppConstants.tableExpeditions,
      where: 'uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Expedition.fromDbMap(rows.first);
  }

  /// Surat yang menunggu diunggah ke server (`needs_upload = 1`).
  Future<List<Expedition>> getPendingUpload() async {
    final db = await _db;
    final rows = await db.query(
      AppConstants.tableExpeditions,
      where: 'needs_upload = 1',
      whereArgs: [],
    );
    return rows.map(Expedition.fromDbMap).toList();
  }

  /// Insert atau update (upsert) berdasarkan UUID.
  Future<void> upsert(Expedition exp) async {
    final db = await _db;
    await db.insert(
      AppConstants.tableExpeditions,
      exp.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Upsert banyak baris dalam satu transaksi (dipakai saat sync download).
  Future<void> upsertAll(List<Expedition> list) async {
    final db = await _db;
    final batch = db.batch();
    for (final exp in list) {
      batch.insert(
        AppConstants.tableExpeditions,
        exp.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Tandai surat sebagai sudah tersinkron setelah upload sukses.
  Future<void> markSynced(String uuid) async {
    final db = await _db;
    await db.update(
      AppConstants.tableExpeditions,
      {'is_synced': 1, 'needs_upload': 0},
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  /// Hapus semua data (mis. saat logout).
  Future<void> clear() async {
    final db = await _db;
    await db.delete(AppConstants.tableExpeditions);
  }
}
