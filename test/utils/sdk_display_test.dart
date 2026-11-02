import 'package:flutter_test/flutter_test.dart';
import 'package:permission_scanner/utils/sdk_display.dart';

void main() {
  group('SdkDisplay Utility Tests', () {
    test('apiValue formats known Android versions accurately', () {
      expect(SdkDisplay.apiValue(34), equals('API 34 · Android 14'));
      expect(SdkDisplay.apiValue(35), equals('API 35 · Android 15'));
      expect(SdkDisplay.apiValue(36), equals('API 36 · Android 16'));
      expect(SdkDisplay.apiValue(21), equals('API 21 · Android 5.0 Lollipop'));
    });

    test('apiValue handles unknown or invalid API numbers gracefully', () {
      expect(SdkDisplay.apiValue(0), equals('Unknown'));
      expect(SdkDisplay.apiValue(-1), equals('Unknown'));
      expect(SdkDisplay.apiValue(99), equals('API 99'));
    });

    test('compactApiValue returns concise API string', () {
      expect(SdkDisplay.compactApiValue(34), equals('API 34'));
      expect(SdkDisplay.compactApiValue(0), equals('Unknown'));
    });

    test('targetPosture classifies API bands correctly', () {
      expect(SdkDisplay.targetPosture(35), equals('Modern target'));
      expect(SdkDisplay.targetPosture(36), equals('Modern target'));
      expect(SdkDisplay.targetPosture(34), equals('Recent target'));
      expect(SdkDisplay.targetPosture(33), equals('Recent target'));
      expect(SdkDisplay.targetPosture(30), equals('Older target'));
      expect(SdkDisplay.targetPosture(26), equals('Legacy target'));
      expect(SdkDisplay.targetPosture(0), equals('Unknown target'));
    });

    test('compileValue formats codename and API properly', () {
      expect(
        SdkDisplay.compileValue(35, 'REL'),
        equals('API 35 · Android 15'),
      );
      expect(SdkDisplay.compileValue(0, ''), equals('Unavailable'));
      expect(SdkDisplay.compileValue(0, 'UpsideDownCake'), equals('UpsideDownCake'));
    });
  });
}
