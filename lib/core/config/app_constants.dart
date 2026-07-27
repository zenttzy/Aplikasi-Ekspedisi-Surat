class AppConstants {
  AppConstants._();

  static const String dbName = 'ekspedisi_surat.db';
  static const int dbVersion = 1;
  static const String tableExpeditions = 'expeditions';

  // REST API endpoints
  static const String epLogin = '/auth/login';
  static const String epRegister = '/auth/register';
  static const String epMe = '/auth/me';
  static const String epSurat = '/surat';

  // Secure storage keys
  static const String keyAccessToken = 'access_token';
  static const String keyUserId = 'user_id';
  static const String keyUserRole = 'user_role';
  static const String keyUserData = 'user_data';

  // Shared prefs
  static const String prefLastSyncAt = 'last_sync_at';
}

class ExpeditionStatus {
  ExpeditionStatus._();
  static const String draft = 'draft';
  static const String dikirim = 'dikirim';
  static const String diterima = 'diterima';
}
