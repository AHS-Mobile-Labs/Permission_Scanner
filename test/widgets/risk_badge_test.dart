import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/utils/app_colors.dart';
import 'package:permission_scanner/widgets/risk_badge.dart';

void main() {
  group('RiskBadge Widget Tests', () {
    testWidgets('renders Safe risk badge correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskBadge(riskLevel: RiskLevel.safe),
          ),
        ),
      );

      expect(find.text('Safe'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      final text = tester.widget<Text>(find.text('Safe'));
      expect(text.style?.color, equals(AppColors.riskSafe));
    });

    testWidgets('renders Medium risk badge correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskBadge(riskLevel: RiskLevel.medium),
          ),
        ),
      );

      expect(find.text('Medium Risk'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      final text = tester.widget<Text>(find.text('Medium Risk'));
      expect(text.style?.color, equals(AppColors.riskMedium));
    });

    testWidgets('renders High risk badge correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskBadge(riskLevel: RiskLevel.high),
          ),
        ),
      );

      expect(find.text('High Risk'), findsOneWidget);
      expect(find.byIcon(Icons.error_rounded), findsOneWidget);

      final text = tester.widget<Text>(find.text('High Risk'));
      expect(text.style?.color, equals(AppColors.riskDangerous));
    });

    testWidgets('renders Critical risk badge correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskBadge(riskLevel: RiskLevel.critical),
          ),
        ),
      );

      expect(find.text('Critical'), findsOneWidget);
      expect(find.byIcon(Icons.gpp_bad_rounded), findsOneWidget);

      final text = tester.widget<Text>(find.text('Critical'));
      expect(text.style?.color, equals(AppColors.riskCritical));
    });

    testWidgets('renders compact version with smaller padding and font size', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskBadge(riskLevel: RiskLevel.safe, compact: true),
          ),
        ),
      );

      expect(find.text('Safe'), findsOneWidget);
      final text = tester.widget<Text>(find.text('Safe'));
      expect(text.style?.fontSize, equals(10));
    });
  });
}
