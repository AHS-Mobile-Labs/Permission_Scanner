import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:permission_scanner/models/app_info.dart';

class PermissionScannerService {
  static const platform = MethodChannel('permission_scanner');

  /// Fetches installed apps with enhanced error handling and efficiency
  Future<List<AppInfo>> getInstalledApps() async {
    try {
      final result = await platform
          .invokeMethod<String>('getInstalledApps')
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('App list fetch timeout - returning empty list');
              return '';
            },
          );
      if (result == null || result.isEmpty) return [];

      return _parseAppsFromJson(result);
    } catch (e) {
      print('Error getting installed apps: $e');
      return [];
    }
  }

  /// Returns a fingerprint hash of the currently installed package set.
  /// Changes when any app is installed, uninstalled, or updated.
  Future<String> getAppsFingerprint() async {
    try {
      final result = await platform
          .invokeMethod<String>('getAppsFingerprint')
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('Fingerprint fetch timeout');
              return '';
            },
          );
      return result ?? '';
    } catch (e) {
      print('Error getting apps fingerprint: $e');
      return '';
    }
  }

  /// Parses JSON response with improved performance for large app lists
  static List<AppInfo> _parseAppsFromJson(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      final List<dynamic> appsJson = json['apps'] ?? [];

      final apps = <AppInfo>[];

      // Parse apps efficiently, skipping failed entries
      for (int i = 0; i < appsJson.length; i++) {
        try {
          final appJson = appsJson[i];
          final permissions = List<String>.from(
            appJson['permissions'] as List? ?? [],
          );
          final isSystem = appJson['isSystemApp'] as bool? ?? false;
          final installSource =
              appJson['installSource'] as String? ?? 'Unknown';
          final installerPackageName =
              appJson['installerPackageName'] as String? ?? '';

          apps.add(
            AppInfo(
              packageName: appJson['packageName'] as String,
              appName: appJson['appName'] as String,
              iconPath: appJson['iconPath'] as String?,
              permissions: permissions,
              riskLevel: RiskLevel.safe,
              dangerousPermissionCount: 0,
              privacyScore: 100,
              isSystemApp: isSystem,
              installSource: installSource,
              installerPackageName: installerPackageName,
            ),
          );
        } catch (e) {
          print('Error parsing app at index $i: $e');
          // Skip failed entry and continue
        }
      }

      return apps;
    } catch (e) {
      print('Error parsing apps JSON: $e');
      return [];
    }
  }

  /// Clears the native icon cache on Android
  /// Useful when user requests a refresh or for cleanup
  Future<void> clearNativeIconCache() async {
    try {
      await platform.invokeMethod<void>('clearIconCache');
    } catch (e) {
      print('Error clearing native icon cache: $e');
    }
  }
}
