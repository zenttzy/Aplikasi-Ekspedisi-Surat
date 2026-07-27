import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

/// Background message handler — must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // No-op: local notification is shown by FCM automatically in background
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _localNotif = FlutterLocalNotificationsPlugin();

  static const _channelId = 'surat_channel';
  static const _channelName = 'Surat Ekspedisi';

  Future<void> init() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // Request permission (Android 13+ / iOS)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Setup local notifications channel (Android)
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notifikasi surat ekspedisi masuk',
      importance: Importance.high,
    );
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Init local notifications
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotif.initialize(initSettings);

    // Show notification when app is in foreground
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _localNotif.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Notifikasi surat ekspedisi masuk',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    });

    // Handle notification tap when app in background (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] Tapped notification: ${message.data}');
    });

    // Handle notification tap when app was terminated
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      debugPrint('[FCM] Launched from notification: ${initial.data}');
    }
  }

  /// Get FCM token for this device
  Future<String?> getToken() => _fcm.getToken();

  /// Stream of token refreshes
  Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;
}
