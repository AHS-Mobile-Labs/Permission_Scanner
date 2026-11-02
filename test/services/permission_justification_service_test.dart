import 'package:flutter_test/flutter_test.dart';
import 'package:permission_scanner/services/permission_justification_service.dart';

void main() {
  group('PermissionJustificationService Tests', () {
    test('getAllCapabilities returns non-empty list of standard capabilities', () {
      final capabilities = PermissionJustificationService.getAllCapabilities();
      expect(capabilities, contains('Take Photos'));
      expect(capabilities, contains('Access Location'));
      expect(capabilities, contains('Record Audio'));
    });

    test('getPermissionsForCapability returns associated permissions', () {
      expect(
        PermissionJustificationService.getPermissionsForCapability('Take Photos'),
        contains('android.permission.CAMERA'),
      );
      expect(
        PermissionJustificationService.getPermissionsForCapability('Nonexistent'),
        isEmpty,
      );
    });

    test('matchCapabilitiesToPermissions matches declared permissions correctly', () {
      final permissions = [
        'android.permission.CAMERA',
        'android.permission.ACCESS_FINE_LOCATION',
        'android.permission.ACCESS_COARSE_LOCATION',
      ];
      final matched = PermissionJustificationService.matchCapabilitiesToPermissions(permissions);
      expect(matched, contains('Take Photos'));
      expect(matched, contains('Access Location'));
    });

    test('isPermissionJustified checks capability justification properly', () {
      expect(
        PermissionJustificationService.isPermissionJustified(
          'android.permission.CAMERA',
          ['Take Photos'],
        ),
        isTrue,
      );
      expect(
        PermissionJustificationService.isPermissionJustified(
          'android.permission.ACCESS_FINE_LOCATION',
          ['Take Photos'],
        ),
        isFalse,
      );
    });

    test('analyzePermissions generates complete breakdown and percentages', () {
      final permissions = [
        'android.permission.CAMERA',
        'android.permission.SEND_SMS',
      ];
      final capabilities = ['Take Photos'];

      final analysis = PermissionJustificationService.analyzePermissions(
        permissions,
        capabilities,
      );

      expect(analysis['justifiedCount'], equals(1));
      expect(analysis['unjustifiedCount'], equals(1));
      expect(analysis['justifiedPermissions'], contains('android.permission.CAMERA'));
      expect(analysis['unjustifiedPermissions'], contains('android.permission.SEND_SMS'));
      expect(analysis['justificationPercentage'], equals('50.0'));
    });
  });
}
