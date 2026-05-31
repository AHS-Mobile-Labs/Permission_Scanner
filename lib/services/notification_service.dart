import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:permission_scanner/services/app_logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;
  bool _isInitialized = false;

  NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final plugin = FlutterLocalNotificationsPlugin();

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const initSettings = InitializationSettings(android: androidSettings);

      await plugin.initialize(initSettings);

      _flutterLocalNotificationsPlugin = plugin;
      _isInitialized = true;
    } catch (e, stackTrace) {
      AppLogger.error('Error initializing notifications', e, stackTrace);
    }
  }

  /// Request notification permission separately from init so it doesn't
  /// block startup with a system dialog.
  Future<void> requestPermission() async {
    await _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      if (status.isDenied) {
        AppLogger.info('Notification permission denied');
      } else if (status.isPermanentlyDenied) {
        AppLogger.info('Notification permission permanently denied');
      } else if (status.isGranted) {
        AppLogger.info('Notification permission granted');
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error requesting notification permission',
        e,
        stackTrace,
      );
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
        AppLogger.info(
          'Notification permission not granted; skipping notification',
        );
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

      await _flutterLocalNotificationsPlugin?.show(
        packageName.hashCode,
        '⚠️ High-Risk App Detected',
        '$appName has $dangerousPermissionCount dangerous permissions',
        notificationDetails,
      );
      AppLogger.info('High-risk app notification shown for $appName');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error showing high-risk app notification',
        e,
        stackTrace,
      );
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
        AppLogger.info(
          'Notification permission not granted; skipping notification',
        );
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

      await _flutterLocalNotificationsPlugin?.show(
        id.hashCode,
        title,
        body,
        notificationDetails,
      );
      AppLogger.info('Notification shown: $title');
    } catch (e, stackTrace) {
      AppLogger.error('Error showing notification', e, stackTrace);
    }
  }

  Future<void> cancelAll() async {
    try {
      if (!_isInitialized) await init();
      await _flutterLocalNotificationsPlugin?.cancelAll();
      AppLogger.info('All notifications cancelled');
    } catch (e, stackTrace) {
      AppLogger.error('Error cancelling notifications', e, stackTrace);
    }
  }
}
