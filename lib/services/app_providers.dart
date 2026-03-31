import 'package:flutter/foundation.dart';
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

/// Enriches a list of apps on a background isolate using [compute].
/// This prevents the heavy permission-analysis work from blocking the UI.
List<AppInfo> _enrichAppsInBackground(List<AppInfo> apps) {
  return apps.map((app) => PermissionAnalyzer.enrichAppInfo(app)).toList();
}

/// Main provider for the installed-apps list.
///
/// Strategy:
/// 1. Return cached apps immediately so the UI renders instantly.
/// 2. In the background, check whether the installed-app fingerprint has
///    changed (apps installed / uninstalled / updated).
/// 3. Only perform a full native re-scan + enrichment when the fingerprint
///    differs from the cached one, then update the cache.
/// 4. If no cache exists yet, do the full scan synchronously (first launch).
final installedAppsProvider =
    AsyncNotifierProvider<InstalledAppsNotifier, List<AppInfo>>(
      InstalledAppsNotifier.new,
    );

class InstalledAppsNotifier extends AsyncNotifier<List<AppInfo>> {
  @override
  Future<List<AppInfo>> build() async {
    final cacheService = ref.watch(cacheServiceProvider);
    final service = ref.watch(permissionScannerServiceProvider);

    await cacheService.init();

    // ── Fast path: return cache while validating in background ─────
    final cachedApps = cacheService.getCachedApps();
    if (cachedApps.isNotEmpty) {
      // Schedule background refresh without blocking the UI
      Future.microtask(() => _refreshIfChanged(service, cacheService));
      return cachedApps;
    }

    // ── Cold start: no cache, must scan now ───────────────────────
    return _performFullScan(service, cacheService);
  }

  Future<List<AppInfo>> _performFullScan(
    PermissionScannerService service,
    CacheService cacheService,
  ) async {
    final apps = await service.getInstalledApps();
    final enrichedApps = await compute(_enrichAppsInBackground, apps);

    // Persist enriched apps + fingerprint
    await cacheService.saveApps(enrichedApps);
    final fingerprint = await service.getAppsFingerprint();
    if (fingerprint.isNotEmpty) {
      await cacheService.saveFingerprint(fingerprint);
    }

    return enrichedApps;
  }

  /// Checks the fingerprint and only re-scans if installed apps have changed.
  Future<void> _refreshIfChanged(
    PermissionScannerService service,
    CacheService cacheService,
  ) async {
    try {
      final fingerprint = await service.getAppsFingerprint();
      if (fingerprint.isEmpty || !cacheService.hasAppsChanged(fingerprint)) {
        return; // Nothing changed — skip expensive scan
      }

      final freshApps = await service.getInstalledApps();
      final enrichedApps = await compute(_enrichAppsInBackground, freshApps);

      await cacheService.saveApps(enrichedApps);
      await cacheService.saveFingerprint(fingerprint);

      // Push updated list to listeners
      state = AsyncData(enrichedApps);
    } catch (e) {
      print('Error refreshing app cache: $e');
    }
  }

  /// Force a full re-scan (e.g. pull-to-refresh).
  Future<void> forceRefresh() async {
    final cacheService = ref.read(cacheServiceProvider);
    final service = ref.read(permissionScannerServiceProvider);
    await cacheService.init();
    state = const AsyncLoading();
    state = AsyncData(await _performFullScan(service, cacheService));
  }
}

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

  List<AppInfo> filtered = apps;

  // Search filter
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
  //  - userApps: NOT system AND installer is a known trusted store
  //  - systemApps: FLAG_SYSTEM or FLAG_UPDATED_SYSTEM_APP (isSystemApp == true)
  //  - unknownSource: NOT system AND installer is missing / not trusted
  if (appType == AppType.userApps) {
    filtered = filtered
        .where(
          (app) =>
              !app.isSystemApp &&
              app.installSource != 'Unknown' &&
              app.installSource != 'System',
        )
        .toList();
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

  // Sorting
  if (filtered.length > 1) {
    switch (sortOption) {
      case SortOption.name:
        filtered.sort((a, b) => a.appName.compareTo(b.appName));
        break;
      case SortOption.risk:
        filtered.sort((a, b) {
          const riskOrder = {
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
