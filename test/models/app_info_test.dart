import 'package:flutter_test/flutter_test.dart';
import 'package:permission_scanner/models/app_info.dart';

void main() {
  group('AppInfo JSON Serialization & Null Safety', () {
    test('Serializes and deserializes correctly with complete fields', () {
      final original = AppInfo(
        packageName: 'com.ahsmobilelabs.test',
        appName: 'Test Application',
        iconPath: '/data/user/0/com.ahsmobilelabs/app_icons/test.png',
        permissions: [
          'android.permission.CAMERA',
          'android.permission.INTERNET',
        ],
        riskLevel: RiskLevel.safe,
        dangerousPermissionCount: 1,
        privacyScore: 92,
        isSystemApp: false,
        installSource: 'Play Store',
        installerPackageName: 'com.android.vending',
        trackers: [
          const TrackerInfo(
            id: 'admob',
            name: 'Google AdMob',
            category: 'Advertising',
            purpose: 'Ad display',
            riskWeight: 4,
          ),
        ],
        riskSignals: [
          const RiskSignal(
            id: 'sensor',
            title: 'Camera access',
            description: 'Can take pictures',
            severity: 'medium',
            weight: 8,
          ),
        ],
        staticFindings: [
          const StaticScanFinding(
            id: 'exported_service',
            title: 'Exported service',
            description: 'Accessible to other apps',
            severity: 'low',
            weight: 2,
          ),
        ],
        malwareIndicators: ['Heuristic test indicator'],
        targetSdkVersion: 34,
        minSdkVersion: 26,
        apkSizeBytes: 15420000,
        apkSha256: 'abcdef1234567890',
        runsAtBoot: true,
        hasInternetAccess: true,
      );

      final json = original.toJson();
      final parsed = AppInfo.fromJson(json);

      expect(parsed.packageName, equals('com.ahsmobilelabs.test'));
      expect(parsed.appName, equals('Test Application'));
      expect(
        parsed.iconPath,
        equals('/data/user/0/com.ahsmobilelabs/app_icons/test.png'),
      );
      expect(
        parsed.permissions,
        equals(['android.permission.CAMERA', 'android.permission.INTERNET']),
      );
      expect(parsed.riskLevel, equals(RiskLevel.safe));
      expect(parsed.dangerousPermissionCount, equals(1));
      expect(parsed.privacyScore, equals(92));
      expect(parsed.isSystemApp, isFalse);
      expect(parsed.installSource, equals('Play Store'));
      expect(parsed.trackers.length, equals(1));
      expect(parsed.trackers.first.id, equals('admob'));
      expect(parsed.riskSignals.length, equals(1));
      expect(parsed.staticFindings.length, equals(1));
      expect(parsed.malwareIndicators, equals(['Heuristic test indicator']));
      expect(parsed.targetSdkVersion, equals(34));
      expect(parsed.apkSizeBytes, equals(15420000));
      expect(parsed.runsAtBoot, isTrue);
      expect(parsed.hasInternetAccess, isTrue);
    });

    test('Handles missing, null, or malformed JSON gracefully', () {
      final minimalJson = <String, dynamic>{'packageName': 'com.minimal.app'};

      final parsed = AppInfo.fromJson(minimalJson);

      expect(parsed.packageName, equals('com.minimal.app'));
      expect(parsed.appName, equals('com.minimal.app'));
      expect(parsed.permissions, isEmpty);
      expect(parsed.riskLevel, equals(RiskLevel.safe));
      expect(parsed.privacyScore, equals(0));
      expect(parsed.dangerousPermissionCount, equals(0));
      expect(parsed.isSystemApp, isFalse);
      expect(parsed.installSource, equals('Unknown'));
      expect(parsed.trackers, isEmpty);
      expect(parsed.riskSignals, isEmpty);
    });

    test('copyWith updates specified fields while retaining others', () {
      final base = AppInfo(
        packageName: 'com.test.app',
        appName: 'Test',
        permissions: const [],
        riskLevel: RiskLevel.safe,
        dangerousPermissionCount: 0,
        privacyScore: 100,
        isSystemApp: false,
        installSource: 'Unknown',
      );

      final updated = base.copyWith(
        appName: 'Renamed Test',
        privacyScore: 85,
        riskLevel: RiskLevel.medium,
      );

      expect(updated.packageName, equals('com.test.app'));
      expect(updated.appName, equals('Renamed Test'));
      expect(updated.privacyScore, equals(85));
      expect(updated.riskLevel, equals(RiskLevel.medium));
      expect(updated.isSystemApp, isFalse);
    });
  });
}
