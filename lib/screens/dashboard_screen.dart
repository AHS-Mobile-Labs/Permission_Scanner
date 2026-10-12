import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_scanner/main.dart';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/screens/apk_scanner_screen.dart';
import 'package:permission_scanner/screens/app_compare_screen.dart';
import 'package:permission_scanner/screens/app_detail_screen.dart';
import 'package:permission_scanner/services/app_providers.dart';
import 'package:permission_scanner/utils/app_colors.dart';
import 'package:permission_scanner/utils/permission_database.dart';
import 'package:permission_scanner/widgets/risk_badge.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DashboardOverview? _cachedOverview;

  Future<void> _handleRefresh() async {
    await ref.read(installedAppsProvider.notifier).forceRefresh();
  }

  void _navigateToAppsWithFilter({RiskLevel? risk, AppType? type}) {
    if (type != null) {
      ref.read(appTypeProvider.notifier).state = type;
    }
    if (risk != null) {
      ref.read(sortOptionProvider.notifier).state = SortOption.risk;
    }
    ref.read(mainNavIndexProvider.notifier).state = 1;
  }

  @override
  Widget build(BuildContext context) {
    final overviewAsync = ref.watch(dashboardOverviewProvider);

    if (overviewAsync.hasValue) _cachedOverview = overviewAsync.value;
    final overview = overviewAsync.valueOrNull ?? _cachedOverview;

    if (overview == null) {
      if (overviewAsync.hasError) {
        return Scaffold(
          appBar: AppBar(title: const Text('Security Dashboard')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppColors.riskDangerous,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Unable to scan applications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${overviewAsync.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _handleRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry Scan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return _buildSkeleton();
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text('Security Dashboard'),
            actions: [
              if (overviewAsync.isLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 22),
                  onPressed: _handleRefresh,
                  tooltip: 'Rescan apps',
                ),
            ],
          ),
          SliverToBoxAdapter(child: _buildSecuritySummary(overview)),
          SliverToBoxAdapter(child: _buildQuickActions()),
          SliverToBoxAdapter(child: _buildLiveMonitoring(overview)),
          SliverToBoxAdapter(child: _buildTopRiskApps(overview)),
          SliverToBoxAdapter(child: _buildPermissionBreakdown(overview)),
          SliverToBoxAdapter(child: _buildTrackerBreakdown(overview)),
          SliverToBoxAdapter(child: _buildRecentPermissionChanges(overview)),
          const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
        ],
      ),
    );
  }

  // ── Security Summary Banner ─────────────────────────────────────

  Widget _buildSecuritySummary(DashboardOverview overview) {
    final score = overview.securityScore;
    final Color scoreColor;
    final String scoreLabel;
    if (score >= 80) {
      scoreColor = AppColors.riskSafe;
      scoreLabel = 'Good';
    } else if (score >= 60) {
      scoreColor = AppColors.riskMedium;
      scoreLabel = 'Moderate';
    } else if (score >= 35) {
      scoreColor = AppColors.riskDangerous;
      scoreLabel = 'High Exposure';
    } else {
      scoreColor = AppColors.riskCritical;
      scoreLabel = 'Critical';
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.dashboardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: score / 100),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return SizedBox(
                    width: 82,
                    height: 82,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 82,
                          height: 82,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 6,
                            strokeCap: StrokeCap.round,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.12,
                            ),
                            valueColor: AlwaysStoppedAnimation(scoreColor),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(value * 100).toInt()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              scoreLabel,
                              style: TextStyle(
                                color: scoreColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overall Privacy Score',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${overview.totalApps} applications audited',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${overview.totalDangerousPermissions} sensitive permissions declared',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 7,
              child: Row(
                children: [
                  if (overview.safeApps > 0)
                    Expanded(
                      flex: overview.safeApps,
                      child: Container(color: AppColors.riskSafe),
                    ),
                  if (overview.safeApps > 0 &&
                      (overview.mediumApps > 0 || overview.dangerousApps > 0))
                    const SizedBox(width: 2),
                  if (overview.mediumApps > 0)
                    Expanded(
                      flex: overview.mediumApps,
                      child: Container(color: AppColors.riskMedium),
                    ),
                  if (overview.mediumApps > 0 && overview.dangerousApps > 0)
                    const SizedBox(width: 2),
                  if (overview.dangerousApps > 0)
                    Expanded(
                      flex: overview.dangerousApps,
                      child: Container(color: AppColors.riskDangerous),
                    ),
                  if (overview.totalApps == 0)
                    Expanded(
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _legendItem(
                'Safe',
                overview.safeApps,
                AppColors.riskSafe,
                () => _navigateToAppsWithFilter(risk: RiskLevel.safe),
              ),
              _legendItem(
                'Medium',
                overview.mediumApps,
                AppColors.riskMedium,
                () => _navigateToAppsWithFilter(risk: RiskLevel.medium),
              ),
              _legendItem(
                'High',
                overview.highRiskApps,
                AppColors.riskDangerous,
                () => _navigateToAppsWithFilter(risk: RiskLevel.high),
              ),
              _legendItem(
                'Critical',
                overview.criticalApps,
                AppColors.riskCritical,
                () => _navigateToAppsWithFilter(risk: RiskLevel.critical),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, int count, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              '$count $label',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick Actions ───────────────────────────────────────────────

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _actionCard(
              Icons.refresh_rounded,
              'Rescan',
              AppColors.primary,
              _handleRefresh,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _actionCard(
              Icons.upload_file_rounded,
              'Scan APK',
              AppColors.secondary,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ApkScannerScreen()),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _actionCard(
              Icons.compare_arrows_rounded,
              'Compare',
              const Color(0xFF6366F1),
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppCompareScreen()),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _actionCard(
              Icons.tune_rounded,
              'Tools',
              AppColors.primary,
              () => ref.read(mainNavIndexProvider.notifier).state = 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Live Monitoring Tiles ───────────────────────────────────────

  Widget _buildLiveMonitoring(DashboardOverview overview) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _metricTile(
              Icons.track_changes_rounded,
              '${overview.totalTrackers}',
              'Trackers Found',
              AppColors.secondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _metricTile(
              Icons.autorenew_rounded,
              '${overview.persistentApps}',
              'Background Apps',
              AppColors.riskMedium,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _metricTile(
              Icons.security_update_warning_rounded,
              '${overview.recentChanges.length}',
              'Recent Changes',
              AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTile(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Apps Needing Review ─────────────────────────────────────

  Widget _buildTopRiskApps(DashboardOverview overview) {
    final topApps = overview.topRiskApps.take(5).toList();
    if (topApps.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Apps Needing Review',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(sortOptionProvider.notifier).state = SortOption.risk;
                  ref.read(mainNavIndexProvider.notifier).state = 1;
                },
                child: const Text('View All', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...topApps.map((app) => _buildAppRow(app)),
        ],
      ),
    );
  }

  Widget _buildAppRow(AppInfo app) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            ref.read(selectedAppProvider.notifier).state = app;
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AppDetailScreen(app: app)),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 40,
                    height: 40,
                    color: AppColors.surfaceVariant,
                    child:
                        app.iconPath != null &&
                            app.iconPath!.isNotEmpty &&
                            app.iconPath!.startsWith('/')
                        ? Image.file(
                            File(app.iconPath!),
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.apps_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(
                            Icons.apps_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.appName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${app.dangerousPermissionCount} sensitive permissions · ${app.installSource}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                RiskBadge(riskLevel: app.riskLevel, compact: true),
                const SizedBox(width: 8),
                Text(
                  '${app.privacyScore}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Permission Breakdown ────────────────────────────────────────

  Widget _buildPermissionBreakdown(DashboardOverview overview) {
    if (overview.permissionUsage.isEmpty) return const SizedBox.shrink();

    final sorted = overview.permissionUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topPerms = sorted.take(6).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sensitive Permission Exposure',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: topPerms.map((entry) {
              final info = permissionDatabase[entry.key];
              final name = info?.displayName ?? entry.key.split('.').last;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.riskDangerousContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shield_rounded,
                      size: 13,
                      color: AppColors.riskDangerous,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$name · ${entry.value}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.riskDangerous,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Tracker Detection Breakdown ─────────────────────────────────

  Widget _buildTrackerBreakdown(DashboardOverview overview) {
    if (overview.trackerUsage.isEmpty) return const SizedBox.shrink();
    final sorted = overview.trackerUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTrackers = sorted.take(4).toList();
    final maxCount = topTrackers.first.value;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trackers & Analytics SDKs',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            ...topTrackers.map((entry) {
              final value = maxCount > 0 ? entry.value / maxCount : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${entry.value} apps',
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceVariant,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Recent Permission Changes ───────────────────────────────────

  Widget _buildRecentPermissionChanges(DashboardOverview overview) {
    if (overview.recentChanges.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Permission Changes',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            ...overview.recentChanges.map((event) {
              final added = event.addedPermissions
                  .take(2)
                  .map(
                    (p) =>
                        permissionDatabase[p]?.displayName ??
                        p.split('.').last.replaceAll('_', ' '),
                  )
                  .join(', ');
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.notification_important_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.appName,
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            added.isEmpty
                                ? 'Removed ${event.removedPermissions.length} permissions'
                                : 'Added $added',
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 11,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    RiskBadge(riskLevel: event.afterRisk, compact: true),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Skeleton Placeholder ────────────────────────────────────────

  Widget _buildSkeleton() {
    return Scaffold(
      appBar: AppBar(title: const Text('Security Dashboard')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Loading security metrics...',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
