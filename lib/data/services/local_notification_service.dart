import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/services/notification_service.dart';

class LocalNotificationService implements NotificationService {
  LocalNotificationService._(this._plugin, this._isReady);

  static const int _sodiumAlertId = 1;
  static const AndroidNotificationDetails _androidDetails = AndroidNotificationDetails(
    'sodium_alerts',
    'Peringatan Natrium',
    channelDescription: 'Peringatan saat total natrium harian mendekati atau melebihi batas.',
    importance: Importance.high,
    priority: Priority.high,
  );

  final FlutterLocalNotificationsPlugin _plugin;
  final bool _isReady;

  static Future<LocalNotificationService> create() async {
    final plugin = FlutterLocalNotificationsPlugin();
    final isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
    if (!isMobile) return LocalNotificationService._(plugin, false);

    try {
      await plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      return LocalNotificationService._(plugin, true);
    } catch (_) {
      return LocalNotificationService._(plugin, false);
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!_isReady) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? await android.areNotificationsEnabled() ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> showSodiumAlert({required String title, required String body}) async {
    if (!_isReady) return;
    await _plugin.show(
      id: _sodiumAlertId,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: _androidDetails, iOS: DarwinNotificationDetails()),
    );
  }
}
