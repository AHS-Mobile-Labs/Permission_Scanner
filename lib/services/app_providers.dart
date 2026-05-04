import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/models/permission_justification.dart';
import 'package:permission_scanner/services/permission_scanner_service.dart';
import 'package:permission_scanner/services/permission_analyzer.dart';
import 'package:permission_scanner/services/cache_service.dart';
import 'package:permission_scanner/utils/permission_database.dart';
import 'dart:async';

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
      // Don't await this - let it run independently
      unawaited(_refreshIfChanged(service, cacheService));
      return cachedApps;
    }

    // ── Cold start: no cache, return basic apps immediately ────────
    // Return unrich apps immediately, then enrich in background
    // This prevents the 10-second freeze on first launch
    try {
      final apps = await service.getInstalledApps();
      if (apps.isEmpty) return [];

      // Don't await enrichment - start caching in background
      unawaited(_enrichAndCache(apps, service, cacheService));

      // Return unenriched apps immediately for fast UI rendering
      return apps;
    } catch (e) {
      print('Error fetching apps on cold start: $e');
      return [];
    }
  }

  /// Enriches apps in the background and updates cache
  Future<void> _enrichAndCache(
    List<AppInfo> apps,
    PermissionScannerService service,
    CacheService cacheService,
  ) async {
    try {
      // Get fingerprint
      final fingerprint = await service.getAppsFingerprint();

      // Enrich on background isolate to avoid blocking
      final enrichedApps = await compute(_enrichAppsInBackground, apps);

      // Update cache
      await cacheService.saveApps(enrichedApps);
      if (fingerprint.isNotEmpty) {
        await cacheService.saveFingerprint(fingerprint);
      }

      // Update state with enriched apps
      state = AsyncData(enrichedApps);
    } catch (e) {
      print('Error enriching apps: $e');
      // Keep the unenriched apps - don't fail
    }
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

  /// Force a re-scan with smart fingerprint checking to avoid unnecessary work.
  /// Runs heavy operations off the main thread to prevent UI freezing.
  /// Returns a Future that completes when the refresh is done.
  Future<void> forceRefresh() async {
    final cacheService = ref.read(cacheServiceProvider);
    final service = ref.read(permissionScannerServiceProvider);
    await cacheService.init();

    try {
      // Immediately set loading state so UI shows progress
      state = const AsyncLoading();

      // Yield to the event loop to let UI update before heavy work
      await Future.delayed(Duration.zero);

      // Check fingerprint first - only rescan if apps changed
      final fingerprint = await service.getAppsFingerprint();
      if (fingerprint.isNotEmpty && !cacheService.hasAppsChanged(fingerprint)) {
        // No changes detected - just return cached data
        final cachedApps = cacheService.getCachedApps();
        if (cachedApps.isNotEmpty) {
          state = AsyncData(cachedApps);
          return;
        }
      }

      // Apps changed or no cache - fetch and enrich
      final apps = await service.getInstalledApps();
      await _enrichAndCache(apps, service, cacheService);
      state = AsyncData(apps);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
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

// ── Dashboard V2 Providers ──────────────────────────────────────

enum DashboardSortOption { name, risk, permissionCount }

final dashboardSearchQueryProvider = StateProvider<String>((ref) => '');
final dashboardSortOptionProvider = StateProvider<DashboardSortOption>(
  (ref) => DashboardSortOption.risk,
);
final dashboardTabProvider = StateProvider<AppType>((ref) => AppType.userApps);
final dashboardRiskFilterProvider = StateProvider<RiskLevel?>((ref) => null);

class DashboardOverview {
  final int totalApps;
  final int systemApps;
  final int userApps;
  final int unknownSourceApps;
  final int safeApps;
  final int mediumApps;
  final int dangerousApps;
  final int totalDangerousPermissions;
  final Map<String, int> permissionUsage;
  final int securityScore;

  DashboardOverview({
    required this.totalApps,
    required this.systemApps,
    required this.userApps,
    required this.unknownSourceApps,
    required this.safeApps,
    required this.mediumApps,
    required this.dangerousApps,
    required this.totalDangerousPermissions,
    required this.permissionUsage,
    required this.securityScore,
  });
}

final dashboardOverviewProvider = FutureProvider<DashboardOverview>((
  ref,
) async {
  final apps = await ref.watch(installedAppsProvider.future);

  int systemCount = 0;
  int userCount = 0;
  int unknownCount = 0;
  int safeCount = 0;
  int mediumCount = 0;
  int dangerousCount = 0;
  int totalDangerousPerms = 0;
  final permUsage = <String, int>{};

  for (final app in apps) {
    if (app.isSystemApp) {
      systemCount++;
    } else if (app.installSource != 'Unknown' &&
        app.installSource != 'System') {
      userCount++;
    } else {
      unknownCount++;
    }

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

    totalDangerousPerms += app.dangerousPermissionCount;

    for (final perm in app.permissions) {
      if (dangerousPermissions.contains(perm)) {
        permUsage[perm] = (permUsage[perm] ?? 0) + 1;
      }
    }
  }

  final securityScore = apps.isEmpty
      ? 100
      : ((safeCount * 100 + mediumCount * 50 + dangerousCount * 10) /
                apps.length)
            .round();

  return DashboardOverview(
    totalApps: apps.length,
    systemApps: systemCount,
    userApps: userCount,
    unknownSourceApps: unknownCount,
    safeApps: safeCount,
    mediumApps: mediumCount,
    dangerousApps: dangerousCount,
    totalDangerousPermissions: totalDangerousPerms,
    permissionUsage: permUsage,
    securityScore: securityScore,
  );
});

final dashboardFilteredAppsProvider = FutureProvider<List<AppInfo>>((
  ref,
) async {
  final apps = await ref.watch(installedAppsProvider.future);
  final query = ref.watch(dashboardSearchQueryProvider);
  final sortOption = ref.watch(dashboardSortOptionProvider);
  final appType = ref.watch(dashboardTabProvider);
  final riskFilter = ref.watch(dashboardRiskFilterProvider);

  List<AppInfo> filtered = List.of(apps);

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
  switch (appType) {
    case AppType.userApps:
      filtered = filtered
          .where(
            (app) =>
                !app.isSystemApp &&
                app.installSource != 'Unknown' &&
                app.installSource != 'System',
          )
          .toList();
      break;
    case AppType.systemApps:
      filtered = filtered.where((app) => app.isSystemApp).toList();
      break;
    case AppType.unknownSource:
      filtered = filtered
          .where((app) => !app.isSystemApp && app.installSource == 'Unknown')
          .toList();
      break;
  }

  // Risk level filter
  if (riskFilter != null) {
    filtered = filtered.where((app) => app.riskLevel == riskFilter).toList();
  }

  // Sorting
  if (filtered.length > 1) {
    switch (sortOption) {
      case DashboardSortOption.name:
        filtered.sort((a, b) => a.appName.compareTo(b.appName));
        break;
      case DashboardSortOption.risk:
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
      case DashboardSortOption.permissionCount:
        filtered.sort(
          (a, b) =>
              b.dangerousPermissionCount.compareTo(a.dangerousPermissionCount),
        );
        break;
    }
  }

  return filtered;
});
