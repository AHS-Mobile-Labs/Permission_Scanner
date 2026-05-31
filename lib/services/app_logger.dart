import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();

  static void info(String message) {
    debugPrint('[PermissionScanner] $message');
  }

  static void error(String message, Object error, StackTrace? stackTrace) {
    debugPrint('[PermissionScanner] $message: $error');
    if (stackTrace != null && kDebugMode) {
      debugPrintStack(label: message, stackTrace: stackTrace);
    }
  }
}
