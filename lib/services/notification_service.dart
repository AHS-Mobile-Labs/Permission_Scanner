import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

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

    try {
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const initSettings = InitializationSettings(android: androidSettings);

      await _flutterLocalNotificationsPlugin.initialize(initSettings);

      // Request notification permission on Android 13+
      await _requestNotificationPermission();

      _isInitialized = true;
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      if (status.isDenied) {
        print('Notification permission denied');
      } else if (status.isPermanentlyDenied) {
        print(
          'Notification permission permanently denied, opening app settings',
        );
        openAppSettings();
      } else if (status.isGranted) {
        print('Notification permission granted');
      }
    } catch (e) {
      print('Error requesting notification permission: $e');
    }
  }

  Future<void> showHighRiskAppNotification({
    required String appName,
    required int dangerousPermissionCount,
    required String packageName,
  }) async {
    try {
      if (!_isInitialized) await init();

      // Check if notification permission is granted
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        print('Notification permission not granted, cannot show notification');
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        'high_risk_apps',
        'High Risk Apps',
        channelDescription: 'Notifications for apps with dangerous permissions',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        showProgress: false,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _flutterLocalNotificationsPlugin.show(
        packageName.hashCode,
        '⚠️ High-Risk App Detected',
        '$appName has $dangerousPermissionCount dangerous permissions',
        notificationDetails,
      );
      print('High-risk app notification shown for $appName');
    } catch (e) {
      print('Error showing high-risk app notification: $e');
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    required String id,
  }) async {
    try {
      if (!_isInitialized) await init();

      // Check if notification permission is granted
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        print('Notification permission not granted, cannot show notification');
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        'permission_scanner',
        'Permission Scanner',
        channelDescription: 'Permission Scanner notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        showProgress: false,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _flutterLocalNotificationsPlugin.show(
        id.hashCode,
        title,
        body,
        notificationDetails,
      );
      print('Notification shown: $title');
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  Future<void> cancelAll() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      print('All notifications cancelled');
    } catch (e) {
      print('Error cancelling notifications: $e');
    }
  }
}
