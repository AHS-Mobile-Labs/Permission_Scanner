import 'package:flutter_test/flutter_test.dart';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/services/permission_analyzer.dart';

void main() {
  group('PermissionAnalyzer Risk Scoring & Deduplication', () {
    test('Empty permissions list produces score 100 and safe risk level', () {
      final app = AppInfo(
        packageName: 'com.example.empty',
        appName: 'Empty App',
        permissions: const [],
        riskLevel: RiskLevel.safe,
        dangerousPermissionCount: 0,
        privacyScore: 100,
        isSystemApp: false,
        installSource: 'Play Store',
      );

      final enriched = PermissionAnalyzer.enrichAppInfo(app);
      expect(enriched.privacyScore, equals(100));
      expect(enriched.riskLevel, equals(RiskLevel.safe));
      expect(enriched.dangerousPermissionCount, equals(0));
      expect(enriched.malwareIndicators, isEmpty);
    });

    test(
      'Single normal sensitive permission remains in Safe / Low Risk band (>= 80)',
      () {
        final app = AppInfo(
          packageName: 'com.example.camera',
          appName: 'Simple Camera',
          permissions: const ['android.permission.CAMERA'],
          riskLevel: RiskLevel.safe,
          dangerousPermissionCount: 1,
          privacyScore: 100,
          isSystemApp: false,
          installSource: 'Play Store',
        );

        final enriched = PermissionAnalyzer.enrichAppInfo(app);
        expect(enriched.privacyScore, greaterThanOrEqualTo(80));
        expect(enriched.riskLevel, equals(RiskLevel.safe));
        expect(enriched.dangerousPermissionCount, equals(1));
      },
    );

    test('Deduplicates fine and coarse location to prevent double-counting', () {
      final fineOnlyApp = AppInfo(
        packageName: 'com.example.fine',
        appName: 'Fine Location',
        permissions: const ['android.permission.ACCESS_FINE_LOCATION'],
        riskLevel: RiskLevel.safe,
        dangerousPermissionCount: 1,
        privacyScore: 100,
        isSystemApp: false,
        installSource: 'Play Store',
      );

      final bothLocationApp = AppInfo(
        packageName: 'com.example.both',
        appName: 'Both Location',
        permissions: const [
          'android.permission.ACCESS_FINE_LOCATION',
          'android.permission.ACCESS_COARSE_LOCATION',
        ],
        riskLevel: RiskLevel.safe,
        dangerousPermissionCount: 2,
        privacyScore: 100,
        isSystemApp: false,
        installSource: 'Play Store',
      );

      final fineScore = PermissionAnalyzer.enrichAppInfo(
        fineOnlyApp,
      ).privacyScore;
      final bothScore = PermissionAnalyzer.enrichAppInfo(
        bothLocationApp,
      ).privacyScore;

      // Coarse location should not add redundant penalty when fine location is declared
      expect(bothScore, equals(fineScore));
    });

    test(
      'Deduplicates storage permissions when MANAGE_EXTERNAL_STORAGE is declared',
      () {
        final manageOnlyApp = AppInfo(
          packageName: 'com.example.storage.manage',
          appName: 'Manage Storage',
          permissions: const ['android.permission.MANAGE_EXTERNAL_STORAGE'],
          riskLevel: RiskLevel.safe,
          dangerousPermissionCount: 1,
          privacyScore: 100,
          isSystemApp: false,
          installSource: 'Play Store',
        );

        final allStorageApp = AppInfo(
          packageName: 'com.example.storage.all',
          appName: 'All Storage',
          permissions: const [
            'android.permission.MANAGE_EXTERNAL_STORAGE',
            'android.permission.READ_EXTERNAL_STORAGE',
            'android.permission.WRITE_EXTERNAL_STORAGE',
          ],
          riskLevel: RiskLevel.safe,
          dangerousPermissionCount: 3,
          privacyScore: 100,
          isSystemApp: false,
          installSource: 'Play Store',
        );

        final manageScore = PermissionAnalyzer.enrichAppInfo(
          manageOnlyApp,
        ).privacyScore;
        final allStorageScore = PermissionAnalyzer.enrichAppInfo(
          allStorageApp,
        ).privacyScore;

        expect(allStorageScore, equals(manageScore));
      },
    );

    test('Privacy score is always clamped strictly between 0 and 100', () {
      // Extremely abusive/hostile metadata combination
      final hostileApp = AppInfo(
        packageName: 'com.hostile.app',
        appName: 'System Update Helper',
        permissions: const [
          'android.permission.ACCESS_FINE_LOCATION',
          'android.permission.ACCESS_BACKGROUND_LOCATION',
          'android.permission.CAMERA',
          'android.permission.RECORD_AUDIO',
          'android.permission.READ_SMS',
          'android.permission.SEND_SMS',
          'android.permission.READ_CALL_LOG',
          'android.permission.READ_CONTACTS',
          'android.permission.INTERNET',
          'android.permission.MANAGE_EXTERNAL_STORAGE',
          'android.permission.SYSTEM_ALERT_WINDOW',
          'android.permission.BIND_ACCESSIBILITY_SERVICE',
        ],
        riskLevel: RiskLevel.safe,
        dangerousPermissionCount: 10,
        privacyScore: 100,
        isSystemApp: false,
        installSource: 'Unknown',
        declaresAccessibilityService: true,
        requestsOverlayPermission: true,
        declaresDeviceAdmin: true,
        hiddenLauncher: true,
        fakeSystemRisk: true,
        runsAtBoot: true,
        contactsInternetCombo: true,
        smsCallInternetCombo: true,
        hasSmsAccess: true,
        hasInternetAccess: true,
      );

      final enriched = PermissionAnalyzer.enrichAppInfo(hostileApp);
      expect(enriched.privacyScore, greaterThanOrEqualTo(0));
      expect(enriched.privacyScore, lessThanOrEqualTo(100));
      expect(enriched.riskLevel, equals(RiskLevel.critical));
      expect(enriched.malwareIndicators, isNotEmpty);
    });

    test('calculatePrivacyScore matches enrichAppInfo privacy score', () {
      final perms = [
        'android.permission.CAMERA',
        'android.permission.RECORD_AUDIO',
        'android.permission.ACCESS_FINE_LOCATION',
      ];

      final directScore = PermissionAnalyzer.calculatePrivacyScore(perms);
      final enrichedApp = PermissionAnalyzer.enrichAppInfo(
        AppInfo(
          packageName: 'com.test',
          appName: 'Test',
          permissions: perms,
          riskLevel: RiskLevel.safe,
          dangerousPermissionCount: 3,
          privacyScore: 100,
          isSystemApp: false,
          installSource: 'Unknown',
        ),
      );

      expect(directScore, equals(enrichedApp.privacyScore));
    });

    test('riskLevelForScore adheres to exact scoring tiers', () {
      expect(PermissionAnalyzer.riskLevelForScore(100), equals(RiskLevel.safe));
      expect(PermissionAnalyzer.riskLevelForScore(80), equals(RiskLevel.safe));
      expect(
        PermissionAnalyzer.riskLevelForScore(79),
        equals(RiskLevel.medium),
      );
      expect(
        PermissionAnalyzer.riskLevelForScore(60),
        equals(RiskLevel.medium),
      );
      expect(PermissionAnalyzer.riskLevelForScore(59), equals(RiskLevel.high));
      expect(PermissionAnalyzer.riskLevelForScore(35), equals(RiskLevel.high));
      expect(
        PermissionAnalyzer.riskLevelForScore(34),
        equals(RiskLevel.critical),
      );
      expect(
        PermissionAnalyzer.riskLevelForScore(0),
        equals(RiskLevel.critical),
      );
    });

    test(
      'Handles unknown and manufacturer-specific permissions gracefully without crashing',
      () {
        final app = AppInfo(
          packageName: 'com.custom.app',
          appName: 'Vendor Specific',
          permissions: const [
            'com.huawei.permission.PUSH',
            'com.samsung.android.permission.SSENSOR',
            'com.xiaomi.permission.CUSTOM_SENSOR',
            'unknown.unrecognized.PERMISSION_ABC',
          ],
          riskLevel: RiskLevel.safe,
          dangerousPermissionCount: 0,
          privacyScore: 100,
          isSystemApp: false,
          installSource: 'Play Store',
        );

        final enriched = PermissionAnalyzer.enrichAppInfo(app);
        expect(enriched.privacyScore, inInclusiveRange(0, 100));
        expect(enriched.riskLevel, equals(RiskLevel.safe));
      },
    );
  });
}
