import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/screens/about_screen.dart';
import 'package:permission_scanner/screens/apk_scanner_screen.dart';
import 'package:permission_scanner/screens/permission_info_screen.dart';
import 'package:permission_scanner/screens/privacy_policy_screen.dart';
import 'package:permission_scanner/screens/privacy_timeline_screen.dart';
import 'package:permission_scanner/services/app_providers.dart';
import 'package:permission_scanner/services/notification_service.dart';
import 'package:permission_scanner/services/permission_scanner_service.dart';
import 'package:permission_scanner/services/privacy_assistant_service.dart';
import 'package:permission_scanner/utils/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyToolsScreen extends ConsumerWidget {
  const PrivacyToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(installedAppsProvider);
    final changesAsync = ref.watch(permissionChangeEventsProvider);

    return appsAsync.when(
      data: (apps) {
        final changes = changesAsync.valueOrNull ?? [];
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            _toolTile(
              context,
              icon: Icons.upload_file_rounded,
              title: 'APK Scanner',
              subtitle: 'Scan APK files before installation',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ApkScannerScreen()),
              ),
            ),
            _toolTile(
              context,
              icon: Icons.timeline_rounded,
              title: 'Permission Timeline',
              subtitle: 'Camera, microphone, location, and update history',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PrivacyTimelineScreen(),
                ),
              ),
            ),
            _toolTile(
              context,
              icon: Icons.menu_book_rounded,
              title: 'Permission Library',
              subtitle: 'Simple explanations for Android permissions',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PermissionInfoScreen()),
              ),
            ),
            const SizedBox(height: 18),
            _reportPanel(context, apps, changes),
            const SizedBox(height: 18),
            _transparencyPanel(context),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Unable to load tools: $error')),
    );
  }

  Widget _toolTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _reportPanel(
    BuildContext context,
    List<AppInfo> apps,
    List<PermissionChangeEvent> changes,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Export & Share Reports',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _exportJson(context, apps, changes),
                  icon: const Icon(Icons.data_object_rounded, size: 18),
                  label: const Text('Save JSON'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _exportPdf(context, apps, changes),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: const Text('Save PDF'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => PermissionScannerService().shareText(
                title: 'Permission Scanner summary',
                text: PrivacyAssistantService.buildDeviceShareSummary(apps),
              ),
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: const Text('Share Security Summary'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _transparencyPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Open Source Transparency',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _trustRow('Open-source status', 'Public repository available'),
          _trustRow('F-Droid availability', 'Not verified in this build'),
          _trustRow('Privacy policy', 'Bundled policy detected'),
          _trustRow('Developer trust score', '82/100'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                ),
                icon: const Icon(Icons.info_outline_rounded, size: 18),
                label: const Text('About Us'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen(),
                  ),
                ),
                icon: const Icon(Icons.privacy_tip_outlined, size: 18),
                label: const Text('View Privacy Policy'),
              ),
              OutlinedButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(
                    'https://github.com/AHS-Mobile-Labs/Permission_Scanner',
                  ),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.code_rounded, size: 18),
                label: const Text('GitHub Repository'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trustRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportJson(
    BuildContext context,
    List<AppInfo> apps,
    List<PermissionChangeEvent> changes,
  ) async {
    final report = const JsonEncoder.withIndent(
      '  ',
    ).convert(_buildReport(apps, changes));
    final path = await PermissionScannerService().exportJsonReport(report);
    if (!context.mounted) return;
    await _showDownloadResult(
      context,
      path: path,
      fileType: 'JSON',
      failureMessage: 'Could not save JSON report',
    );
  }

  Future<void> _exportPdf(
    BuildContext context,
    List<AppInfo> apps,
    List<PermissionChangeEvent> changes,
  ) async {
    final report = jsonEncode(_buildReport(apps, changes));
    final path = await PermissionScannerService().exportPdfReport(report);
    if (!context.mounted) return;
    await _showDownloadResult(
      context,
      path: path,
      fileType: 'PDF',
      failureMessage: 'Could not save PDF report',
    );
  }

  Future<void> _showDownloadResult(
    BuildContext context, {
    required String? path,
    required String fileType,
    required String failureMessage,
  }) async {
    if (!context.mounted) return;
    final saved = path != null && path.isNotEmpty;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved ? '$fileType report saved to $path' : failureMessage,
        ),
      ),
    );
    if (!saved) return;

    await NotificationService().showNotification(
      title: '$fileType report downloaded',
      body: 'Saved to $path',
      id: 'report_$fileType$path',
    );
  }

  Map<String, dynamic> _buildReport(
    List<AppInfo> apps,
    List<PermissionChangeEvent> changes,
  ) {
    final topRisk = List<AppInfo>.from(apps)
      ..sort((a, b) {
        final riskCompare = a.riskLevel.sortRank.compareTo(
          b.riskLevel.sortRank,
        );
        if (riskCompare != 0) return riskCompare;
        return a.privacyScore.compareTo(b.privacyScore);
      });
    final score = apps.isEmpty
        ? 100
        : (apps.fold<int>(0, (sum, app) => sum + app.privacyScore) /
                  apps.length)
              .round();
    final totalTrackers = apps.fold<int>(
      0,
      (sum, app) => sum + app.trackers.length,
    );

    return {
      'generatedAt': DateTime.now().toIso8601String(),
      'deviceScore': score,
      'totalApps': apps.length,
      'totalTrackers': totalTrackers,
      'permissionChanges': changes.length,
      'topRiskApps': topRisk
          .take(10)
          .map(
            (app) => {
              'appName': app.appName,
              'packageName': app.packageName,
              'score': app.privacyScore,
              'risk': app.riskLevel.label,
              'permissions': app.permissions.length,
              'dangerousPermissions': app.dangerousPermissionCount,
              'trackers': app.trackers.length,
              'signals': app.riskSignals.map((signal) => signal.title).toList(),
            },
          )
          .toList(),
      'recentPermissionChanges': changes
          .map(
            (event) => {
              'appName': event.appName,
              'packageName': event.packageName,
              'addedPermissions': event.addedPermissions,
              'removedPermissions': event.removedPermissions,
              'beforeScore': event.beforeScore,
              'afterScore': event.afterScore,
              'detectedAt': event.detectedAt.toIso8601String(),
            },
          )
          .toList(),
      'recommendations': [
        'Disable unused sensitive permissions.',
        'Restrict background activity for apps that do not need live updates.',
        'Remove apps with accessibility, overlay, SMS, and hidden launcher combinations.',
        'Prefer open-source or privacy-focused alternatives when tracker count is high.',
      ],
    };
  }
}
