import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/widgets/app_card.dart';

void main() {
  group('AppCard Widget Tests', () {
    testWidgets('renders app details and responds to taps', (tester) async {
      bool tapped = false;
      final testApp = AppInfo(
        packageName: 'com.example.secureapp',
        appName: 'Secure Test App',
        permissions: const [
          'android.permission.CAMERA',
          'android.permission.RECORD_AUDIO',
        ],
        riskLevel: RiskLevel.medium,
        dangerousPermissionCount: 2,
        privacyScore: 78,
        isSystemApp: false,
        installSource: 'Play Store',
        trackers: const [
          TrackerInfo(
            id: 'admob',
            name: 'Google AdMob',
            category: 'Ads',
            purpose: 'Advertising',
            riskWeight: 3,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              app: testApp,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Secure Test App'), findsOneWidget);
      expect(find.text('com.example.secureapp'), findsOneWidget);
      expect(find.text('78/100'), findsOneWidget);
      expect(find.text('Medium Risk'), findsOneWidget);
      expect(find.text('1 tracker SDKs'), findsOneWidget);

      await tester.tap(find.byType(AppCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('renders without tracker info when trackers list is empty', (
      tester,
    ) async {
      final testApp = AppInfo(
        packageName: 'com.example.clean',
        appName: 'Clean App',
        permissions: const ['android.permission.CAMERA'],
        riskLevel: RiskLevel.safe,
        dangerousPermissionCount: 0,
        privacyScore: 95,
        isSystemApp: false,
        installSource: 'Play Store',
        trackers: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              app: testApp,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Clean App'), findsOneWidget);
      expect(find.text('95/100'), findsOneWidget);
      expect(find.text('Safe'), findsOneWidget);
      expect(find.byIcon(Icons.radar_rounded), findsNothing);
    });
  });
}
