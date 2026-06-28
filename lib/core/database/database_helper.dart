import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../config/app_constants.dart';

/// Pengelola koneksi database SQLite lokal (singleton).
///
/// UI dan repository selalu membaca dari sini (arsitektur offline-first),
/// bukan langsung dari API. SyncManager-lah yang menjembatani ke server.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    // Simpan DB di direktori dokumen aplikasi agar persisten & ter-backup.
    final docsDir = await getApplicationDocumentsDirectory();
    final path = p.join(docsDir.path, AppConstants.dbName);

    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onConfigure: (db) async {
        // Aktifkan foreign keys (untuk pengembangan tabel relasional nanti).
        await db.execute('PRAGMA foreign_keys = ON');
      },
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
        foto_path        TEXT,
        foto_hash        TEXT,
        lat              REAL,
        long             REAL,
        alamat           TEXT,
        status           TEXT NOT NULL DEFAULT '${ExpeditionStatus.dikirim}',
        is_synced        INTEGER NOT NULL DEFAULT 0,
        needs_upload     INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Index untuk query yang sering dipakai oleh UI & SyncManager.
    await db.execute(
      'CREATE INDEX idx_exp_status ON ${AppConstants.tableExpeditions}(status)',
    );
    await db.execute(
      'CREATE INDEX idx_exp_needs_upload ON ${AppConstants.tableExpeditions}(needs_upload)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Tempat migrasi skema di versi mendatang.
  }

  /// Menutup koneksi (mis. saat logout / testing).
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
