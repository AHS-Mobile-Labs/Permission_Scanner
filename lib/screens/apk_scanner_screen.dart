import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/services/permission_analyzer.dart';
import 'package:permission_scanner/services/permission_scanner_service.dart';
import 'package:permission_scanner/utils/app_colors.dart';
import 'package:permission_scanner/utils/sdk_display.dart';
import 'package:permission_scanner/utils/permission_database.dart';
import 'package:permission_scanner/widgets/risk_badge.dart';

class ApkScannerScreen extends StatefulWidget {
  const ApkScannerScreen({super.key});

  @override
  State<ApkScannerScreen> createState() => _ApkScannerScreenState();
}

class _ApkScannerScreenState extends State<ApkScannerScreen> {
  final _pathController = TextEditingController();
  AppInfo? _result;
  bool _scanning = false;

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _pickAndScan() async {
    setState(() => _scanning = true);
    final scanned = await PermissionScannerService().pickAndScanApk();
    final enriched = scanned == null
        ? null
        : await compute(_enrichApk, scanned);
    if (!mounted) return;
    setState(() {
      _result = enriched;
      _scanning = false;
    });
  }

  Future<void> _scanPath() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) return;
    setState(() => _scanning = true);
    final scanned = await PermissionScannerService().scanApk(path);
    final enriched = scanned == null
        ? null
        : await compute(_enrichApk, scanned);
    if (!mounted) return;
    setState(() {
      _result = enriched;
      _scanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('APK Scanner')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Container(
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
                  'Scan before install',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Analyze permissions, trackers, packers, overlays, background behavior, and spyware indicators without installing the APK.',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _scanning ? null : _pickAndScan,
                  icon: _scanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_rounded),
                  label: Text(_scanning ? 'Scanning...' : 'Choose APK'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pathController,
                  decoration: InputDecoration(
                    hintText: '/storage/emulated/0/Download/app.apk',
                    suffixIcon: IconButton(
                      onPressed: _scanning ? null : _scanPath,
                      icon: const Icon(Icons.search_rounded),
                      tooltip: 'Scan path',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_result != null) _resultCard(_result!),
        ],
      ),
    );
  }

  Widget _resultCard(AppInfo app) {
    final dangerousPermissionsFound = app.permissions
        .where((permission) => dangerousPermissions.contains(permission))
        .toList();
    final otherPermissions = app.permissions
        .where(
          (permission) =>
              !dangerousPermissions.contains(permission) &&
              !permissionDatabase.containsKey(permission),
        )
        .toList();

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
          Row(
            children: [
              Expanded(
                child: Text(
                  app.appName,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              RiskBadge(riskLevel: app.riskLevel),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            app.packageName,
            style: const TextStyle(color: AppColors.textLight, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('${app.privacyScore}/100 score', AppColors.primary),
              _chip(
                '${app.dangerousPermissionCount} dangerous',
                AppColors.riskDangerous,
              ),
              _chip('${app.trackers.length} SDKs', AppColors.secondary),
              if (app.usesKnownPacker)
                _chip('Packed APK', AppColors.riskMedium),
              if (app.requestsOverlayPermission)
                _chip('Overlay', AppColors.riskDangerous),
              if (app.declaresAccessibilityService)
                _chip('Accessibility', AppColors.riskCritical),
              if (app.staticFindings.isNotEmpty)
                _chip(
                  '${app.staticFindings.length} static signals',
                  AppColors.riskDangerous,
                ),
            ],
          ),

          const SizedBox(height: 16),
          _sectionBlock('APK Identity', [
            _detailRow('Package', app.packageName, monospace: true),
            _detailRow('App size', _formatBytes(app.apkSizeBytes)),
            _detailRow(
              'APK SHA-256',
              _shortHash(app.apkSha256),
              monospace: true,
            ),
            _detailRow(
              'Signer SHA-256',
              app.signerSha256Digests.isEmpty
                  ? 'Unavailable'
                  : _shortHash(app.signerSha256Digests.first),
              monospace: true,
            ),
            if (app.signerSha256Digests.length > 1)
              _detailRow(
                'Extra signers',
                '${app.signerSha256Digests.length - 1} more certificate digests',
              ),
            const SizedBox(height: 8),
            _sdkSummary(app),
          ]),

          _sectionBlock('Component Surface', [
            _metricGrid({
              'Permissions': '${app.permissions.length}',
              'Dangerous': '${app.dangerousPermissionCount}',
              'Activities': '${app.activityCount}',
              'Services': '${app.serviceCount}',
              'Receivers': '${app.receiverCount}',
              'Providers': '${app.providerCount}',
              'DEX files': '${app.dexFileCount}',
              'Native libs': '${app.nativeLibraryCount}',
              'Assets': '${app.assetFileCount}',
              'APK files': '${app.apkFileCount}',
            }),
            if (app.nativeArchitectures.isNotEmpty) ...[
              const SizedBox(height: 10),
              _detailRow('Native ABIs', app.nativeArchitectures.join(', ')),
            ],
            if (app.staticAnalysisLimitReached) ...[
              const SizedBox(height: 10),
              _warningBanner(
                'Scan limit reached. Results are still useful, but this APK has more code/resources than the bounded offline scan fully inspected.',
              ),
            ],
          ]),

          _sectionBlock(
            'Risk Findings',
            app.riskSignals.isEmpty
                ? [
                    const Text(
                      'No major risk signals were detected.',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ]
                : app.riskSignals.take(12).map(_riskSignalRow).toList(),
          ),

          if (app.staticFindings.isNotEmpty)
            _sectionBlock(
              'Static Indicators',
              app.staticFindings.map(_staticFindingRow).toList(),
            ),

          _sectionBlock(
            'Trackers & SDKs',
            app.trackers.isEmpty
                ? [
                    _warningBanner(
                      app.staticAnalysisLimitReached
                          ? 'No known tracker SDKs matched before the scan limit was reached. Treat this as inconclusive, not clean.'
                          : 'No known tracker SDK signatures matched in the bounded offline scan.',
                    ),
                  ]
                : app.trackers.map(_trackerRow).toList(),
          ),

          _sectionBlock('Permissions', [
            _permissionSummary(
              app.permissions.length,
              dangerousPermissionsFound.length,
              otherPermissions.length,
            ),
            if (dangerousPermissionsFound.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Sensitive permissions',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: dangerousPermissionsFound
                    .map(
                      (permission) => _permissionChip(
                        _permissionLabel(permission),
                        AppColors.riskDangerous,
                      ),
                    )
                    .toList(),
              ),
            ],
            if (otherPermissions.isNotEmpty) ...[
              const SizedBox(height: 10),
              _detailRow(
                'Custom/other',
                otherPermissions.take(4).map(_permissionLabel).join(', '),
              ),
            ],
          ]),
        ],
      ),
    );
  }

  Widget _sectionBlock(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _metricGrid(Map<String, String> metrics) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: metrics.entries
              .map(
                (entry) => SizedBox(
                  width: width,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.value,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.key,
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _sdkSummary(AppInfo app) {
    final targetColor = _sdkStatusColor(app.targetSdkVersion);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
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
                size: 17,
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'Android SDK Profile',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _chip(
                SdkDisplay.targetPosture(app.targetSdkVersion),
                targetColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _sdkMiniStat(
                  'Target',
                  SdkDisplay.apiValue(app.targetSdkVersion),
                  targetColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _sdkMiniStat(
                  'Minimum',
                  SdkDisplay.apiValue(app.minSdkVersion),
                  AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _detailRow(
            'Compiled',
            SdkDisplay.compileValue(
              app.compileSdkVersion,
              app.compileSdkCodename,
            ),
          ),
          _detailRow(
            'Target note',
            SdkDisplay.targetNote(app.targetSdkVersion),
          ),
        ],
      ),
    );
  }

  Widget _sdkMiniStat(String label, String value, Color color) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool monospace = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Unavailable' : value,
              style: TextStyle(
                color: AppColors.textMedium,
                fontSize: 12,
                height: 1.3,
                fontFamily: monospace ? 'monospace' : null,
                fontWeight: monospace ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _riskSignalRow(RiskSignal signal) {
    final color = _severityColor(signal.severity);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_rounded, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  signal.title,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  signal.description,
                  style: const TextStyle(
                    color: AppColors.textMedium,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _staticFindingRow(StaticScanFinding finding) {
    final color = _severityColor(finding.severity);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _severityPill(finding.severity, color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  finding.title,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            finding.description,
            style: const TextStyle(
              color: AppColors.textMedium,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          if (finding.evidence.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              finding.evidence,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _trackerRow(TrackerInfo tracker) {
    final color = _trackerRiskColor(tracker.riskWeight);
    final confidence = tracker.confidence > 0
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
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.hub_rounded, color: color, size: 17),
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
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _severityPill(confidence, color),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${tracker.category} · ${_trackerRiskLabel(tracker.riskWeight)}',
                  style: TextStyle(
                    color: color,
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

  Widget _permissionSummary(int total, int dangerous, int other) {
    return Row(
      children: [
        Expanded(child: _miniStat('Total', '$total', AppColors.primary)),
        const SizedBox(width: 8),
        Expanded(
          child: _miniStat('Sensitive', '$dangerous', AppColors.riskDangerous),
        ),
        const SizedBox(width: 8),
        Expanded(child: _miniStat('Other', '$other', AppColors.textLight)),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
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

  Widget _warningBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.riskMediumContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.riskMedium.withValues(alpha: 0.25)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.textMedium,
          fontSize: 12,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _severityPill(String severity, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _permissionChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Color _severityColor(String severity) {
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

  Color _sdkStatusColor(int targetApi) {
    if (targetApi <= 0) return AppColors.textLight;
    if (targetApi >= 35) return AppColors.riskSafe;
    if (targetApi >= 33) return AppColors.primary;
    if (targetApi >= 29) return AppColors.riskMedium;
    return AppColors.riskDangerous;
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

  String _permissionLabel(String permission) {
    return permissionDatabase[permission]?.displayName ??
        permission.split('.').last.replaceAll('_', ' ');
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return 'Unavailable';
    const units = ['B', 'KB', 'MB', 'GB'];
    var value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    final precision = unitIndex == 0 ? 0 : 1;
    return '${value.toStringAsFixed(precision)} ${units[unitIndex]}';
  }

  String _shortHash(String hash) {
    if (hash.isEmpty) return 'Unavailable';
    if (hash.length <= 28) return hash;
    return '${hash.substring(0, 14)}...${hash.substring(hash.length - 14)}';
  }
}

AppInfo _enrichApk(AppInfo app) => PermissionAnalyzer.enrichAppInfo(app);
