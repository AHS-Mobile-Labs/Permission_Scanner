import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/models/permission_justification.dart';
import 'package:permission_scanner/services/permission_scanner_service.dart';
import 'package:permission_scanner/services/permission_analyzer.dart';
import 'package:permission_scanner/services/cache_service.dart';

enum SortOption { name, risk }

enum AppType { userApps, systemApps, unknownSource }

final permissionScannerServiceProvider = Provider((_) {
  return PermissionScannerService();
});

final cacheServiceProvider = Provider((_) {
  return CacheService();
});

final installedAppsProvider = FutureProvider<List<AppInfo>>((ref) async {
  final cacheService = ref.watch(cacheServiceProvider);
  final service = ref.watch(permissionScannerServiceProvider);

  // Try to get cached apps first for instant display
  final cachedApps = cacheService.getCachedApps();
  if (cachedApps.isNotEmpty) {
    // Return cached apps while fetching fresh data in background
    Future.microtask(() async {
      try {
        final freshApps = await service.getInstalledApps();
        final enrichedApps = freshApps
            .map((app) => PermissionAnalyzer.enrichAppInfo(app))
            .toList();
        await cacheService.saveApps(enrichedApps);
      } catch (e) {
        print('Error updating app cache: $e');
      }
    });
    return cachedApps;
  }

  // No cache, fetch from native
  final apps = await service.getInstalledApps();
  final enrichedApps = apps
      .map((app) => PermissionAnalyzer.enrichAppInfo(app))
      .toList();

  // Cache the results
  await cacheService.saveApps(enrichedApps);

  return enrichedApps;
});

final searchQueryProvider = StateProvider<String>((ref) => '');
final sortOptionProvider = StateProvider<SortOption>((ref) => SortOption.name);
final appTypeProvider = StateProvider<AppType>((ref) => AppType.userApps);
final permissionFilterProvider = StateProvider<String?>((ref) => null);

final filteredAppsProvider = FutureProvider<List<AppInfo>>((ref) async {
  final apps = await ref.watch(installedAppsProvider.future);
  final query = ref.watch(searchQueryProvider);
  final sortOption = ref.watch(sortOptionProvider);
  final appType = ref.watch(appTypeProvider);
  final permissionFilter = ref.watch(permissionFilterProvider);

  // Start with all apps
  List<AppInfo> filtered = apps;

  // Search filter - only if query is not empty
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

  // App type filter
  if (appType == AppType.userApps) {
    filtered = filtered.where((app) => !app.isSystemApp).toList();
  } else if (appType == AppType.systemApps) {
    filtered = filtered.where((app) => app.isSystemApp).toList();
  } else if (appType == AppType.unknownSource) {
    filtered = filtered
        .where((app) => !app.isSystemApp && app.installSource == 'Unknown')
        .toList();
  }

  // Permission filter
  if (permissionFilter != null && permissionFilter.isNotEmpty) {
    filtered = filtered
        .where((app) => app.permissions.contains(permissionFilter))
        .toList();
  }

  // Sorting - optimized with early return for single item
  if (filtered.length > 1) {
    switch (sortOption) {
      case SortOption.name:
        filtered.sort((a, b) => a.appName.compareTo(b.appName));
        break;
      case SortOption.risk:
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
    }
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
    totalDangerousPermissions += (app.dangerousPermissionCount as int? ?? 0);
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
