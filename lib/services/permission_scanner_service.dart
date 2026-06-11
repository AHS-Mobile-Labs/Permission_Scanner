import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/services/app_logger.dart';

class PermissionScannerService {
  static const platform = MethodChannel('permission_scanner');

  /// Fetches installed apps with enhanced error handling and efficiency
  Future<List<AppInfo>> getInstalledApps({bool deepScan = false}) async {
    try {
      final result = await platform
          .invokeMethod<String>('getInstalledApps', {'deepScan': deepScan})
          .timeout(
            Duration(seconds: deepScan ? 95 : 20),
            onTimeout: () {
              AppLogger.info('App list fetch timeout - returning empty list');
              return '';
            },
          );
      if (result == null || result.isEmpty) return [];

      return compute(parseAppsFromJson, result);
    } catch (e, stackTrace) {
      AppLogger.error('Error getting installed apps', e, stackTrace);
      return [];
    }
  }

  Future<AppInfo?> pickAndScanApk() async {
    try {
      final uri = await platform.invokeMethod<String>('pickApkFile');
      if (uri == null || uri.isEmpty) return null;
      return scanApk(uri);
    } catch (e, stackTrace) {
      AppLogger.error('Error picking APK', e, stackTrace);
      return null;
    }
  }

  Future<AppInfo?> scanApk(String uriOrPath) async {
    try {
      final result = await platform
          .invokeMethod<String>('scanApk', {'uri': uriOrPath})
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              AppLogger.info('APK scan timeout');
              return '';
            },
          );
      if (result == null || result.isEmpty) return null;
      final apps = await compute(parseAppsFromJson, result);
      return apps.isEmpty ? null : apps.first;
    } catch (e, stackTrace) {
      AppLogger.error('Error scanning APK', e, stackTrace);
      return null;
    }
  }

  Future<String?> exportPdfReport(String reportJson) async {
    try {
      await _requestLegacyDownloadPermission();
      final path = await platform
          .invokeMethod<String>('exportPdfReport', {'reportJson': reportJson})
          .timeout(const Duration(seconds: 25));
      return path;
    } catch (e, stackTrace) {
      AppLogger.error('Error exporting PDF report', e, stackTrace);
      return null;
    }
  }

  Future<String?> exportJsonReport(String reportJson) async {
    try {
      await _requestLegacyDownloadPermission();
      final path = await platform
          .invokeMethod<String>('exportJsonReport', {'reportJson': reportJson})
          .timeout(const Duration(seconds: 25));
      return path;
    } catch (e, stackTrace) {
      AppLogger.error('Error exporting JSON report', e, stackTrace);
      return null;
    }
  }

  Future<void> _requestLegacyDownloadPermission() async {
    try {
      await Permission.storage.request();
    } catch (e, stackTrace) {
      AppLogger.error('Error requesting storage permission', e, stackTrace);
    }
  }

  Future<void> shareText({required String title, required String text}) async {
    try {
      await platform
          .invokeMethod<void>('shareText', {'title': title, 'text': text})
          .timeout(const Duration(seconds: 10));
    } catch (e, stackTrace) {
      AppLogger.error('Error sharing text', e, stackTrace);
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
              AppLogger.info('Fingerprint fetch timeout');
              return '';
            },
          );
      return result ?? '';
    } catch (e, stackTrace) {
      AppLogger.error('Error getting apps fingerprint', e, stackTrace);
      return '';
    }
  }

  /// Clears the native icon cache on Android
  /// Useful when user requests a refresh or for cleanup
  Future<void> clearNativeIconCache() async {
    try {
      await platform
          .invokeMethod<void>('clearIconCache')
          .timeout(const Duration(seconds: 10));
    } catch (e, stackTrace) {
      AppLogger.error('Error clearing native icon cache', e, stackTrace);
    }
  }
}

/// Parses JSON response off the UI isolate for large app lists.
List<AppInfo> parseAppsFromJson(String jsonString) {
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
        final installSource = appJson['installSource'] as String? ?? 'Unknown';
        final installerPackageName =
            appJson['installerPackageName'] as String? ?? '';
        final trackers = (appJson['trackers'] as List? ?? [])
            .whereType<Map>()
            .map(
              (item) => TrackerInfo.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
        final staticFindings = (appJson['staticFindings'] as List? ?? [])
            .whereType<Map>()
            .map(
              (item) =>
                  StaticScanFinding.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();

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
            trackers: trackers,
            staticFindings: staticFindings,
            signerSha256Digests: List<String>.from(
              appJson['signerSha256Digests'] as List? ?? [],
            ),
            nativeArchitectures: List<String>.from(
              appJson['nativeArchitectures'] as List? ?? [],
            ),
            serviceCount: appJson['serviceCount'] as int? ?? 0,
            receiverCount: appJson['receiverCount'] as int? ?? 0,
            activityCount: appJson['activityCount'] as int? ?? 0,
            providerCount: appJson['providerCount'] as int? ?? 0,
            targetSdkVersion: appJson['targetSdkVersion'] as int? ?? 0,
            minSdkVersion: appJson['minSdkVersion'] as int? ?? 0,
            compileSdkVersion: appJson['compileSdkVersion'] as int? ?? 0,
            compileSdkCodename: appJson['compileSdkCodename'] as String? ?? '',
            apkSizeBytes: appJson['apkSizeBytes'] as int? ?? 0,
            apkFileCount: appJson['apkFileCount'] as int? ?? 0,
            dexFileCount: appJson['dexFileCount'] as int? ?? 0,
            nativeLibraryCount: appJson['nativeLibraryCount'] as int? ?? 0,
            assetFileCount: appJson['assetFileCount'] as int? ?? 0,
            apkSha256: appJson['apkSha256'] as String? ?? '',
            firstInstallTime: _dateFromJson(appJson['firstInstallTime']),
            lastUpdateTime: _dateFromJson(appJson['lastUpdateTime']),
            hasLauncher: appJson['hasLauncher'] as bool? ?? true,
            declaresAccessibilityService:
                appJson['declaresAccessibilityService'] as bool? ?? false,
            declaresDeviceAdmin:
                appJson['declaresDeviceAdmin'] as bool? ?? false,
            requestsOverlayPermission:
                appJson['requestsOverlayPermission'] as bool? ?? false,
            runsAtBoot: appJson['runsAtBoot'] as bool? ?? false,
            keepsDeviceAwake: appJson['keepsDeviceAwake'] as bool? ?? false,
            usesForegroundService:
                appJson['usesForegroundService'] as bool? ?? false,
            usesExactAlarm: appJson['usesExactAlarm'] as bool? ?? false,
            requestsBatteryOptimizationBypass:
                appJson['requestsBatteryOptimizationBypass'] as bool? ?? false,
            hasSmsAccess: appJson['hasSmsAccess'] as bool? ?? false,
            hasCallAccess: appJson['hasCallAccess'] as bool? ?? false,
            hasContactsAccess: appJson['hasContactsAccess'] as bool? ?? false,
            hasInternetAccess: appJson['hasInternetAccess'] as bool? ?? false,
            contactsInternetCombo:
                appJson['contactsInternetCombo'] as bool? ?? false,
            smsCallInternetCombo:
                appJson['smsCallInternetCombo'] as bool? ?? false,
            hiddenLauncher: appJson['hiddenLauncher'] as bool? ?? false,
            fakeSystemRisk: appJson['fakeSystemRisk'] as bool? ?? false,
            isDebuggable: appJson['isDebuggable'] as bool? ?? false,
            usesKnownPacker: appJson['usesKnownPacker'] as bool? ?? false,
            hasNativeLibraries: appJson['hasNativeLibraries'] as bool? ?? false,
            staticAnalysisLimitReached:
                appJson['staticAnalysisLimitReached'] as bool? ?? false,
          ),
        );
      } catch (e) {
        AppLogger.info('Error parsing app at index $i: $e');
        // Skip failed entry and continue
      }
    }

    return apps;
  } catch (e, stackTrace) {
    AppLogger.error('Error parsing apps JSON', e, stackTrace);
    return [];
  }
}

DateTime? _dateFromJson(dynamic value) {
  if (value == null) return null;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String && value.isNotEmpty) {
    final millis = int.tryParse(value);
    if (millis != null) return DateTime.fromMillisecondsSinceEpoch(millis);
    return DateTime.tryParse(value);
  }
  return null;
}
