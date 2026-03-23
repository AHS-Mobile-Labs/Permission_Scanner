import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/utils/permission_database.dart';
import 'package:permission_scanner/services/permission_justification_service.dart';

class PermissionAnalyzer {
  static RiskLevel analyzeRiskLevel(int dangerousPermissionCount) {
    if (dangerousPermissionCount == 0) return RiskLevel.safe;
    if (dangerousPermissionCount <= 3) return RiskLevel.medium;
    return RiskLevel.dangerous;
  }

  static int calculatePrivacyScore(List<String> permissions) {
    int score = 100;
    for (final permission in permissions) {
      if (dangerousPermissions.contains(permission)) {
        score -= 10;
      }
    }
    return score.clamp(0, 100);
  }

  static int countDangerousPermissions(List<String> permissions) {
    return permissions.where((p) => dangerousPermissions.contains(p)).length;
  }

  static AppInfo enrichAppInfo(AppInfo baseInfo) {
    final dangerousCount = countDangerousPermissions(baseInfo.permissions);
    final privacyScore = calculatePrivacyScore(baseInfo.permissions);
    final riskLevel = analyzeRiskLevel(dangerousCount);

    return AppInfo(
      packageName: baseInfo.packageName,
      appName: baseInfo.appName,
      iconPath: baseInfo.iconPath,
      permissions: baseInfo.permissions,
      riskLevel: riskLevel,
      dangerousPermissionCount: dangerousCount,
      privacyScore: privacyScore,
      isSystemApp: baseInfo.isSystemApp,
      installSource: baseInfo.installSource,
    );
  }

  /// Analyze permissions with justification scoring
  static Map<String, dynamic> analyzeWithJustification(
    AppInfo app,
    List<String> appCapabilities,
  ) {
    final analysis = PermissionJustificationService.analyzePermissions(
      app.permissions,
      appCapabilities,
    );

    // Calculate adjusted risk level based on justified permissions
    final justifiedPercentage = app.permissions.isEmpty
        ? 0
        : (analysis['justifiedCount'] as int) / app.permissions.length * 100;

    // If most permissions are justified, reduce risk slightly
    final adjustedRisk = justifiedPercentage > 80
        ? _reduceRiskLevel(app.riskLevel)
        : app.riskLevel;

    return {
      'originalRisk': app.riskLevel,
      'adjustedRisk': adjustedRisk,
      'justifiedPercentage': justifiedPercentage.toStringAsFixed(1),
      'analysis': analysis,
    };
  }

  static RiskLevel _reduceRiskLevel(RiskLevel level) {
    if (level == RiskLevel.dangerous) return RiskLevel.medium;
    if (level == RiskLevel.medium) return RiskLevel.safe;
    return RiskLevel.safe;
  }
}
