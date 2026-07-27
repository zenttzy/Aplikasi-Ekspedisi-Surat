import 'package:get_it/get_it.dart';

import '../database/database_helper.dart';
import '../network/connectivity_service.dart';
import '../network/dio_client.dart';
import '../network/secure_storage_service.dart';
import '../sync/sync_manager.dart';
import '../sync/sync_prefs.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/expeditions/data/api_surat_repository.dart';
import '../../features/expeditions/data/expedition_repository.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  sl.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper.instance);
  sl.registerLazySingleton<SecureStorageService>(() => SecureStorageService());
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  sl.registerLazySingleton<SyncPrefs>(() => SyncPrefs());
  sl.registerLazySingleton<DioClient>(() => DioClient(sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepository(sl()));
  sl.registerLazySingleton<ExpeditionRepository>(
    () => ExpeditionRepository(sl()),
  );
  sl.registerLazySingleton<ApiSuratRepository>(
    () => ApiSuratRepository(sl()),
  );
  sl.registerLazySingleton<SyncManager>(
    () => SyncManager(
      api: sl(),
      repository: sl(),
      connectivity: sl(),
      storage: sl(),
      prefs: sl(),
    ),
  );
}
