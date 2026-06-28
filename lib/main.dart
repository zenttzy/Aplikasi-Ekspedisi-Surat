import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/di/service_locator.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi dependency injection (DB, network, repository, sync).
  await initDependencies();

  runApp(EkspedisiSuratApp(isConfigured: AppConfig.isConfigured));
}
