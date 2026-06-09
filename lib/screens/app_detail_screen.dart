import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/utils/app_colors.dart';
import 'package:permission_scanner/utils/sdk_display.dart';
import 'package:permission_scanner/utils/permission_database.dart';
import 'package:permission_scanner/widgets/permission_item.dart';
import 'package:permission_scanner/widgets/risk_badge.dart';
import 'package:permission_scanner/widgets/permission_verification_dialog.dart';
import 'package:permission_scanner/services/permission_justification_service.dart';
import 'package:permission_scanner/services/cache_service.dart';
import 'package:permission_scanner/services/privacy_assistant_service.dart';
import 'package:permission_scanner/services/permission_scanner_service.dart';

class AppDetailScreen extends ConsumerStatefulWidget {
  final AppInfo app;

  const AppDetailScreen({super.key, required this.app});

  @override
  ConsumerState<AppDetailScreen> createState() => _AppDetailScreenState();
}

class _AppDetailScreenState extends ConsumerState<AppDetailScreen> {
  late CacheService cacheService;
  late List<String> appCapabilities;
  late Map<String, dynamic> permissionAnalysis;
  bool showDeveloperPermissions = false;

  @override
  void initState() {
    super.initState();
    cacheService = CacheService();
    appCapabilities = [];
    permissionAnalysis = {
      'justifiedPermissions': <String>[],
      'unjustifiedPermissions': <String>[],
      'justifiedCount': 0,
      'unjustifiedCount': 0,
    };
    _initializeData();
  }

  void _initializeData() async {
    await cacheService.init();
    appCapabilities = await cacheService.getAppCapabilities(
      widget.app.packageName,
    );
    permissionAnalysis = PermissionJustificationService.analyzePermissions(
      widget.app.permissions,
      appCapabilities,
    );
    if (!mounted) return;
    setState(() {});
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (_) => PermissionVerificationDialog(
        app: widget.app,
        cacheService: cacheService,
      ),
    ).then((result) {
      if (!mounted) return;
      if (result != null) {
        appCapabilities = result;
        permissionAnalysis = PermissionJustificationService.analyzePermissions(
          widget.app.permissions,
          appCapabilities,
        );
        setState(() {});
      }
    });
  }

  Future<void> _shareAppReport() async {
    final summary = PrivacyAssistantService.buildPlainLanguageSummary(
      widget.app,
    );
    await PermissionScannerService().shareText(
      title: '${widget.app.appName} privacy report',
      text: summary,
    );
  }

  List<String> _getFilteredPermissions() {
    if (showDeveloperPermissions) {
      return widget.app.permissions;
    }
    return widget.app.permissions.where((permission) {
      return dangerousPermissions.contains(permission) ||
          permissionDatabase.containsKey(permission);
    }).toList();
  }

  List<String> _getDangerousPerms(List<String> perms) =>
      perms.where((p) => dangerousPermissions.contains(p)).toList();

  List<String> _getNormalPerms(List<String> perms) => perms
      .where(
        (p) =>
            !dangerousPermissions.contains(p) &&
            permissionDatabase.containsKey(p),
      )
      .toList();

  List<String> _getOtherPerms(List<String> perms) => perms
      .where(
        (p) =>
            !dangerousPermissions.contains(p) &&
            !permissionDatabase.containsKey(p),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    final filteredPerms = _getFilteredPermissions();
    final dangerousPerms = _getDangerousPerms(filteredPerms);
    final normalPerms = _getNormalPerms(filteredPerms);
    final otherPerms = showDeveloperPermissions
        ? _getOtherPerms(filteredPerms)
        : <String>[];

    return Scaffold(
      appBar: AppBar(title: const Text('App Details')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // App header card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  // App icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child:
                        widget.app.iconPath != null &&
                            widget.app.iconPath!.isNotEmpty &&
                            widget.app.iconPath!.startsWith('/')
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(
                              File(widget.app.iconPath!),
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.medium,
                              cacheWidth: 144,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.apps_rounded,
                                size: 36,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.apps_rounded,
                            size: 36,
                            color: AppColors.primary,
                          ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.app.appName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      letterSpacing: 0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.app.packageName,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  // Info chips row
                  Row(
                    children: [
                      Expanded(
                        child: _infoChip(
                          '${widget.app.permissions.length}',
                          'Total',
                          AppColors.primary,
                          AppColors.primaryContainer,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _infoChip(
                          '${widget.app.dangerousPermissionCount}',
                          'Dangerous',
                          AppColors.riskDangerous,
                          AppColors.riskDangerousContainer,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _riskBgColor(widget.app.riskLevel),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              RiskBadge(riskLevel: widget.app.riskLevel),
                              const SizedBox(height: 4),
                              const Text(
                                'Risk Level',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Verify button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _showVerificationDialog,
                      icon: const Icon(Icons.verified_user_rounded, size: 18),
                      label: const Text('Verify App'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            _buildIntelligencePanel(),
            _buildSdkPanel(),
            _buildAssistantPanel(),
            _buildTrackerPanel(),
            if (widget.app.malwareIndicators.isNotEmpty) _buildMalwarePanel(),

            // Verified capabilities
            if (appCapabilities.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.riskSafeContainer,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.riskSafe.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.riskSafe,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Verified Capabilities',
                            style: TextStyle(
                              color: AppColors.riskSafe,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${permissionAnalysis['justifiedCount']}/${widget.app.permissions.length} justified',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.riskSafe,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: appCapabilities
                            .map(
                              (cap) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  cap,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.riskSafe,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),

            // Permissions header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Permissions (${filteredPerms.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        showDeveloperPermissions = !showDeveloperPermissions;
                      });
                    },
                    icon: Icon(
                      showDeveloperPermissions
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 16,
                    ),
                    label: Text(
                      showDeveloperPermissions ? 'Hide Dev' : 'Show Dev',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textMedium,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),

            // Dangerous permissions section
            if (dangerousPerms.isNotEmpty) ...[
              _sectionHeader(
                'Dangerous',
                dangerousPerms.length,
                AppColors.riskDangerous,
                Icons.error_rounded,
              ),
              ...dangerousPerms.map(
                (permName) => _buildPermissionRow(permName),
              ),
            ],

            // Normal permissions section
            if (normalPerms.isNotEmpty) ...[
              _sectionHeader(
                'Standard',
                normalPerms.length,
                AppColors.riskSafe,
                Icons.check_circle_rounded,
              ),
              ...normalPerms.map((permName) => _buildPermissionRow(permName)),
            ],

            // Other permissions (dev mode)
            if (otherPerms.isNotEmpty) ...[
              _sectionHeader(
                'Other',
                otherPerms.length,
                AppColors.textLight,
                Icons.code_rounded,
              ),
              ...otherPerms.map((permName) => _buildUnknownPermRow(permName)),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildIntelligencePanel() {
    final signals = widget.app.riskSignals.take(5).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _scoreRing(widget.app.privacyScore, 58),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Privacy Intelligence',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.app.trackers.length} SDKs · ${widget.app.serviceCount} services · ${widget.app.receiverCount} receivers',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _shareAppReport,
                  icon: const Icon(Icons.ios_share_rounded, size: 20),
                  tooltip: 'Share report',
                ),
              ],
            ),
            if (signals.isNotEmpty) ...[
              const SizedBox(height: 14),
              ...signals.map(_signalRow),
            ] else ...[
              const SizedBox(height: 12),
              const Text(
                'No major risk signals detected by the offline scanner.',
                style: TextStyle(
                  color: AppColors.textMedium,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSdkPanel() {
    final app = widget.app;
    final targetColor = _sdkStatusColor(app.targetSdkVersion);
    final compileValue = SdkDisplay.compileValue(
      app.compileSdkVersion,
      app.compileSdkCodename,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.android_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Android SDK Profile',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                _sdkStatusPill(
                  SdkDisplay.targetPosture(app.targetSdkVersion),
                  targetColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _sdkTile(
                      'Target',
                      SdkDisplay.apiValue(app.targetSdkVersion),
                      targetColor,
                      width,
                    ),
                    _sdkTile(
                      'Minimum',
                      SdkDisplay.apiValue(app.minSdkVersion),
                      AppColors.primary,
                      width,
                    ),
                    _sdkTile(
                      'Compiled With',
                      compileValue,
                      AppColors.textMedium,
                      width,
                    ),
                    _sdkTile(
                      'Compatibility',
                      app.minSdkVersion > 0 && app.targetSdkVersion > 0
                          ? '${SdkDisplay.compactApiValue(app.minSdkVersion)} to ${SdkDisplay.compactApiValue(app.targetSdkVersion)}'
                          : 'Range unavailable',
                      AppColors.secondary,
                      width,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              SdkDisplay.targetNote(app.targetSdkVersion),
              style: const TextStyle(
                color: AppColors.textMedium,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssistantPanel() {
    final summary = PrivacyAssistantService.buildPlainLanguageSummary(
      widget.app,
    );
    final recommendations = PrivacyAssistantService.recommendations(widget.app);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.12),
              AppColors.secondary.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.psychology_alt_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'AI Privacy Assistant',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              summary.split('\n').first,
              style: const TextStyle(
                color: AppColors.textMedium,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            ...recommendations
                .take(3)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                          size: 15,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackerPanel() {
    final categoryCounts = <String, int>{};
    for (final tracker in widget.app.trackers) {
      categoryCounts[tracker.category] =
          (categoryCounts[tracker.category] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.radar_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Tracker & SDK Scanner',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                _sdkStatusPill(
                  '${widget.app.trackers.length} found',
                  widget.app.trackers.isEmpty
                      ? AppColors.riskSafe
                      : AppColors.secondary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.app.trackers.isEmpty) ...[
              const Text(
                'No known tracker SDK signatures were found in the latest scan.',
                style: TextStyle(
                  color: AppColors.textMedium,
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.app.staticAnalysisLimitReached) ...[
                const SizedBox(height: 8),
                const Text(
                  'The APK scan hit its safety limit, so absence of a match is not a guarantee.',
                  style: TextStyle(
                    color: AppColors.riskMedium,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ] else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categoryCounts.entries
                    .map(
                      (entry) => _categoryPill(
                        '${entry.key} ${entry.value}',
                        AppColors.secondary,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              ...widget.app.trackers.map(_trackerSdkCard),
            ],
          ],
        ),
      ),
    );
  }

  Widget _trackerSdkCard(TrackerInfo tracker) {
    final riskColor = _trackerRiskColor(tracker.riskWeight);
    final confidenceLabel = tracker.confidence > 0
        ? '${tracker.confidence}% match'
        : 'Inferred';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.hub_rounded, color: riskColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tracker.name,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _categoryPill(confidenceLabel, riskColor),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${tracker.category} · ${_trackerRiskLabel(tracker.riskWeight)}',
                  style: TextStyle(
                    color: riskColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tracker.purpose,
                  style: const TextStyle(
                    color: AppColors.textMedium,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                if (tracker.evidence.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    tracker.evidence,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  Color _trackerRiskColor(int weight) {
    if (weight >= 8) return AppColors.riskDangerous;
    if (weight >= 6) return AppColors.riskMedium;
    return AppColors.primary;
  }

  String _trackerRiskLabel(int weight) {
    if (weight >= 8) return 'high privacy impact';
    if (weight >= 6) return 'medium privacy impact';
    return 'low privacy impact';
  }

  Widget _buildMalwarePanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.riskCriticalContainer.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.riskCritical.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.gpp_bad_rounded,
                  color: AppColors.riskCritical,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Malware & Spyware Warnings',
                  style: TextStyle(
                    color: AppColors.riskCritical,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...widget.app.malwareIndicators.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  item,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sdkTile(String label, String value, Color color, double width) {
    return SizedBox(
      width: width,
      child: Container(
        constraints: const BoxConstraints(minHeight: 78),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sdkStatusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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

  Widget _scoreRing(int score, double size) {
    final color = _scoreColor(score);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score / 100),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: 5,
                strokeCap: StrokeCap.round,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation(color),
              ),
              Text(
                '${(value * 100).round()}',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _signalRow(RiskSignal signal) {
    final color = _signalColor(signal.severity);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.bolt_rounded, color: color, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  signal.title,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  signal.description,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 85) return AppColors.riskSafe;
    if (score >= 65) return AppColors.riskMedium;
    if (score >= 40) return AppColors.riskDangerous;
    return AppColors.riskCritical;
  }

  Color _sdkStatusColor(int targetApi) {
    if (targetApi <= 0) return AppColors.textLight;
    if (targetApi >= 35) return AppColors.riskSafe;
    if (targetApi >= 33) return AppColors.primary;
    if (targetApi >= 29) return AppColors.riskMedium;
    return AppColors.riskDangerous;
  }

  Color _signalColor(String severity) {
    switch (severity) {
      case 'critical':
        return AppColors.riskCritical;
      case 'high':
        return AppColors.riskDangerous;
      case 'medium':
        return AppColors.riskMedium;
      default:
        return AppColors.primary;
    }
  }

  Widget _infoChip(String value, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _riskBgColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe:
        return AppColors.riskSafeContainer;
      case RiskLevel.medium:
        return AppColors.riskMediumContainer;
      case RiskLevel.high:
        return AppColors.riskDangerousContainer;
      case RiskLevel.critical:
        return AppColors.riskCriticalContainer;
    }
  }

  Widget _sectionHeader(String title, int count, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$title ($count)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(String permissionName) {
    final permissionInfo = permissionDatabase[permissionName];
    final isJustified =
        (permissionAnalysis['justifiedPermissions'] as List<String>).contains(
          permissionName,
        );

    if (permissionInfo == null) {
      return _buildUnknownPermRow(permissionName, isJustified: isJustified);
    }

    return PermissionItem(permission: permissionInfo, isJustified: isJustified);
  }

  Widget _buildUnknownPermRow(
    String permissionName, {
    bool isJustified = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isJustified
              ? AppColors.riskSafeContainer.withValues(alpha: 0.5)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.extension_rounded,
                size: 18,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(width: 12),
            if (isJustified)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: AppColors.riskSafe,
                ),
              ),
            Expanded(
              child: Text(
                permissionName.split('.').last,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
