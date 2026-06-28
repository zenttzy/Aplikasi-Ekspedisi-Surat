import 'package:connectivity_plus/connectivity_plus.dart';

/// Layanan pemantau konektivitas jaringan. SyncManager memakai ini untuk
/// memicu sinkronisasi saat sinyal kembali pulih (kurir sering di blank spot).
class ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityService([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  /// Stream perubahan status koneksi; emit true jika ada koneksi apa pun.
  Stream<bool> get onConnectivityChanged => _connectivity.onConnectivityChanged
      .map((results) => results.any((r) => r != ConnectivityResult.none));

  /// Cek status koneksi saat ini.
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}
