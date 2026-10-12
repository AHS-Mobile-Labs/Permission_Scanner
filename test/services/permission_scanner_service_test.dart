import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_scanner/services/permission_scanner_service.dart';

void main() {
  group('PermissionScannerService JSON Parsing Tests', () {
    test('parseAppsFromJson parses valid JSON with multiple apps', () {
      final jsonPayload = jsonEncode({
        'apps': [
          {
            'packageName': 'com.test.app1',
            'appName': 'App One',
            'permissions': ['android.permission.INTERNET'],
            'isSystemApp': false,
            'installSource': 'Play Store',
          },
          {
            'packageName': 'com.test.app2',
            'appName': 'App Two',
            'permissions': ['android.permission.CAMERA'],
            'isSystemApp': true,
            'installSource': 'System',
          },
        ],
      });

      final apps = parseAppsFromJson(jsonPayload);
      expect(apps.length, equals(2));
      expect(apps[0].packageName, equals('com.test.app1'));
      expect(apps[0].appName, equals('App One'));
      expect(apps[0].isSystemApp, isFalse);
      expect(apps[1].packageName, equals('com.test.app2'));
      expect(apps[1].isSystemApp, isTrue);
    });

    test('parseAppsFromJson handles empty or missing apps key', () {
      expect(parseAppsFromJson('{}'), isEmpty);
      expect(parseAppsFromJson('{"apps": []}'), isEmpty);
      expect(parseAppsFromJson('{"apps": null}'), isEmpty);
    });

    test(
      'parseAppsFromJson gracefully skips corrupted app entries without failing the batch',
      () {
        final mixedPayload = jsonEncode({
          'apps': [
            {
              'packageName': 'com.valid.app',
              'appName': 'Valid App',
              'permissions': [],
            },
            // Corrupt object: package name is missing or has incorrect type
            {'unexpectedField': 12345},
            {
              'packageName': 'com.valid.second',
              'appName': 'Valid Second',
              'permissions': ['android.permission.RECORD_AUDIO'],
            },
          ],
        });

        final apps = parseAppsFromJson(mixedPayload);
        expect(apps.length, greaterThanOrEqualTo(2));
        expect(apps.any((a) => a.packageName == 'com.valid.app'), isTrue);
        expect(apps.any((a) => a.packageName == 'com.valid.second'), isTrue);
      },
    );

    test('parseAppsFromJson returns empty list on invalid JSON string', () {
      expect(parseAppsFromJson('not a json string'), isEmpty);
      expect(parseAppsFromJson(''), isEmpty);
    });
  });
}
