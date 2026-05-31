import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/services/app_providers.dart';
import 'package:permission_scanner/utils/app_colors.dart';
import 'package:permission_scanner/utils/permission_database.dart';
import 'package:permission_scanner/widgets/risk_badge.dart';

class PrivacyTimelineScreen extends ConsumerWidget {
  const PrivacyTimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(installedAppsProvider);
    final changesAsync = ref.watch(permissionChangeEventsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Permission Timeline')),
      body: appsAsync.when(
        data: (apps) {
          final changes = changesAsync.valueOrNull ?? [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _usageOverview(apps),
              const SizedBox(height: 16),
              _activityBars(apps),
              const SizedBox(height: 16),
              _changeTimeline(changes),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Unable to load timeline: $error')),
      ),
    );
  }

  Widget _usageOverview(List<AppInfo> apps) {
    final camera = _countApps(apps, 'android.permission.CAMERA');
    final mic = _countApps(apps, 'android.permission.RECORD_AUDIO');
    final location = apps
        .where(
          (app) =>
              app.permissions.contains(
                'android.permission.ACCESS_FINE_LOCATION',
              ) ||
              app.permissions.contains(
                'android.permission.ACCESS_COARSE_LOCATION',
              ) ||
              app.permissions.contains(
                'android.permission.ACCESS_BACKGROUND_LOCATION',
              ),
        )
        .length;
    final background = apps
        .where(
          (app) =>
              app.runsAtBoot ||
              app.usesForegroundService ||
              app.requestsBatteryOptimizationBypass,
        )
        .length;

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
      'Location exposure': apps
          .where(
            (app) =>
                app.permissions.contains(
                  'android.permission.ACCESS_FINE_LOCATION',
                ) ||
                app.permissions.contains(
                  'android.permission.ACCESS_COARSE_LOCATION',
                ) ||
                app.permissions.contains(
                  'android.permission.ACCESS_BACKGROUND_LOCATION',
                ),
          )
          .length,
      'Background spikes': apps
          .where(
            (app) =>
                app.runsAtBoot ||
                app.usesForegroundService ||
                app.requestsBatteryOptimizationBypass,
          )
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
          const Text(
            'Permission Activity',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
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
                        '${entry.value}',
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
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary,
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

  Widget _changeTimeline(List<PermissionChangeEvent> changes) {
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
          const Text(
            'Recently Granted Permissions',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (changes.isEmpty)
            const Text(
              'No permission changes have been detected yet. The app records this after updates or rescans.',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 12,
                height: 1.35,
              ),
            )
          else
            ...changes.map(_changeCard),
        ],
      ),
    );
  }

  Widget _changeCard(PermissionChangeEvent event) {
    final formatter = DateFormat('MMM d, h:mm a');
    final added = event.addedPermissions
        .map(
          (permission) =>
              permissionDatabase[permission]?.displayName ??
              permission.split('.').last,
        )
        .join(', ');
    final removed = event.removedPermissions
        .map(
          (permission) =>
              permissionDatabase[permission]?.displayName ??
              permission.split('.').last,
        )
        .join(', ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.appName,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                RiskBadge(riskLevel: event.afterRisk, compact: true),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              formatter.format(event.detectedAt),
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (added.isNotEmpty)
              Text(
                'Added: $added',
                style: const TextStyle(
                  color: AppColors.riskDangerous,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (removed.isNotEmpty)
              Text(
                'Removed: $removed',
                style: const TextStyle(
                  color: AppColors.riskSafe,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _countApps(List<AppInfo> apps, String permission) {
    return apps.where((app) => app.permissions.contains(permission)).length;
  }
}
