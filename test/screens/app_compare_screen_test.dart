import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/screens/app_compare_screen.dart';
import 'package:permission_scanner/services/app_providers.dart';

class FakeEmptyAppsNotifier extends InstalledAppsNotifier {
  @override
  Future<List<AppInfo>> build() async => [];
}

class FakePopulatedAppsNotifier extends InstalledAppsNotifier {
  final List<AppInfo> apps;
  FakePopulatedAppsNotifier(this.apps);

  @override
  Future<List<AppInfo>> build() async => apps;
}

void main() {
  testWidgets(
    'AppCompareScreen displays Scaffold with AppBar and themed empty state',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            installedAppsProvider.overrideWith(FakeEmptyAppsNotifier.new),
          ],
          child: const MaterialApp(home: AppCompareScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Compare Apps'), findsOneWidget);
      expect(find.text('No apps available to compare'), findsOneWidget);
    },
  );

  testWidgets(
    'AppCompareScreen displays compare view when apps are available',
    (tester) async {
      final mockApps = [
        AppInfo(
          packageName: 'com.example.app1',
          appName: 'Alpha App',
          permissions: ['android.permission.CAMERA'],
          riskLevel: RiskLevel.safe,
          dangerousPermissionCount: 0,
          privacyScore: 88,
          isSystemApp: false,
          installSource: 'Play Store',
        ),
        AppInfo(
          packageName: 'com.example.app2',
          appName: 'Beta App',
          permissions: ['android.permission.RECORD_AUDIO'],
          riskLevel: RiskLevel.medium,
          dangerousPermissionCount: 1,
          privacyScore: 72,
          isSystemApp: false,
          installSource: 'Play Store',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            installedAppsProvider.overrideWith(
              () => FakePopulatedAppsNotifier(mockApps),
            ),
          ],
          child: const MaterialApp(home: AppCompareScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Compare Apps'), findsOneWidget);
      expect(find.text('Alpha App'), findsWidgets);
      expect(find.text('Beta App'), findsWidgets);
    },
  );
}
