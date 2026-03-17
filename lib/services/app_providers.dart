import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/services/permission_scanner_service.dart';
import 'package:permission_scanner/services/permission_analyzer.dart';

final permissionScannerServiceProvider = Provider((_) {
  return PermissionScannerService();
});

final installedAppsProvider = FutureProvider<List<AppInfo>>((ref) async {
  final service = ref.watch(permissionScannerServiceProvider);
  final apps = await service.getInstalledApps();
  return apps.map((app) => PermissionAnalyzer.enrichAppInfo(app)).toList();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredAppsProvider = FutureProvider<List<AppInfo>>((ref) async {
  final apps = await ref.watch(installedAppsProvider.future);
  final query = ref.watch(searchQueryProvider);

  if (query.isEmpty) {
    return apps;
  }

  final lowerQuery = query.toLowerCase();
  return apps
      .where(
        (app) =>
            app.appName.toLowerCase().contains(lowerQuery) ||
            app.packageName.toLowerCase().contains(lowerQuery),
      )
      .toList();
});

final selectedAppProvider = StateProvider<AppInfo?>((ref) => null);

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final apps = await ref.watch(installedAppsProvider.future);

  int safeCount = 0;
  int mediumCount = 0;
  int dangerousCount = 0;
  int totalDangerousPermissions = 0;

  for (final app in apps) {
    switch (app.riskLevel) {
      case RiskLevel.safe:
        safeCount++;
        break;
      case RiskLevel.medium:
        mediumCount++;
        break;
      case RiskLevel.dangerous:
        dangerousCount++;
        break;
    }
    totalDangerousPermissions += app.dangerousPermissionCount;
  }

  return DashboardStats(
    totalApps: apps.length,
    safeApps: safeCount,
    mediumApps: mediumCount,
    dangerousApps: dangerousCount,
    totalDangerousPermissions: totalDangerousPermissions,
  );
});

class DashboardStats {
  final int totalApps;
  final int safeApps;
  final int mediumApps;
  final int dangerousApps;
  final int totalDangerousPermissions;

  DashboardStats({
    required this.totalApps,
    required this.safeApps,
    required this.mediumApps,
    required this.dangerousApps,
    required this.totalDangerousPermissions,
  });
}
