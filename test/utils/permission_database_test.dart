import 'package:flutter_test/flutter_test.dart';
import 'package:permission_scanner/utils/permission_database.dart';

void main() {
  group('PermissionDatabase Utility Tests', () {
    test('Contains core dangerous permissions', () {
      expect(dangerousPermissions, contains('android.permission.CAMERA'));
      expect(dangerousPermissions, contains('android.permission.RECORD_AUDIO'));
      expect(
        dangerousPermissions,
        contains('android.permission.ACCESS_FINE_LOCATION'),
      );
      expect(dangerousPermissions, contains('android.permission.READ_SMS'));
      expect(
        dangerousPermissions,
        contains('android.permission.READ_CONTACTS'),
      );
      expect(
        dangerousPermissions,
        contains('android.permission.READ_CALL_LOG'),
      );
      expect(
        dangerousPermissions,
        contains('android.permission.MANAGE_EXTERNAL_STORAGE'),
      );
    });

    test('Contains modern Android 13/14 permissions', () {
      expect(
        permissionDatabase.containsKey(
          'android.permission.NEARBY_WIFI_DEVICES',
        ),
        isTrue,
      );
      expect(
        permissionDatabase.containsKey(
          'android.permission.BODY_SENSORS_BACKGROUND',
        ),
        isTrue,
      );
      expect(
        permissionDatabase.containsKey(
          'android.permission.READ_BASIC_PHONE_STATE',
        ),
        isTrue,
      );
      expect(
        permissionDatabase.containsKey(
          'android.permission.DETECT_SCREEN_CAPTURE',
        ),
        isTrue,
      );
      expect(
        permissionDatabase.containsKey('android.permission.USE_BIOMETRIC'),
        isTrue,
      );
    });

    test(
      'getPermissionDetails returns accurate metadata for known permissions',
      () {
        final cameraDetails = getPermissionDetails('android.permission.CAMERA');
        expect(cameraDetails.displayName, equals('Camera'));
        expect(cameraDetails.isDangerous, isTrue);
        expect(cameraDetails.description.toLowerCase(), contains('camera'));
      },
    );

    test(
      'getPermissionDetails provides intelligent fallback for unknown vendor permissions',
      () {
        final vendorDetails = getPermissionDetails(
          'com.samsung.accessory.permission.ACCESSORY_FRAMEWORK',
        );
        expect(vendorDetails.displayName, equals('Accessory Framework'));
        expect(vendorDetails.isDangerous, isFalse);
        expect(vendorDetails.group, equals('System'));

        final customDetails = getPermissionDetails(
          'com.custom.VENDOR_SENSOR_DATA',
        );
        expect(customDetails.displayName, equals('Vendor Sensor Data'));
      },
    );

    test(
      'formatPermissionName properly parses and formats permission strings',
      () {
        expect(
          formatPermissionName('android.permission.ACCESS_FINE_LOCATION'),
          equals('Access Fine Location'),
        );
        expect(
          formatPermissionName('com.example.CUSTOM_HEALTH_READ'),
          equals('Custom Health Read'),
        );
        expect(
          formatPermissionName('SIMPLE_PERMISSION'),
          equals('Simple Permission'),
        );
      },
    );
  });
}
