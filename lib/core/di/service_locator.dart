import 'package:get_it/get_it.dart';

import '../database/database_helper.dart';
import '../network/connectivity_service.dart';
import '../network/dio_client.dart';
import '../network/secure_storage_service.dart';
import '../sync/sync_manager.dart';
import '../sync/sync_prefs.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/expeditions/data/expedition_repository.dart';

/// Service locator global.
final GetIt sl = GetIt.instance;

/// Registrasi seluruh dependency. Dipanggil sekali di `main()` sebelum runApp.
Future<void> initDependencies() async {
  // ---- Core: storage & infrastruktur ----
  sl.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper.instance);
  sl.registerLazySingleton<SecureStorageService>(() => SecureStorageService());
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  sl.registerLazySingleton<SyncPrefs>(() => SyncPrefs());

  // ---- Network ----
  sl.registerLazySingleton<DioClient>(() => DioClient(sl()));

  // ---- Repositories ----
  sl.registerLazySingleton<AuthRepository>(() => AuthRepository(sl()));
  sl.registerLazySingleton<ExpeditionRepository>(
    () => ExpeditionRepository(sl()),
  );

  // ---- Sync ----
  sl.registerLazySingleton<SyncManager>(
    () => SyncManager(
      dio: sl<DioClient>().build(),
      repository: sl(),
      prefs: sl(),
    ),
  );
}
