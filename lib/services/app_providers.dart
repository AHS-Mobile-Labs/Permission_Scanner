import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/models/loading_progress.dart';
import 'package:permission_scanner/models/permission_justification.dart';
import 'package:permission_scanner/services/app_logger.dart';
import 'package:permission_scanner/services/cache_service.dart';
import 'package:permission_scanner/services/notification_service.dart';
import 'package:permission_scanner/services/permission_analyzer.dart';
import 'package:permission_scanner/services/permission_scanner_service.dart';
import 'package:permission_scanner/utils/permission_database.dart';

enum SortOption { name, risk }

enum AppType { userApps, systemApps, unknownSource }

final permissionScannerServiceProvider = Provider((_) {
  return PermissionScannerService();
});

final cacheServiceProvider = Provider((_) {
  return CacheService();
});

/// Loading progress provider that responds accurately to real lifecycle states.
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
      _reportProgress(stage: 0, percentage: 10, message: 'Initializing...');

      ref.listen<AsyncValue<List<AppInfo>>>(installedAppsProvider, (
        previous,
        next,
      ) {
        next.when(
          data: (apps) {
            _reportProgress(stage: 3, percentage: 100, message: 'Ready!');
            state = const LoadingProgress.complete();
          },
          loading: () {
            if (state.stage < 1) {
              _reportProgress(
                stage: 1,
                percentage: 45,
                message: 'Scanning apps...',
              );
            }
          },
          error: (error, stack) {
            _reportProgress(
              stage: 3,
              percentage: 100,
              message: 'Ready (cached)',
            );
            state = const LoadingProgress.complete();
          },
        );
      }, fireImmediately: true);

      // Safety timeout after 10 seconds to avoid ever freezing the splash screen
      Future.delayed(const Duration(seconds: 10), () {
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

  void _reportProgress({
    required int stage,
    required int percentage,
    required String message,
  }) {
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

bool _needsTrackerDeepScan(List<AppInfo> apps) {
  return apps.any((app) {
    if (app.isSystemApp) return false;
    return app.apkFileCount == 0 &&
        app.dexFileCount == 0 &&
        app.nativeLibraryCount == 0 &&
        !app.staticAnalysisLimitReached &&
        app.apkSha256.isEmpty;
  });
}

/// Main provider for installed applications.
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
      unawaited(_refreshIfChanged(service, cacheService));
      return cachedApps;
    }

    // ── Cold start: no cache yet ────────
    try {
      final apps = await service.getInstalledApps(deepScan: false);
      if (apps.isEmpty) {
        throw StateError('No applications discovered from device scanner');
      }

      final enrichedApps = await compute(_enrichAppsInBackground, apps);
      await cacheService.saveApps(enrichedApps);
      final fingerprint = await service.getAppsFingerprint();
      if (fingerprint.isNotEmpty) {
        await cacheService.saveFingerprint(fingerprint);
      }

      unawaited(_deepScanAndCache(service, cacheService));
      return enrichedApps;
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching apps on cold start', e, stackTrace);
      rethrow;
    }
  }



  Future<void> _refreshIfChanged(
    PermissionScannerService service,
    CacheService cacheService,
  ) async {
    try {
      final fingerprint = await service.getAppsFingerprint();
      final cachedApps = await cacheService.getCachedAppsAsync();
      final needsTrackerScan = _needsTrackerDeepScan(cachedApps);
      if ((fingerprint.isEmpty && !needsTrackerScan) ||
          (fingerprint.isNotEmpty &&
              !cacheService.hasAppsChanged(fingerprint) &&
              !needsTrackerScan)) {
        return;
      }

      final freshApps = await service.getInstalledApps(deepScan: false);
      if (freshApps.isEmpty) return;
      final enrichedApps = _enrichAppsInBackground(freshApps);
      final permissionChanges = _detectPermissionChanges(
        cachedApps,
        enrichedApps,
      );
      if (permissionChanges.isNotEmpty) {
        await cacheService.savePermissionChangeEvents(permissionChanges);
        unawaited(_notifyPermissionChanges(permissionChanges));
      }

      await cacheService.saveApps(enrichedApps);
      if (fingerprint.isNotEmpty) {
        await cacheService.saveFingerprint(fingerprint);
      }

      state = AsyncData(enrichedApps);
      ref.invalidate(dashboardOverviewProvider);
      ref.invalidate(permissionChangeEventsProvider);
    } catch (e, stackTrace) {
      AppLogger.error('Error refreshing app cache', e, stackTrace);
    }
  }

  Future<void> _deepScanAndCache(
    PermissionScannerService service,
    CacheService cacheService,
  ) async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 1500));
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
      ref.invalidate(dashboardOverviewProvider);
      ref.invalidate(permissionChangeEventsProvider);
    } catch (e, stackTrace) {
      AppLogger.error('Background deep scan failed', e, stackTrace);
    }
  }

  Future<void> forceRefresh() async {
    final cacheService = ref.read(cacheServiceProvider);
    final service = ref.read(permissionScannerServiceProvider);
    await cacheService.init();

    try {
      // Retain previous data so pull-to-refresh does not flash a skeleton or blank screen
      state = AsyncLoading<List<AppInfo>>().copyWithPrevious(state);

      // Instant fast scan completes in ~150-200ms
      final apps = await service.getInstalledApps(deepScan: false);
      if (apps.isEmpty) {
        if (state.hasValue) {
          state = AsyncData(state.value!);
        }
        return;
      }

      final enrichedApps = _enrichAppsInBackground(apps);
      final previousApps = await cacheService.getCachedAppsAsync();
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
      ref.invalidate(dashboardOverviewProvider);
      ref.invalidate(permissionChangeEventsProvider);

      // Kick off background deep scan without blocking UI or refresh indicator
      unawaited(_deepScanAndCache(service, cacheService));
    } catch (e, stackTrace) {
      AppLogger.error('Error during forceRefresh', e, stackTrace);
      if (state.hasValue) {
        state = AsyncData(state.value!);
      } else {
        state = AsyncError(e, stackTrace);
      }
    }
  }
}

final searchQueryProvider = StateProvider<String>((ref) => '');
final sortOptionProvider = StateProvider<SortOption>((ref) => SortOption.name);
final appTypeProvider = StateProvider<AppType>((ref) => AppType.userApps);
final permissionFilterProvider = StateProvider<String?>((ref) => null);

/// Synchronous in-memory filtered apps provider.
/// Prevents UI flickers and loading skeletons while searching or switching filters.
final filteredAppsProvider = Provider<AsyncValue<List<AppInfo>>>((ref) {
  final appsAsync = ref.watch(installedAppsProvider);
  final query = ref.watch(searchQueryProvider);
  final sortOption = ref.watch(sortOptionProvider);
  final appType = ref.watch(appTypeProvider);
  final permissionFilter = ref.watch(permissionFilterProvider);

  return appsAsync.whenData((apps) {
    List<AppInfo> filtered = apps;

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

    if (appType == AppType.userApps) {
      filtered = filtered.where((app) => !app.isSystemApp).toList();
    } else if (appType == AppType.systemApps) {
      filtered = filtered.where((app) => app.isSystemApp).toList();
    } else if (appType == AppType.unknownSource) {
      filtered = filtered
          .where((app) => !app.isSystemApp && app.installSource == 'Unknown')
          .toList();
    }

    if (permissionFilter != null && permissionFilter.isNotEmpty) {
      filtered = filtered
          .where((app) => app.permissions.contains(permissionFilter))
          .toList();
    }

    if (filtered.length > 1) {
      final sorted = List<AppInfo>.from(filtered);
      switch (sortOption) {
        case SortOption.name:
          sorted.sort(
            (a, b) =>
                a.appName.toLowerCase().compareTo(b.appName.toLowerCase()),
          );
          break;
        case SortOption.risk:
          sorted.sort((a, b) {
            final cmp = a.riskLevel.sortRank.compareTo(b.riskLevel.sortRank);
            if (cmp != 0) return cmp;
            return a.privacyScore.compareTo(b.privacyScore);
          });
          break;
      }
      return sorted;
    }

    return filtered;
  });
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

// ── Dashboard Overview Models & Provider ────────────────────────

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

  final input = _DashboardOverviewInput(apps, recentChanges);
  if (apps.length > 300) {
    return compute(_buildDashboardOverviewInBackground, input);
  }
  return _buildDashboardOverviewInBackground(input);
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
    } else {
      userCount++;
      if (app.installSource == 'Unknown') {
        unknownCount++;
      }
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
