import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  bool _isInitialized = false;

  NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  Future<void> init() async {
    if (_isInitialized) return;

    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iOSSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(initSettings);
    _isInitialized = true;
  }

  Future<void> showHighRiskAppNotification({
    required String appName,
    required int dangerousPermissionCount,
    required String packageName,
  }) async {
    if (!_isInitialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'high_risk_apps',
      'High Risk Apps',
      channelDescription: 'Notifications for apps with dangerous permissions',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iOSDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      packageName.hashCode,
      '⚠️ High-Risk App Detected',
      '$appName has $dangerousPermissionCount dangerous permissions',
      notificationDetails,
    );
  }

  Future<void> showNotification({
    required String title,
    required String body,
    required String id,
  }) async {
    if (!_isInitialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'permission_scanner',
      'Permission Scanner',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iOSDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id.hashCode,
      title,
      body,
      notificationDetails,
    );
  }

  Future<void> cancelAll() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
