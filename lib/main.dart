import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/config/app_config.dart';
import 'core/di/service_locator.dart';
import 'core/notifications/notification_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init Firebase (requires google-services.json in android/app/)
  try {
    await Firebase.initializeApp();
    await NotificationService().init();
  } catch (e) {
    debugPrint('[Firebase] Init skipped: $e');
  }

  await initDependencies();

  runApp(EkspedisiSuratApp(isConfigured: AppConfig.isConfigured));
}
