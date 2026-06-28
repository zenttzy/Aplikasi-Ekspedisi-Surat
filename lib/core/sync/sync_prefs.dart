import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_constants.dart';

/// Wrapper SharedPreferences untuk metadata sinkronisasi
/// (timestamp sync terakhir & device id).
class SyncPrefs {
  /// Ambil timestamp sync terakhir; null jika sync awal (install baru).
  Future<String?> getLastSyncAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefLastSyncAt);
  }

  Future<void> setLastSyncAt(String iso) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefLastSyncAt, iso);
  }

  Future<String?> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefDeviceId);
  }

  Future<void> setDeviceId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefDeviceId, id);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefLastSyncAt);
  }
}
