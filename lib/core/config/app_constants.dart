/// Konstanta global aplikasi: nama tabel/kolom SQLite, key penyimpanan,
/// dan endpoint API. Dipusatkan agar konsisten antara DB lokal dan sync.
class AppConstants {
  AppConstants._();

  // ---- Database lokal (SQLite) ----
  static const String dbName = 'ekspedisi_surat.db';
  static const int dbVersion = 1;

  static const String tableExpeditions = 'expeditions';

  // ---- Endpoint Edge Functions ----

  /// Upload bukti per surat via Edge Function (surat_id dikirim lewat form data).
  static const String epUploadBukti = '/functions/v1/sync-proof';

  // ---- Endpoint Supabase Auth ----
  static const String epAuthToken = '/token';

  // ---- Key secure storage ----
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';

  // ---- Key shared preferences ----
  static const String prefLastSyncAt = 'last_sync_at';
  static const String prefDeviceId = 'device_id';
}

/// Status surat ekspedisi (selaras dengan server: draft/dikirim/diterima).
class ExpeditionStatus {
  ExpeditionStatus._();

  static const String draft = 'draft';
  static const String dikirim = 'dikirim';
  static const String diterima = 'diterima';
}
