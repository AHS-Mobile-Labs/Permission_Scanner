import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/services/app_providers.dart';
import 'package:permission_scanner/utils/app_colors.dart';
import 'package:permission_scanner/utils/permission_database.dart';
import 'package:permission_scanner/widgets/risk_badge.dart';

enum _TimelineFilter { all, added, removed, sensitive }

class PrivacyTimelineScreen extends ConsumerStatefulWidget {
  const PrivacyTimelineScreen({super.key});

  @override
  ConsumerState<PrivacyTimelineScreen> createState() =>
      _PrivacyTimelineScreenState();
}

class _PrivacyTimelineScreenState extends ConsumerState<PrivacyTimelineScreen> {
  _TimelineFilter _filter = _TimelineFilter.all;

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(installedAppsProvider);
    final changesAsync = ref.watch(permissionChangeEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission Timeline'),
        actions: [
          IconButton(
            tooltip: 'Refresh timeline',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(permissionChangeEventsProvider);
              ref.read(installedAppsProvider.notifier).forceRefresh();
            },
          ),
        ],
      ),
      body: appsAsync.when(
        data: (apps) {
          final changes = changesAsync.valueOrNull ?? [];
          final overview = _TimelineOverview.from(apps, changes);
          final filteredChanges = _filterChanges(changes);
          final groupedChanges = _groupChangesByDay(filteredChanges);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(permissionChangeEventsProvider);
              await ref.read(installedAppsProvider.notifier).forceRefresh();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _timelineHero(overview),
                if (changesAsync.isLoading) ...[
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(minHeight: 3),
                ],
                const SizedBox(height: 16),
                _usageOverview(apps),
                const SizedBox(height: 16),
                _activityBars(apps),
                const SizedBox(height: 16),
                _permissionPressurePanel(apps),
                const SizedBox(height: 16),
                _filterBar(changes),
                const SizedBox(height: 12),
                _changeTimeline(groupedChanges, filteredChanges.length),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Unable to load timeline: $error')),
      ),
    );
  }

  Widget _timelineHero(_TimelineOverview overview) {
    final postureColor = overview.highImpactChanges == 0
        ? AppColors.riskSafe
        : overview.highImpactChanges <= 2
        ? AppColors.riskMedium
        : AppColors.riskDangerous;
    final posture = overview.highImpactChanges == 0
        ? 'Stable'
        : overview.highImpactChanges <= 2
        ? 'Watch'
        : 'Review';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.dashboardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.timeline_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Permission Change Intelligence',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      overview.lastChangeText,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _heroPill(posture, postureColor),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _heroMetric('Changes', '${overview.totalChanges}'),
              ),
              const SizedBox(width: 8),
              Expanded(child: _heroMetric('Added', '${overview.addedCount}')),
              const SizedBox(width: 8),
              Expanded(
                child: _heroMetric('Removed', '${overview.removedCount}'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _heroMetric(
                  'High impact',
                  '${overview.highImpactChanges}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _usageOverview(List<AppInfo> apps) {
    final camera = _countApps(apps, 'android.permission.CAMERA');
    final mic = _countApps(apps, 'android.permission.RECORD_AUDIO');
    final location = apps.where(_hasLocationAccess).length;
    final background = apps.where(_hasBackgroundBehavior).length;

    return Row(
      children: [
        Expanded(child: _stat('Camera', camera, Icons.photo_camera_rounded)),
        const SizedBox(width: 8),
        Expanded(child: _stat('Mic', mic, Icons.mic_rounded)),
        const SizedBox(width: 8),
        Expanded(child: _stat('Location', location, Icons.location_on_rounded)),
        const SizedBox(width: 8),
        Expanded(
          child: _stat('Background', background, Icons.autorenew_rounded),
        ),
      ],
    );
  }

  Widget _stat(String label, int value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
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

  Widget _activityBars(List<AppInfo> apps) {
    final values = {
      'Camera exposure': _countApps(apps, 'android.permission.CAMERA'),
      'Microphone exposure': _countApps(
        apps,
        'android.permission.RECORD_AUDIO',
      ),
      'Location exposure': apps.where(_hasLocationAccess).length,
      'Background persistence': apps.where(_hasBackgroundBehavior).length,
      'Contacts + internet': apps
          .where((app) => app.contactsInternetCombo)
          .length,
      'SMS/calls + internet': apps
          .where((app) => app.smsCallInternetCombo)
          .length,
    };
    final maxValue = values.values.fold<int>(
      1,
      (max, value) => value > max ? value : max,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Current Exposure Map',
            'Which privacy-sensitive capabilities are present right now',
            Icons.insights_rounded,
          ),
          const SizedBox(height: 12),
          ...values.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
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
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: entry.value / maxValue),
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation(
                          _exposureColor(entry.key, entry.value),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _permissionPressurePanel(List<AppInfo> apps) {
    final groupCounts = <String, int>{};
    for (final app in apps) {
      for (final permission in app.permissions) {
        if (!_isSensitivePermission(permission)) continue;
        final group = _permissionGroup(permission);
        groupCounts[group] = (groupCounts[group] ?? 0) + 1;
      }
    }
    final sortedGroups = groupCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxValue = sortedGroups.isEmpty ? 1 : sortedGroups.first.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Permission Pressure',
            'Sensitive permission groups across installed apps',
            Icons.shield_rounded,
          ),
          const SizedBox(height: 12),
          if (sortedGroups.isEmpty)
            const Text(
              'No sensitive permission groups were found in the current scan.',
              style: TextStyle(color: AppColors.textLight, fontSize: 12),
            )
          else
            ...sortedGroups
                .take(6)
                .map((entry) => _pressureRow(entry.key, entry.value, maxValue)),
        ],
      ),
    );
  }

  Widget _pressureRow(String group, int count, int maxValue) {
    final color = _groupColor(group);
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              group,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: count / maxValue,
                minHeight: 9,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBar(List<PermissionChangeEvent> changes) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Change Feed',
            '${changes.length} stored update events from rescans',
            Icons.manage_search_rounded,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(_TimelineFilter.all, 'All', changes.length),
                _filterChip(
                  _TimelineFilter.added,
                  'Granted',
                  changes
                      .where((event) => event.addedPermissions.isNotEmpty)
                      .length,
                ),
                _filterChip(
                  _TimelineFilter.removed,
                  'Removed',
                  changes
                      .where((event) => event.removedPermissions.isNotEmpty)
                      .length,
                ),
                _filterChip(
                  _TimelineFilter.sensitive,
                  'Sensitive',
                  changes.where(_eventHasSensitiveChange).length,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(_TimelineFilter filter, String label, int count) {
    final selected = _filter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        onSelected: (_) => setState(() => _filter = filter),
        label: Text('$label $count'),
        showCheckmark: false,
        selectedColor: AppColors.primaryContainer,
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: TextStyle(
          color: selected ? AppColors.primary : AppColors.textMedium,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        side: BorderSide(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.25)
              : AppColors.divider,
        ),
      ),
    );
  }

  Widget _changeTimeline(
    Map<String, List<PermissionChangeEvent>> groupedChanges,
    int filteredCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Detailed Timeline',
            '$filteredCount events match the current filter',
            Icons.history_rounded,
          ),
          const SizedBox(height: 12),
          if (groupedChanges.isEmpty)
            _emptyTimeline()
          else
            ...groupedChanges.entries.map(
              (entry) => _dayGroup(entry.key, entry.value),
            ),
        ],
      ),
    );
  }

  Widget _emptyTimeline() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No matching permission changes yet',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'The timeline fills after rescans detect app updates that added or removed permissions.',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayGroup(String label, List<PermissionChangeEvent> events) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${events.length} events',
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...events.map(_changeCard),
        ],
      ),
    );
  }

  Widget _changeCard(PermissionChangeEvent event) {
    final formatter = DateFormat('h:mm a');
    final impact = _eventImpact(event);
    final impactColor = _impactColor(impact);
    final riskChanged = event.beforeRisk != event.afterRisk;
    final scoreDelta = event.afterScore - event.beforeScore;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: impactColor.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: impactColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(_eventIcon(event), color: impactColor, size: 20),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event.packageName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                RiskBadge(riskLevel: event.afterRisk, compact: true),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metaPill(
                  formatter.format(event.detectedAt),
                  AppColors.primary,
                ),
                _metaPill(_impactLabel(impact), impactColor),
                _metaPill(
                  _scoreDeltaLabel(scoreDelta),
                  _scoreDeltaColor(scoreDelta),
                ),
                if (riskChanged)
                  _metaPill(
                    '${event.beforeRisk.label} → ${event.afterRisk.label}',
                    _impactColor(impact + 6),
                  ),
              ],
            ),
            if (event.addedPermissions.isNotEmpty) ...[
              const SizedBox(height: 12),
              _permissionChangeSection(
                'Granted',
                event.addedPermissions,
                AppColors.riskDangerous,
                Icons.add_circle_rounded,
              ),
            ],
            if (event.removedPermissions.isNotEmpty) ...[
              const SizedBox(height: 12),
              _permissionChangeSection(
                'Removed',
                event.removedPermissions,
                AppColors.riskSafe,
                Icons.remove_circle_rounded,
              ),
            ],
            const SizedBox(height: 10),
            Text(
              _reviewFocus(event),
              style: const TextStyle(
                color: AppColors.textMedium,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _permissionChangeSection(
    String title,
    List<String> permissions,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(
              '$title ${permissions.length}',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: permissions
              .map((permission) => _permissionPill(permission, color))
              .toList(),
        ),
      ],
    );
  }

  Widget _permissionPill(String permission, Color baseColor) {
    final sensitive = _isSensitivePermission(permission);
    final color = sensitive ? _permissionColor(permission) : baseColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Text(
        '${_permissionLabel(permission)} · ${_permissionGroup(permission)}',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _metaPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<PermissionChangeEvent> _filterChanges(
    List<PermissionChangeEvent> changes,
  ) {
    switch (_filter) {
      case _TimelineFilter.added:
        return changes
            .where((event) => event.addedPermissions.isNotEmpty)
            .toList();
      case _TimelineFilter.removed:
        return changes
            .where((event) => event.removedPermissions.isNotEmpty)
            .toList();
      case _TimelineFilter.sensitive:
        return changes.where(_eventHasSensitiveChange).toList();
      case _TimelineFilter.all:
        return changes;
    }
  }

  Map<String, List<PermissionChangeEvent>> _groupChangesByDay(
    List<PermissionChangeEvent> changes,
  ) {
    final groups = <String, List<PermissionChangeEvent>>{};
    for (final event in changes) {
      final label = _dayLabel(event.detectedAt);
      groups.putIfAbsent(label, () => []).add(event);
    }
    return groups;
  }

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(eventDay).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(date);
    return DateFormat('MMM d, yyyy').format(date);
  }

  bool _eventHasSensitiveChange(PermissionChangeEvent event) {
    return [
      ...event.addedPermissions,
      ...event.removedPermissions,
    ].any(_isSensitivePermission);
  }

  int _eventImpact(PermissionChangeEvent event) {
    final added = event.addedPermissions.fold<int>(
      0,
      (sum, permission) => sum + _permissionImpact(permission),
    );
    final removed = event.removedPermissions.fold<int>(
      0,
      (sum, permission) => sum + _permissionImpact(permission),
    );
    final riskDelta =
        _riskWeight(event.afterRisk) - _riskWeight(event.beforeRisk);
    return added - removed + riskDelta;
  }

  String _impactLabel(int impact) {
    if (impact >= 16) return 'Critical impact';
    if (impact >= 8) return 'High impact';
    if (impact > 0) return 'Permission gain';
    if (impact < 0) return 'Reduced access';
    return 'Neutral';
  }

  Color _impactColor(int impact) {
    if (impact >= 16) return AppColors.riskCritical;
    if (impact >= 8) return AppColors.riskDangerous;
    if (impact > 0) return AppColors.riskMedium;
    if (impact < 0) return AppColors.riskSafe;
    return AppColors.primary;
  }

  String _scoreDeltaLabel(int delta) {
    if (delta == 0) return 'score unchanged';
    if (delta > 0) return '+$delta score';
    return '$delta score';
  }

  Color _scoreDeltaColor(int delta) {
    if (delta > 0) return AppColors.riskSafe;
    if (delta < 0) return AppColors.riskDangerous;
    return AppColors.textLight;
  }

  IconData _eventIcon(PermissionChangeEvent event) {
    if (event.addedPermissions.isNotEmpty &&
        event.removedPermissions.isNotEmpty) {
      return Icons.sync_alt_rounded;
    }
    if (event.addedPermissions.isNotEmpty) return Icons.lock_open_rounded;
    return Icons.lock_rounded;
  }

  String _reviewFocus(PermissionChangeEvent event) {
    final addedSensitive = event.addedPermissions
        .where(_isSensitivePermission)
        .map(_permissionLabel)
        .toList();
    if (addedSensitive.isNotEmpty) {
      return 'Review why this app now needs ${addedSensitive.take(3).join(', ')} before trusting the update.';
    }
    if (event.removedPermissions.isNotEmpty && event.addedPermissions.isEmpty) {
      return 'This update reduced access. You can still review app behavior if the risk level stayed elevated.';
    }
    if (event.beforeRisk != event.afterRisk) {
      return 'Risk changed from ${event.beforeRisk.label} to ${event.afterRisk.label}; compare the new permission set with the app purpose.';
    }
    return 'No highly sensitive grant was detected, but the app permission surface changed.';
  }

  bool _isSensitivePermission(String permission) {
    return dangerousPermissions.contains(permission) ||
        developerOnlyPermissions.contains(permission) ||
        permission == 'android.permission.SYSTEM_ALERT_WINDOW' ||
        permission == 'android.permission.REQUEST_INSTALL_PACKAGES' ||
        permission == 'com.google.android.gms.permission.AD_ID';
  }

  int _permissionImpact(String permission) {
    if (permission == 'android.permission.SYSTEM_ALERT_WINDOW') return 18;
    if (permission == 'android.permission.ACCESS_BACKGROUND_LOCATION') {
      return 16;
    }
    if (permission.contains('SMS') || permission.contains('CALL_LOG')) {
      return 14;
    }
    if (permission == 'android.permission.RECORD_AUDIO' ||
        permission == 'android.permission.CAMERA') {
      return 12;
    }
    if (dangerousPermissions.contains(permission)) return 8;
    if (developerOnlyPermissions.contains(permission)) return 7;
    if (permission == 'com.google.android.gms.permission.AD_ID') return 5;
    return 2;
  }

  int _riskWeight(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.safe:
        return 0;
      case RiskLevel.medium:
        return 4;
      case RiskLevel.high:
        return 9;
      case RiskLevel.critical:
        return 14;
    }
  }

  String _permissionLabel(String permission) {
    return permissionDatabase[permission]?.displayName ??
        permission.split('.').last.replaceAll('_', ' ');
  }

  String _permissionGroup(String permission) {
    if (permission == 'android.permission.SYSTEM_ALERT_WINDOW') {
      return 'Overlay';
    }
    if (permission == 'android.permission.REQUEST_INSTALL_PACKAGES') {
      return 'Installer';
    }
    if (permission == 'com.google.android.gms.permission.AD_ID') {
      return 'Ads';
    }
    return permissionDatabase[permission]?.group ?? 'Other';
  }

  Color _permissionColor(String permission) {
    return _groupColor(_permissionGroup(permission));
  }

  Color _groupColor(String group) {
    switch (group) {
      case 'SMS':
      case 'Call Log':
      case 'Overlay':
      case 'Installer':
        return AppColors.riskDangerous;
      case 'Location':
      case 'Microphone':
      case 'Camera':
      case 'Phone':
        return AppColors.riskMedium;
      case 'Contacts':
      case 'Storage':
      case 'Media':
      case 'Ads':
        return AppColors.primary;
      default:
        return AppColors.secondary;
    }
  }

  Color _exposureColor(String label, int value) {
    if (value == 0) return AppColors.riskSafe;
    if (label.contains('SMS') || label.contains('Contacts')) {
      return AppColors.riskDangerous;
    }
    if (label.contains('Background') || label.contains('Location')) {
      return AppColors.riskMedium;
    }
    return AppColors.primary;
  }

  bool _hasLocationAccess(AppInfo app) {
    return app.permissions.contains(
          'android.permission.ACCESS_FINE_LOCATION',
        ) ||
        app.permissions.contains('android.permission.ACCESS_COARSE_LOCATION') ||
        app.permissions.contains(
          'android.permission.ACCESS_BACKGROUND_LOCATION',
        );
  }

  bool _hasBackgroundBehavior(AppInfo app) {
    return app.runsAtBoot ||
        app.usesForegroundService ||
        app.requestsBatteryOptimizationBypass ||
        app.keepsDeviceAwake;
  }

  int _countApps(List<AppInfo> apps, String permission) {
    return apps.where((app) => app.permissions.contains(permission)).length;
  }
}

class _TimelineOverview {
  final int totalChanges;
  final int addedCount;
  final int removedCount;
  final int highImpactChanges;
  final String lastChangeText;

  const _TimelineOverview({
    required this.totalChanges,
    required this.addedCount,
    required this.removedCount,
    required this.highImpactChanges,
    required this.lastChangeText,
  });

  factory _TimelineOverview.from(
    List<AppInfo> apps,
    List<PermissionChangeEvent> changes,
  ) {
    final addedCount = changes.fold<int>(
      0,
      (sum, event) => sum + event.addedPermissions.length,
    );
    final removedCount = changes.fold<int>(
      0,
      (sum, event) => sum + event.removedPermissions.length,
    );
    final highImpactChanges = changes.where((event) {
      final sensitiveAdded = event.addedPermissions.any(
        (permission) =>
            dangerousPermissions.contains(permission) ||
            developerOnlyPermissions.contains(permission),
      );
      return sensitiveAdded || event.afterRisk == RiskLevel.critical;
    }).length;
    final lastChangeText = changes.isEmpty
        ? '${apps.length} apps scanned. No permission changes recorded yet.'
        : 'Last change ${DateFormat('MMM d, h:mm a').format(changes.first.detectedAt)}';

    return _TimelineOverview(
      totalChanges: changes.length,
      addedCount: addedCount,
      removedCount: removedCount,
      highImpactChanges: highImpactChanges,
      lastChangeText: lastChangeText,
    );
  }
}
