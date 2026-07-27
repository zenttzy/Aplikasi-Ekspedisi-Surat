import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

const _channelId = 'surat_channel';
const _channelName = 'Surat Ekspedisi';

final _localNotif = FlutterLocalNotificationsPlugin();

/// Background/terminated handler — top-level, shows local notification
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await _initLocalNotif();
  _showLocalNotif(message);
}

Future<void> _initLocalNotif() async {
  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );
  await _localNotif.initialize(initSettings);
}

void _showLocalNotif(RemoteMessage message) {
  final notification = message.notification;
  final title = notification?.title ?? message.data['title'] ?? 'Surat Baru';
  final body = notification?.body ?? message.data['body'] ?? '';
  _localNotif.show(
    message.hashCode,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Notifikasi surat ekspedisi masuk',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      ),
    ),
  );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // Request permission
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    // Create notification channel (Android 8+)
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notifikasi surat ekspedisi masuk',
      importance: Importance.max,
      playSound: true,
    );
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Init local notifications
    await _initLocalNotif();

    // Show heads-up notification when app is in FOREGROUND
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground message listener
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM] Foreground message: ${message.messageId}');
      _showLocalNotif(message);
    });

    // Notification tapped (background)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] Opened from background: ${message.data}');
    });

    // Notification tapped (terminated)
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      debugPrint('[FCM] Launched from terminated: ${initial.data}');
    }
  }

  Future<String?> getToken() async {
    final token = await _fcm.getToken();
    debugPrint('[FCM] Token: $token');
    return token;
  }

  Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;
}
