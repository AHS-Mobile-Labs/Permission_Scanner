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

  static List<AppInfo> _parseAppsFromJson(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      final List<dynamic> appsJson = json['apps'] ?? [];

      return appsJson.map((appJson) {
        final permissions = List<String>.from(
          appJson['permissions'] as List? ?? [],
        );
        return AppInfo(
          packageName: appJson['packageName'] as String,
          appName: appJson['appName'] as String,
          iconPath: appJson['iconPath'] as String?,
          permissions: permissions,
          riskLevel: RiskLevel.safe,
          dangerousPermissionCount: 0,
          privacyScore: 100,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
