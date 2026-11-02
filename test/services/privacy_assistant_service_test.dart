import 'package:flutter_test/flutter_test.dart';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/services/privacy_assistant_service.dart';

void main() {
  group('PrivacyAssistantService Tests', () {
    final testApp = AppInfo(
      packageName: 'com.example.chat',
      appName: 'Chat App',
      permissions: const [
        'android.permission.CAMERA',
        'android.permission.RECORD_AUDIO',
        'android.permission.ACCESS_FINE_LOCATION',
        'android.permission.READ_CONTACTS',
      ],
      riskLevel: RiskLevel.medium,
      dangerousPermissionCount: 4,
      privacyScore: 65,
      isSystemApp: false,
      installSource: 'Play Store',
      trackers: const [
        TrackerInfo(
          id: 'admob',
          name: 'Google AdMob',
          category: 'Advertising',
          purpose: 'Ad delivery',
          riskWeight: 4,
        ),
      ],
    );

    test('answerQuestion responds appropriately to microphone inquiries', () {
      final answer = PrivacyAssistantService.answerQuestion(testApp, 'does it use microphone?');
      expect(answer.toLowerCase(), contains('microphone'));
    });

    test('answerQuestion responds appropriately to camera inquiries', () {
      final answer = PrivacyAssistantService.answerQuestion(testApp, 'does it use camera?');
      expect(answer.toLowerCase(), contains('camera'));
    });

    test('answerQuestion explains tracker details when asked', () {
      final answer = PrivacyAssistantService.answerQuestion(testApp, 'are there any trackers?');
      expect(answer, contains('Google AdMob'));
    });

    test('recommendations returns actionable advice based on app risk profile', () {
      final recs = PrivacyAssistantService.recommendations(testApp);
      expect(recs, isNotEmpty);
      expect(recs.any((r) => r.contains('disable permissions') || r.contains('permissions')), isTrue);
    });

    test('buildPlainLanguageSummary includes app name, score, and risk level', () {
      final summary = PrivacyAssistantService.buildPlainLanguageSummary(testApp);
      expect(summary, contains('Chat App'));
      expect(summary, contains('65/100'));
      expect(summary, contains('Medium Risk'));
    });

    test('buildDeviceShareSummary formats multi-app summary', () {
      final summary = PrivacyAssistantService.buildDeviceShareSummary([testApp]);
      expect(summary, contains('Permission Scanner'));
      expect(summary, contains('Apps scanned: 1'));
      expect(summary, contains('Device score: 65/100'));
    });
  });
}
