class AppConstants {
  AppConstants._();

  static const String dbName = 'ekspedisi_surat.db';
  static const int dbVersion = 2;
  static const String tableExpeditions = 'expeditions';

  // REST API endpoints
  static const String epLogin = '/auth/login';
  static const String epRegister = '/auth/register';
  static const String epMe = '/auth/me';
  static const String epSurat = '/surat';
  static const String epUploadBukti = '/surat';
  static const String epPairingClaim = '/pairing/claim';

  // Secure storage keys
  static const String keyAccessToken = 'access_token';
  static const String keyUserId = 'user_id';
  static const String keyUserRole = 'user_role';
  static const String keyUserData = 'user_data';

  // Shared prefs
  static const String prefLastSyncAt = 'last_sync_at';
  static const String prefDeviceId = 'device_id';
}

class ExpeditionStatus {
  ExpeditionStatus._();
  static const String draft = 'draft';
  static const String dikirim = 'dikirim';
  static const String diterima = 'diterima';
}
