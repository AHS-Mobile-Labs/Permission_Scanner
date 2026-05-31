import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/models/permission_justification.dart';
import 'package:permission_scanner/models/loading_progress.dart';
import 'package:permission_scanner/services/permission_scanner_service.dart';
import 'package:permission_scanner/services/permission_analyzer.dart';
import 'package:permission_scanner/services/cache_service.dart';
import 'package:permission_scanner/services/icon_cache_service.dart';
import 'package:permission_scanner/services/notification_service.dart';
import 'package:permission_scanner/services/app_logger.dart';
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

/// Loading progress provider with proper state machine.
///
/// Tracks real app initialization through these stages:
/// - Stage 0: Initialize cache (0-20%)
/// - Stage 1: Scan apps from native (20-50%)
/// - Stage 2: Enrich + analyze (50-80%)
/// - Stage 3: Cache icons & finalize (80-100%)
final loadingProgressProvider =
    StateNotifierProvider<LoadingProgressNotifier, LoadingProgress>(
      (ref) => LoadingProgressNotifier(ref),
    );

class LoadingProgressNotifier extends StateNotifier<LoadingProgress> {
  final Ref ref;
  bool _initialized = false;
  int _lastReportedStage = -1;

  LoadingProgressNotifier(this.ref) : super(const LoadingProgress.initial()) {
    _startInitialization();
  }

  void _startInitialization() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // Stage 0: Initialize cache (0-20%)
      _reportProgress(stage: 0, percentage: 5, message: 'Starting up...');
      await Future.delayed(const Duration(milliseconds: 300));
      _reportProgress(
        stage: 0,
        percentage: 15,
        message: 'Initializing cache...',
      );

      // Listen to installedAppsProvider to track real progress
      ref.listen<AsyncValue<List<AppInfo>>>(installedAppsProvider, (
        previous,
        next,
      ) {
        next.when(
          data: (apps) {
            // Stage 1 complete: Apps fetched (50%)
            _reportProgress(
              stage: 1,
              percentage: 50,
              message: 'Scanning apps...',
            );

            if (apps.isEmpty) {
              // No apps - skip to complete
              _reportProgress(stage: 3, percentage: 100, message: 'Ready!');
              state = const LoadingProgress.complete();
              return;
            }

            // Stage 2: Enrichment happens in background via compute()
            // Give visual feedback that enrichment is happening
            _reportProgress(
              stage: 2,
              percentage: 65,
              message: 'Analyzing permissions...',
            );

            // Icon caching happens in background (unawaited in InstalledAppsNotifier)
            // Simulate the icon caching stage with visual progress
            Future.delayed(const Duration(milliseconds: 800), () {
              if (!mounted) return;
              if (state.percentage < 90) {
                _reportProgress(
                  stage: 3,
                  percentage: 90,
                  message: 'Finalizing...',
                );
              }
            });

            // Mark complete after a brief delay to show final state
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (!mounted) return;
              if (!state.isComplete) {
                state = const LoadingProgress.complete();
              }
            });
          },
          loading: () {
            // Still loading - keep progress moving forward
            if (state.stage < 1) {
              _reportProgress(
                stage: 1,
                percentage: 30,
                message: 'Fetching apps...',
              );
            }
          },
          error: (error, stack) {
            // Error during loading - show meaningful message
            _reportProgress(
              stage: 3,
              percentage: 100,
              message: 'Ready (cached data)',
            );
            state = const LoadingProgress.complete();
          },
        );
      });

      // Timeout after 30 seconds to prevent infinite splash screen
      Future.delayed(const Duration(seconds: 30), () {
        if (!mounted) return;
        if (!state.isComplete) {
          state = const LoadingProgress.complete();
        }
      });
    } catch (e, stackTrace) {
      AppLogger.error('Loading progress initialization failed', e, stackTrace);
      state = const LoadingProgress.complete();
    }
  }

  /// Report progress only when stage advances or percentage increases significantly
  void _reportProgress({
    required int stage,
    required int percentage,
    required String message,
  }) {
    // Avoid redundant updates for the same stage
    if (stage == _lastReportedStage && percentage <= state.percentage) {
      return;
    }

    _lastReportedStage = stage;

    state = LoadingProgress(
      stage: stage,
      percentage: percentage.clamp(0, 99),
      message: message,
      isComplete: false,
    );
  }
}

/// Enriches a list of apps on a background isolate using [compute].
/// This prevents the heavy permission-analysis work from blocking the UI.
List<AppInfo> _enrichAppsInBackground(List<AppInfo> apps) {
  return apps.map((app) => PermissionAnalyzer.enrichAppInfo(app)).toList();
}

List<PermissionChangeEvent> _detectPermissionChanges(
  List<AppInfo> previousApps,
  List<AppInfo> freshApps,
) {
  if (previousApps.isEmpty) return [];
  final previousByPackage = {
    for (final app in previousApps) app.packageName: app,
  };
  final events = <PermissionChangeEvent>[];
  final now = DateTime.now();

  for (final fresh in freshApps) {
    final previous = previousByPackage[fresh.packageName];
    if (previous == null) continue;

    final before = previous.permissions.toSet();
    final after = fresh.permissions.toSet();
    final added = after.difference(before).toList()..sort();
    final removed = before.difference(after).toList()..sort();

    if (added.isEmpty && removed.isEmpty) continue;

    events.add(
      PermissionChangeEvent(
        packageName: fresh.packageName,
        appName: fresh.appName,
        addedPermissions: added,
        removedPermissions: removed,
        beforeScore: previous.privacyScore,
        afterScore: fresh.privacyScore,
        beforeRisk: previous.riskLevel,
        afterRisk: fresh.riskLevel,
        detectedAt: now,
      ),
    );
  }

  return events;
}

Future<void> _notifyPermissionChanges(
  List<PermissionChangeEvent> events,
) async {
  if (events.isEmpty) return;
  final notificationService = NotificationService();

  for (final event in events.take(5)) {
    if (!event.hasAddedPermissions) continue;
    final firstPermission = _permissionDisplayName(
      event.addedPermissions.first,
    );
    final more = event.addedPermissions.length > 1
        ? ' and ${event.addedPermissions.length - 1} more'
        : '';
    await notificationService.showNotification(
      title: 'Permission changed',
      body: '${event.appName} added $firstPermission$more after update.',
      id: 'permission_change_${event.packageName}_${event.detectedAt.millisecondsSinceEpoch}',
    );
  }
}

String _permissionDisplayName(String permission) {
  return permissionDatabase[permission]?.displayName ??
      permission.split('.').last.replaceAll('_', ' ');
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
    final cachedApps = await cacheService.getCachedAppsAsync();
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
      final apps = await service.getInstalledApps(deepScan: false);
      if (apps.isEmpty) return [];

      // Don't await enrichment - start caching in background
      unawaited(_enrichAndCache(apps, service, cacheService));
      // A deeper APK byte scan is useful but never part of first paint.
      unawaited(_deepScanAndCache(service, cacheService));

      // Return unenriched apps immediately for fast UI rendering
      return apps;
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching apps on cold start', e, stackTrace);
      return [];
    }
  }

  /// Enriches apps in the background and updates cache
  /// Also caches icons to files to eliminate base64 decoding on every render
  Future<void> _enrichAndCache(
    List<AppInfo> apps,
    PermissionScannerService service,
    CacheService cacheService,
  ) async {
    try {
      final previousApps = await cacheService.getCachedAppsAsync();

      // Get fingerprint
      final fingerprint = await service.getAppsFingerprint();

      // Enrich on background isolate to avoid blocking
      final enrichedApps = await compute(_enrichAppsInBackground, apps);
      final permissionChanges = _detectPermissionChanges(
        previousApps,
        enrichedApps,
      );
      if (permissionChanges.isNotEmpty) {
        await cacheService.savePermissionChangeEvents(permissionChanges);
        unawaited(_notifyPermissionChanges(permissionChanges));
      }

      // Cache icons in parallel to avoid blocking
      // Icons are cached from base64 to PNG files for fast rendering
      unawaited(_cacheIconsInBackground(enrichedApps));

      // Update cache
      await cacheService.saveApps(enrichedApps);
      if (fingerprint.isNotEmpty) {
        await cacheService.saveFingerprint(fingerprint);
      }

      // Update state with enriched apps
      state = AsyncData(enrichedApps);
    } catch (e, stackTrace) {
      AppLogger.error('Error enriching apps', e, stackTrace);
      // Keep the unenriched apps - don't fail
    }
  }

  /// Caches all app icons from base64 to PNG files in background
  /// This eliminates expensive base64 decode operations during rendering
  Future<void> _cacheIconsInBackground(List<AppInfo> apps) async {
    try {
      for (final app in apps) {
        if (app.iconPath != null && app.iconPath!.isNotEmpty) {
          // Try to detect if already a file path (starts with /)
          if (!app.iconPath!.startsWith('/')) {
            await IconCacheService.cacheIconFromBase64(
              app.iconPath!,
              app.packageName,
            );
          }
        }
      }
      AppLogger.info('Icon caching completed for ${apps.length} apps');
    } catch (e, stackTrace) {
      AppLogger.error('Error caching icons', e, stackTrace);
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

      final freshApps = await service.getInstalledApps(deepScan: true);
      final enrichedApps = await compute(_enrichAppsInBackground, freshApps);
      final previousApps = await cacheService.getCachedAppsAsync();
      final permissionChanges = _detectPermissionChanges(
        previousApps,
        enrichedApps,
      );
      if (permissionChanges.isNotEmpty) {
        await cacheService.savePermissionChangeEvents(permissionChanges);
        unawaited(_notifyPermissionChanges(permissionChanges));
      }

      // Cache icons in background
      unawaited(_cacheIconsInBackground(enrichedApps));

      await cacheService.saveApps(enrichedApps);
      await cacheService.saveFingerprint(fingerprint);

      // Push updated list to listeners
      state = AsyncData(enrichedApps);
    } catch (e, stackTrace) {
      AppLogger.error('Error refreshing app cache', e, stackTrace);
    }
  }

  Future<void> _deepScanAndCache(
    PermissionScannerService service,
    CacheService cacheService,
  ) async {
    try {
      await Future<void>.delayed(const Duration(seconds: 2));
      final freshApps = await service.getInstalledApps(deepScan: true);
      if (freshApps.isEmpty) return;
      final previousApps = await cacheService.getCachedAppsAsync();
      final enrichedApps = await compute(_enrichAppsInBackground, freshApps);
      final permissionChanges = _detectPermissionChanges(
        previousApps,
        enrichedApps,
      );
      if (permissionChanges.isNotEmpty) {
        await cacheService.savePermissionChangeEvents(permissionChanges);
        unawaited(_notifyPermissionChanges(permissionChanges));
      }
      final fingerprint = await service.getAppsFingerprint();
      await cacheService.saveApps(enrichedApps);
      if (fingerprint.isNotEmpty) {
        await cacheService.saveFingerprint(fingerprint);
      }
      state = AsyncData(enrichedApps);
    } catch (e, stackTrace) {
      AppLogger.error('Background deep scan failed', e, stackTrace);
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
        final cachedApps = await cacheService.getCachedAppsAsync();
        if (cachedApps.isNotEmpty) {
          state = AsyncData(cachedApps);
          return;
        }
      }

      // Apps changed or no cache - fetch and enrich
      final apps = await service.getInstalledApps(deepScan: true);
      await _enrichAndCache(apps, service, cacheService);

      // Update state with refreshed apps
      final refreshedApps = await state.maybeWhen(
        data: (data) => Future.value(data),
        orElse: () => Future.value(apps),
      );
      state = AsyncData(refreshedApps);
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
            RiskLevel.critical: 0,
            RiskLevel.high: 1,
            RiskLevel.medium: 2,
            RiskLevel.safe: 3,
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
      final cacheService = ref.watch(cacheServiceProvider);
      await cacheService.init();
      return cacheService.getPermissionHistory(packageName);
    });

final permissionChangeEventsProvider =
    FutureProvider<List<PermissionChangeEvent>>((ref) async {
      final cacheService = ref.watch(cacheServiceProvider);
      await cacheService.init();
      return cacheService.getPermissionChangeEvents(limit: 50);
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
      case RiskLevel.high:
      case RiskLevel.critical:
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
  final int highRiskApps;
  final int criticalApps;
  final int totalDangerousPermissions;
  final int totalTrackers;
  final int persistentApps;
  final int trackerHeavyApps;
  final Map<String, int> permissionUsage;
  final Map<String, int> trackerUsage;
  final List<AppInfo> topRiskApps;
  final List<PermissionChangeEvent> recentChanges;
  final int securityScore;

  int get dangerousApps => highRiskApps + criticalApps;

  DashboardOverview({
    required this.totalApps,
    required this.systemApps,
    required this.userApps,
    required this.unknownSourceApps,
    required this.safeApps,
    required this.mediumApps,
    required this.highRiskApps,
    required this.criticalApps,
    required this.totalDangerousPermissions,
    required this.totalTrackers,
    required this.persistentApps,
    required this.trackerHeavyApps,
    required this.permissionUsage,
    required this.trackerUsage,
    required this.topRiskApps,
    required this.recentChanges,
    required this.securityScore,
  });
}

class _DashboardOverviewInput {
  final List<AppInfo> apps;
  final List<PermissionChangeEvent> recentChanges;

  const _DashboardOverviewInput(this.apps, this.recentChanges);
}

final dashboardOverviewProvider = FutureProvider<DashboardOverview>((
  ref,
) async {
  final apps = await ref.watch(installedAppsProvider.future);
  final cacheService = ref.watch(cacheServiceProvider);
  await cacheService.init();
  final recentChanges = await cacheService.getPermissionChangeEvents(limit: 5);

  return compute(
    _buildDashboardOverviewInBackground,
    _DashboardOverviewInput(apps, recentChanges),
  );
});

DashboardOverview _buildDashboardOverviewInBackground(
  _DashboardOverviewInput input,
) {
  final apps = input.apps;

  int systemCount = 0;
  int userCount = 0;
  int unknownCount = 0;
  int safeCount = 0;
  int mediumCount = 0;
  int highRiskCount = 0;
  int criticalCount = 0;
  int totalDangerousPerms = 0;
  int totalTrackers = 0;
  int persistentApps = 0;
  int trackerHeavyApps = 0;
  final permUsage = <String, int>{};
  final trackerUsage = <String, int>{};

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
      case RiskLevel.high:
        highRiskCount++;
        break;
      case RiskLevel.critical:
        criticalCount++;
        break;
    }

    totalDangerousPerms += app.dangerousPermissionCount;
    totalTrackers += app.trackers.length;
    if (app.runsAtBoot ||
        app.usesForegroundService ||
        app.requestsBatteryOptimizationBypass ||
        app.keepsDeviceAwake) {
      persistentApps++;
    }
    if (app.trackers.length >= 3) trackerHeavyApps++;

    for (final perm in app.permissions) {
      if (dangerousPermissions.contains(perm)) {
        permUsage[perm] = (permUsage[perm] ?? 0) + 1;
      }
    }
    for (final tracker in app.trackers) {
      trackerUsage[tracker.name] = (trackerUsage[tracker.name] ?? 0) + 1;
    }
  }

  final securityScore = apps.isEmpty
      ? 100
      : (apps.fold<int>(0, (sum, app) => sum + app.privacyScore) / apps.length)
            .round();
  final topRiskApps = List<AppInfo>.from(apps)
    ..sort((a, b) {
      final riskCompare = a.riskLevel.sortRank.compareTo(b.riskLevel.sortRank);
      if (riskCompare != 0) return riskCompare;
      return a.privacyScore.compareTo(b.privacyScore);
    });

  return DashboardOverview(
    totalApps: apps.length,
    systemApps: systemCount,
    userApps: userCount,
    unknownSourceApps: unknownCount,
    safeApps: safeCount,
    mediumApps: mediumCount,
    highRiskApps: highRiskCount,
    criticalApps: criticalCount,
    totalDangerousPermissions: totalDangerousPerms,
    totalTrackers: totalTrackers,
    persistentApps: persistentApps,
    trackerHeavyApps: trackerHeavyApps,
    permissionUsage: permUsage,
    trackerUsage: trackerUsage,
    topRiskApps: topRiskApps.take(8).toList(),
    recentChanges: input.recentChanges,
    securityScore: securityScore,
  );
}

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
            RiskLevel.critical: 0,
            RiskLevel.high: 1,
            RiskLevel.medium: 2,
            RiskLevel.safe: 3,
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
