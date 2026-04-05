import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_scanner/models/app_info.dart';
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
  final _searchController = TextEditingController();
  DashboardOverview? _cachedOverview;
  List<AppInfo>? _cachedApps;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await ref.read(installedAppsProvider.notifier).forceRefresh();
  }

  Future<void> _handleClearCache() async {
    final cacheService = ref.read(cacheServiceProvider);
    await cacheService.init();
    await cacheService.clearCache();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache cleared. Rescanning...'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    await _handleRefresh();
  }

  void _showHighRiskApps() {
    ref.read(dashboardRiskFilterProvider.notifier).state = RiskLevel.dangerous;
  }

  @override
  Widget build(BuildContext context) {
    final overviewAsync = ref.watch(dashboardOverviewProvider);
    final filteredAsync = ref.watch(dashboardFilteredAppsProvider);
    final currentTab = ref.watch(dashboardTabProvider);
    final currentSort = ref.watch(dashboardSortOptionProvider);
    final riskFilter = ref.watch(dashboardRiskFilterProvider);

    // Cache latest values to avoid flickering during refresh
    if (overviewAsync.hasValue) _cachedOverview = overviewAsync.value;
    if (filteredAsync.hasValue) _cachedApps = filteredAsync.value;

    final overview = overviewAsync.valueOrNull ?? _cachedOverview;
    final filteredApps = filteredAsync.valueOrNull ?? _cachedApps;

    // Initial load — no data at all
    if (overview == null) {
      return _buildSkeleton();
    }

    return _buildDashboard(
      overview,
      filteredApps ?? [],
      currentTab,
      currentSort,
      riskFilter,
      isRefreshing: overviewAsync.isLoading,
    );
  }

  // ── Main Dashboard ──────────────────────────────────────────────

  Widget _buildDashboard(
    DashboardOverview overview,
    List<AppInfo> filteredApps,
    AppType currentTab,
    DashboardSortOption currentSort,
    RiskLevel? riskFilter, {
    bool isRefreshing = false,
  }) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const Text('Security Dashboard'),
              actions: [
                if (isRefreshing)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _handleRefresh,
                    tooltip: 'Rescan apps',
                  ),
              ],
            ),
            SliverToBoxAdapter(child: _buildSecuritySummary(overview)),
            SliverToBoxAdapter(child: _buildQuickActions()),
            SliverToBoxAdapter(child: _buildPermissionBreakdown(overview)),
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildAppTypeTabs(overview, currentTab)),
            SliverToBoxAdapter(
              child: _buildSortFilterBar(currentSort, riskFilter),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  '${filteredApps.length} apps',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            if (filteredApps.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No apps found',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => RepaintBoundary(
                    child: _buildAppTile(filteredApps[index]),
                  ),
                  childCount: filteredApps.length,
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }

  // ── Security Summary Header ─────────────────────────────────────

  Widget _buildSecuritySummary(DashboardOverview overview) {
    final score = overview.securityScore;
    final Color scoreColor;
    final String scoreLabel;
    if (score >= 80) {
      scoreColor = AppColors.riskSafe;
      scoreLabel = 'Good';
    } else if (score >= 50) {
      scoreColor = AppColors.riskMedium;
      scoreLabel = 'Fair';
    } else {
      scoreColor = AppColors.riskDangerous;
      scoreLabel = 'At Risk';
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Score ring
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation(scoreColor),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$score',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          scoreLabel,
                          style: TextStyle(
                            color: scoreColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Security Score',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${overview.totalApps} apps scanned',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${overview.totalDangerousPermissions} dangerous permissions',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Risk distribution bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  if (overview.safeApps > 0)
                    Expanded(
                      flex: overview.safeApps,
                      child: Container(color: AppColors.riskSafe),
                    ),
                  if (overview.mediumApps > 0)
                    Expanded(
                      flex: overview.mediumApps,
                      child: Container(color: AppColors.riskMedium),
                    ),
                  if (overview.dangerousApps > 0)
                    Expanded(
                      flex: overview.dangerousApps,
                      child: Container(color: AppColors.riskDangerous),
                    ),
                  if (overview.totalApps == 0)
                    Expanded(
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _legendItem('Safe', overview.safeApps, AppColors.riskSafe),
              _legendItem('Medium', overview.mediumApps, AppColors.riskMedium),
              _legendItem(
                'High Risk',
                overview.dangerousApps,
                AppColors.riskDangerous,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$count $label',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
              Icons.delete_sweep_outlined,
              'Clear Cache',
              AppColors.secondary,
              _handleClearCache,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _actionCard(
              Icons.warning_amber_rounded,
              'High Risk',
              AppColors.riskDangerous,
              _showHighRiskApps,
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Permission Breakdown ────────────────────────────────────────

  Widget _buildPermissionBreakdown(DashboardOverview overview) {
    if (overview.permissionUsage.isEmpty) return const SizedBox(height: 8);

    final sorted = overview.permissionUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topPerms = sorted.take(6).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Dangerous Permissions',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
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
                  color: AppColors.riskDangerous.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.riskDangerous.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 14,
                      color: AppColors.riskDangerous,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$name · ${entry.value}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.riskDangerous,
                        fontWeight: FontWeight.w600,
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

  // ── Search Bar ──────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: SearchBar(
        controller: _searchController,
        onChanged: (value) {
          ref.read(dashboardSearchQueryProvider.notifier).state = value;
        },
        leading: const Icon(Icons.search, color: AppColors.textLight),
        hintText: 'Search apps...',
      ),
    );
  }

  // ── App Type Tabs ───────────────────────────────────────────────

  Widget _buildAppTypeTabs(DashboardOverview overview, AppType currentTab) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<AppType>(
          segments: [
            ButtonSegment(
              value: AppType.userApps,
              label: Text('User (${overview.userApps})'),
            ),
            ButtonSegment(
              value: AppType.systemApps,
              label: Text('System (${overview.systemApps})'),
            ),
            ButtonSegment(
              value: AppType.unknownSource,
              label: Text('Unknown (${overview.unknownSourceApps})'),
            ),
          ],
          selected: {currentTab},
          onSelectionChanged: (value) {
            ref.read(dashboardTabProvider.notifier).state = value.first;
          },
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            textStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  // ── Sort & Filter Bar ───────────────────────────────────────────

  Widget _buildSortFilterBar(
    DashboardSortOption currentSort,
    RiskLevel? riskFilter,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          // Sort dropdown
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<DashboardSortOption>(
                  isExpanded: true,
                  value: currentSort,
                  icon: const Icon(Icons.sort, size: 18),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: DashboardSortOption.risk,
                      child: Text('Risk Level'),
                    ),
                    DropdownMenuItem(
                      value: DashboardSortOption.name,
                      child: Text('Name'),
                    ),
                    DropdownMenuItem(
                      value: DashboardSortOption.permissionCount,
                      child: Text('Permissions'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(dashboardSortOptionProvider.notifier).state = v;
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Risk filter chips
          _filterChip(
            'All',
            riskFilter == null,
            () => ref.read(dashboardRiskFilterProvider.notifier).state = null,
          ),
          const SizedBox(width: 6),
          _filterChip(
            'Risky',
            riskFilter == RiskLevel.dangerous,
            () => ref.read(dashboardRiskFilterProvider.notifier).state =
                riskFilter == RiskLevel.dangerous ? null : RiskLevel.dangerous,
            activeColor: AppColors.riskDangerous,
          ),
          const SizedBox(width: 6),
          _filterChip(
            'Safe',
            riskFilter == RiskLevel.safe,
            () => ref.read(dashboardRiskFilterProvider.notifier).state =
                riskFilter == RiskLevel.safe ? null : RiskLevel.safe,
            activeColor: AppColors.riskSafe,
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
    String label,
    bool selected,
    VoidCallback onTap, {
    Color? activeColor,
  }) {
    final color = activeColor ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? color : AppColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? color : AppColors.textLight,
          ),
        ),
      ),
    );
  }

  // ── App Tile ────────────────────────────────────────────────────

  Widget _buildAppTile(AppInfo app) {
    final topPerms = app.permissions
        .where((p) => dangerousPermissions.contains(p))
        .take(3)
        .map((p) {
          final info = permissionDatabase[p];
          return info?.displayName ?? p.split('.').last;
        })
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.divider),
        ),
        child: InkWell(
          onTap: () {
            ref.read(selectedAppProvider.notifier).state = app;
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AppDetailScreen(app: app)),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // App icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 46,
                    height: 46,
                    color: AppColors.background,
                    child: app.iconPath != null && app.iconPath!.isNotEmpty
                        ? Image.memory(
                            base64Decode(app.iconPath!),
                            width: 46,
                            height: 46,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.apps,
                              size: 26,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(
                            Icons.apps,
                            size: 26,
                            color: AppColors.primary,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              app.appName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          RiskBadge(riskLevel: app.riskLevel),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _sourceTag(app.installSource),
                          const SizedBox(width: 8),
                          Text(
                            '${app.dangerousPermissionCount} dangerous',
                            style: TextStyle(
                              fontSize: 11,
                              color: app.dangerousPermissionCount > 0
                                  ? AppColors.riskDangerous
                                  : AppColors.textLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${app.permissions.length} perms',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                      if (topPerms.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: topPerms
                              .map(
                                (name) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.riskDangerous.withValues(
                                      alpha: 0.07,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.riskDangerous,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textLight,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sourceTag(String source) {
    final Color color;
    switch (source) {
      case 'Play Store':
      case 'Galaxy Store':
        color = AppColors.riskSafe;
        break;
      case 'System':
        color = AppColors.primary;
        break;
      default:
        color = AppColors.riskMedium;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        source,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Skeleton Loader ─────────────────────────────────────────────

  Widget _buildSkeleton() {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(pinned: true, title: Text('Security Dashboard')),
          SliverToBoxAdapter(child: _DashboardSkeleton()),
        ],
      ),
    );
  }
}

// ── Skeleton Animation ──────────────────────────────────────────────

class _DashboardSkeleton extends StatefulWidget {
  @override
  State<_DashboardSkeleton> createState() => _DashboardSkeletonState();
}

class _DashboardSkeletonState extends State<_DashboardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _bone(double width, double height, {double radius = 12}) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300.withValues(
            alpha: 0.3 + _controller.value * 0.4,
          ),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary skeleton
          _bone(double.infinity, 190, radius: 20),
          const SizedBox(height: 16),
          // Quick actions skeleton
          Row(
            children: List.generate(
              3,
              (_) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _bone(double.infinity, 80, radius: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Permission chips skeleton
          Align(alignment: Alignment.centerLeft, child: _bone(180, 16)),
          const SizedBox(height: 10),
          Row(
            children: [
              _bone(100, 30),
              const SizedBox(width: 8),
              _bone(80, 30),
              const SizedBox(width: 8),
              _bone(90, 30),
            ],
          ),
          const SizedBox(height: 20),
          // Search skeleton
          _bone(double.infinity, 48),
          const SizedBox(height: 16),
          // Tabs skeleton
          _bone(double.infinity, 40),
          const SizedBox(height: 16),
          // App list skeleton
          ...List.generate(
            5,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _bone(double.infinity, 84),
            ),
          ),
        ],
      ),
    );
  }
}
