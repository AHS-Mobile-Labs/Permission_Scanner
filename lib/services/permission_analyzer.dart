import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/utils/permission_database.dart';

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
    );
  }
}
