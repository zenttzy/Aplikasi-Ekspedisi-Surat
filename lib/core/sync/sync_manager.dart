import 'dart:async';
import 'dart:io';

import '../network/connectivity_service.dart';
import '../network/secure_storage_service.dart';
import '../../features/expeditions/data/api_surat_repository.dart';
import '../../features/expeditions/data/expedition_model.dart';
import '../../features/expeditions/data/expedition_repository.dart';
import 'sync_prefs.dart';

class SyncState {
  final bool isOnline;
  final bool isSyncing;
  final int pendingCount;
  final String? lastSyncAt;
  final String? error;

  const SyncState({
    required this.isOnline,
    required this.isSyncing,
    required this.pendingCount,
    this.lastSyncAt,
    this.error,
  });
}

class OfflineActionResult {
  final bool synced;
  final bool queued;

  const OfflineActionResult({
    required this.synced,
    required this.queued,
  });
}

class SyncManager {
  final ApiSuratRepository _api;
  final ExpeditionRepository _repository;
  final ConnectivityService _connectivity;
  final SecureStorageService _storage;
  final SyncPrefs _prefs;

  final _stateController = StreamController<SyncState>.broadcast();
  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _retryTimer;
  bool _syncing = false;
  bool _started = false;
  bool _online = false;

  SyncManager({
    required ApiSuratRepository api,
    required ExpeditionRepository repository,
    required ConnectivityService connectivity,
    required SecureStorageService storage,
    required SyncPrefs prefs,
  })  : _api = api,
        _repository = repository,
        _connectivity = connectivity,
        _storage = storage,
        _prefs = prefs;

  Stream<SyncState> get states => _stateController.stream;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _online = await _connectivity.isConnected;
    await _emitState();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((isOnline) async {
      _online = isOnline;
      await _emitState();
      if (isOnline) await syncAll();
    });
    _retryTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      if (_online && await _repository.getPendingCount() > 0) {
        await syncAll();
      }
    });
    if (_online) await syncAll();
  }

  Future<List<Expedition>> loadLocal() => _repository.getAll();

  Future<OfflineActionResult> takeSurat(Expedition expedition) async {
    final user = await _storage.getUserData();
    final courierId = user?['id'] as String?;
    if (courierId == null || courierId.isEmpty) {
      throw StateError('Data kurir tidak ditemukan. Silakan login ulang.');
    }

    await _repository.queueTake(
      expedition: expedition,
      courierId: courierId,
    );
    await _emitState();

    if (!_online) {
      return const OfflineActionResult(synced: false, queued: true);
    }

    await syncAll();
    final refreshed = await _repository.getByUuid(expedition.uuid);
    return OfflineActionResult(
      synced: refreshed?.pendingTake == false,
      queued: refreshed?.pendingTake == true,
    );
  }

  Future<OfflineActionResult> saveProof({
    required Expedition expedition,
    required String recipient,
    required String photoPath,
    required String photoHash,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    await _repository.queueProof(
      expedition: expedition,
      recipient: recipient,
      photoPath: photoPath,
      photoHash: photoHash,
      latitude: latitude,
      longitude: longitude,
      address: address,
    );
    await _emitState();

    if (!_online) {
      return const OfflineActionResult(synced: false, queued: true);
    }

    await syncAll();
    final refreshed = await _repository.getByUuid(expedition.uuid);
    return OfflineActionResult(
      synced: refreshed?.needsUpload == false,
      queued: refreshed?.needsUpload == true,
    );
  }

  Future<void> syncAll() async {
    if (_syncing || !_online) return;
    _syncing = true;
    await _emitState();

    String? error;
    try {
      final pendingTake = await _repository.getPendingTake();
      for (final expedition in pendingTake) {
        try {
          final success = await _api.ambilSurat(expedition.uuid);
          if (!success) {
            throw StateError('Data kurir tidak tersedia.');
          }
          await _repository.markTakeSynced(expedition.uuid);
        } catch (exception) {
          error = 'Sebagian klaim surat belum tersinkron.';
        }
      }

      final pendingProof = await _repository.getPendingUpload();
      for (final expedition in pendingProof) {
        final photoPath = expedition.fotoPath;
        if (photoPath == null || !await File(photoPath).exists()) {
          error = 'File foto untuk ${expedition.nomorSurat ?? expedition.uuid} tidak ditemukan.';
          continue;
        }
        try {
          await _api.uploadBukti(
            uuid: expedition.uuid,
            foto: File(photoPath),
            lat: expedition.lat ?? 0,
            lng: expedition.lng ?? 0,
            namaPenerima: expedition.penerima ?? '',
            fotoHash: expedition.fotoHash,
          );
          await _repository.markProofSynced(expedition.uuid);
        } catch (exception) {
          error = 'Sebagian bukti pengiriman belum tersinkron.';
        }
      }

      final serverItems = await _api.fetchSurat();
      await _repository.upsertFromServer(serverItems);
      final now = DateTime.now().toUtc().toIso8601String();
      await _prefs.setLastSyncAt(now);
    } catch (exception) {
      error = 'Sinkronisasi tertunda. Akan dicoba kembali saat koneksi stabil.';
    } finally {
      _syncing = false;
      await _emitState(error: error);
    }
  }

  Future<void> _emitState({String? error}) async {
    if (_stateController.isClosed) return;
    _stateController.add(
      SyncState(
        isOnline: _online,
        isSyncing: _syncing,
        pendingCount: await _repository.getPendingCount(),
        lastSyncAt: await _prefs.getLastSyncAt(),
        error: error,
      ),
    );
  }

  Future<void> dispose() async {
    _retryTimer?.cancel();
    await _connectivitySubscription?.cancel();
    await _stateController.close();
  }
}
