import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:permission_scanner/models/app_info.dart';

class PermissionScannerService {
  static const platform = MethodChannel('permission_scanner');

  Future<List<AppInfo>> getInstalledApps() async {
    try {
      final result = await platform.invokeMethod<String>('getInstalledApps');
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
      final result = await platform.invokeMethod<String>('getAppsFingerprint');
      return result ?? '';
    } catch (e) {
      print('Error getting apps fingerprint: $e');
      return '';
    }
  }

  static List<AppInfo> _parseAppsFromJson(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      final List<dynamic> appsJson = json['apps'] ?? [];

      return appsJson.map((appJson) {
        final permissions = List<String>.from(
          appJson['permissions'] as List? ?? [],
        );
        final isSystem = appJson['isSystemApp'] as bool? ?? false;
        final installSource = appJson['installSource'] as String? ?? 'Unknown';
        final installerPackageName =
            appJson['installerPackageName'] as String? ?? '';

        return AppInfo(
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
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
