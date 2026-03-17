import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/models/permission_justification.dart';
import 'package:permission_scanner/services/permission_scanner_service.dart';
import 'package:permission_scanner/services/permission_analyzer.dart';

enum SortOption {
  nameAsc,
  nameDesc,
  riskHigh,
  riskLow,
  privacyHigh,
  privacyLow,
}

enum PermissionFilter { all, dangerous, medium, safe }

final permissionScannerServiceProvider = Provider((_) {
  return PermissionScannerService();
});

final installedAppsProvider = FutureProvider<List<AppInfo>>((ref) async {
  final service = ref.watch(permissionScannerServiceProvider);
  final apps = await service.getInstalledApps();
  return apps.map((app) => PermissionAnalyzer.enrichAppInfo(app)).toList();
});

final searchQueryProvider = StateProvider<String>((ref) => '');
final sortOptionProvider = StateProvider<SortOption>(
  (ref) => SortOption.nameAsc,
);
final riskFilterProvider = StateProvider<PermissionFilter>(
  (ref) => PermissionFilter.all,
);
final permissionFilterProvider = StateProvider<String?>((ref) => null);

final filteredAppsProvider = FutureProvider<List<AppInfo>>((ref) async {
  final apps = await ref.watch(installedAppsProvider.future);
  var query = ref.watch(searchQueryProvider);
  final sortOption = ref.watch(sortOptionProvider);
  final riskFilter = ref.watch(riskFilterProvider);
  final permissionFilter = ref.watch(permissionFilterProvider);

  // Search filter
  var filtered = apps;
  if (query.isNotEmpty) {
    final lowerQuery = query.toLowerCase();
    filtered = filtered
        .where(
          (app) =>
              app.appName.toLowerCase().contains(lowerQuery) ||
              app.packageName.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  // Risk filter
  if (riskFilter != PermissionFilter.all) {
    filtered = filtered.where((app) {
      switch (riskFilter) {
        case PermissionFilter.dangerous:
          return app.riskLevel == RiskLevel.dangerous;
        case PermissionFilter.medium:
          return app.riskLevel == RiskLevel.medium;
        case PermissionFilter.safe:
          return app.riskLevel == RiskLevel.safe;
        default:
          return true;
      }
    }).toList();
  }

  // Permission filter
  if (permissionFilter != null && permissionFilter.isNotEmpty) {
    filtered = filtered
        .where((app) => app.permissions.contains(permissionFilter))
        .toList();
  }

  // Sorting
  switch (sortOption) {
    case SortOption.nameAsc:
      filtered.sort((a, b) => a.appName.compareTo(b.appName));
      break;
    case SortOption.nameDesc:
      filtered.sort((a, b) => b.appName.compareTo(a.appName));
      break;
    case SortOption.riskHigh:
      filtered.sort((a, b) {
        final riskOrder = {
          RiskLevel.dangerous: 0,
          RiskLevel.medium: 1,
          RiskLevel.safe: 2,
        };
        return (riskOrder[a.riskLevel] ?? 3).compareTo(
          riskOrder[b.riskLevel] ?? 3,
        );
      });
      break;
    case SortOption.riskLow:
      filtered.sort((a, b) {
        final riskOrder = {
          RiskLevel.safe: 0,
          RiskLevel.medium: 1,
          RiskLevel.dangerous: 2,
        };
        return (riskOrder[a.riskLevel] ?? 3).compareTo(
          riskOrder[b.riskLevel] ?? 3,
        );
      });
      break;
    case SortOption.privacyHigh:
      filtered.sort((a, b) => b.privacyScore.compareTo(a.privacyScore));
      break;
    case SortOption.privacyLow:
      filtered.sort((a, b) => a.privacyScore.compareTo(b.privacyScore));
      break;
  }

  return filtered;
});

final selectedAppProvider = StateProvider<AppInfo?>((ref) => null);

final appCapabilitiesProvider = StateProvider<Map<String, List<String>>>(
  (ref) => {},
);

final permissionHistoryProvider =
    FutureProvider.family<List<PermissionHistory>, String>((
      ref,
      packageName,
    ) async {
      // This will be populated from CacheService
      return [];
    });

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
