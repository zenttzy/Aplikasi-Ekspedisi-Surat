import 'package:sqflite/sqflite.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/database/database_helper.dart';
import 'expedition_model.dart';

class ExpeditionRepository {
  final DatabaseHelper _dbHelper;

  ExpeditionRepository(this._dbHelper);

  Future<Database> get _db async => _dbHelper.database;

  Future<List<Expedition>> getAll() async {
    final db = await _db;
    final rows = await db.query(
      AppConstants.tableExpeditions,
      orderBy: 'created_at DESC, nomor_surat DESC',
    );
    return rows.map(Expedition.fromSqlite).toList();
  }

  Future<Expedition?> getByUuid(String uuid) async {
    final db = await _db;
    final rows = await db.query(
      AppConstants.tableExpeditions,
      where: 'uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    return rows.isEmpty ? null : Expedition.fromSqlite(rows.first);
  }

  Future<List<Expedition>> getPendingTake() async {
    final db = await _db;
    final rows = await db.query(
      AppConstants.tableExpeditions,
      where: 'pending_take = 1',
      orderBy: 'created_at ASC',
    );
    return rows.map(Expedition.fromSqlite).toList();
  }

  Future<List<Expedition>> getPendingUpload() async {
    final db = await _db;
    final rows = await db.query(
      AppConstants.tableExpeditions,
      where: 'needs_upload = 1',
      orderBy: 'created_at ASC',
    );
    return rows.map(Expedition.fromSqlite).toList();
  }

  Future<int> getPendingCount() async {
    final db = await _db;
    final result = await db.rawQuery(
      '''SELECT COUNT(*) AS total
         FROM ${AppConstants.tableExpeditions}
         WHERE pending_take = 1 OR needs_upload = 1''',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> upsert(Expedition expedition) async {
    final db = await _db;
    await db.insert(
      AppConstants.tableExpeditions,
      expedition.toSqliteMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertFromServer(List<Expedition> serverItems) async {
    final db = await _db;
    await db.transaction((transaction) async {
      for (final serverItem in serverItems) {
        final rows = await transaction.query(
          AppConstants.tableExpeditions,
          where: 'uuid = ?',
          whereArgs: [serverItem.uuid],
          limit: 1,
        );
        final local = rows.isEmpty ? null : Expedition.fromSqlite(rows.first);

        if (local?.pendingTake == true || local?.needsUpload == true) {
          continue;
        }

        final merged = serverItem.copyWith(
          fotoPath: local?.fotoPath,
          fotoHash: local?.fotoHash,
          lat: serverItem.lat ?? local?.lat,
          lng: serverItem.lng ?? local?.lng,
          alamat: local?.alamat,
        );
        await transaction.insert(
          AppConstants.tableExpeditions,
          merged.toSqliteMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> queueTake({
    required Expedition expedition,
    required String courierId,
  }) async {
    await upsert(
      expedition.copyWith(
        status: ExpeditionStatus.dikirim,
        kurirId: courierId,
        pendingTake: true,
        isSynced: false,
      ),
    );
  }

  Future<void> queueProof({
    required Expedition expedition,
    required String recipient,
    required String photoPath,
    required String photoHash,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    await upsert(
      expedition.copyWith(
        status: ExpeditionStatus.diterima,
        penerima: recipient,
        tanggalDiterima: DateTime.now().toUtc().toIso8601String(),
        fotoPath: photoPath,
        fotoHash: photoHash,
        lat: latitude,
        lng: longitude,
        alamat: address,
        needsUpload: true,
        isSynced: false,
      ),
    );
  }

  Future<void> markTakeSynced(String uuid) async {
    final db = await _db;
    await db.rawUpdate(
      '''UPDATE ${AppConstants.tableExpeditions}
         SET pending_take = 0,
             is_synced = CASE WHEN needs_upload = 1 THEN 0 ELSE 1 END
         WHERE uuid = ?''',
      [uuid],
    );
  }

  Future<void> markProofSynced(String uuid) async {
    final db = await _db;
    await db.update(
      AppConstants.tableExpeditions,
      {
        'pending_take': 0,
        'needs_upload': 0,
        'is_synced': 1,
      },
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  Future<void> clear() async {
    final db = await _db;
    await db.delete(AppConstants.tableExpeditions);
  }
}
