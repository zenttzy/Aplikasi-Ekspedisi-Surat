import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../config/app_constants.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final path = p.join(docsDir.path, AppConstants.dbName);

    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableExpeditions} (
        uuid             TEXT PRIMARY KEY,
        nomor_surat      TEXT,
        perihal          TEXT NOT NULL,
        divisi_pengirim  TEXT NOT NULL,
        divisi_tujuan    TEXT NOT NULL,
        penerima         TEXT,
        tanggal_diterima TEXT,
        created_at       TEXT,
        foto_path        TEXT,
        foto_hash        TEXT,
        lat              REAL,
        long             REAL,
        alamat           TEXT,
        status           TEXT NOT NULL DEFAULT '${ExpeditionStatus.draft}',
        kurir_id         TEXT,
        is_synced        INTEGER NOT NULL DEFAULT 0,
        needs_upload     INTEGER NOT NULL DEFAULT 0,
        pending_take     INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_exp_status ON ${AppConstants.tableExpeditions}(status)',
    );
    await db.execute(
      'CREATE INDEX idx_exp_pending ON ${AppConstants.tableExpeditions}(pending_take, needs_upload)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE ${AppConstants.tableExpeditions} ADD COLUMN created_at TEXT',
      );
      await db.execute(
        'ALTER TABLE ${AppConstants.tableExpeditions} ADD COLUMN pending_take INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_exp_pending ON ${AppConstants.tableExpeditions}(pending_take, needs_upload)',
      );
    }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
