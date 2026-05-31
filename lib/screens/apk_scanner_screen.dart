import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/services/permission_analyzer.dart';
import 'package:permission_scanner/services/permission_scanner_service.dart';
import 'package:permission_scanner/utils/app_colors.dart';
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
              _chip('${app.trackers.length} trackers', AppColors.secondary),
              if (app.usesKnownPacker)
                _chip('Packed APK', AppColors.riskMedium),
              if (app.requestsOverlayPermission)
                _chip('Overlay', AppColors.riskDangerous),
              if (app.declaresAccessibilityService)
                _chip('Accessibility', AppColors.riskCritical),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Findings',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (app.riskSignals.isEmpty)
            const Text(
              'No major risk signals were detected.',
              style: TextStyle(color: AppColors.textLight, fontSize: 12),
            )
          else
            ...app.riskSignals
                .take(8)
                .map(
                  (signal) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${signal.title}: ${signal.description}',
                      style: const TextStyle(
                        color: AppColors.textMedium,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
        ],
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
}

AppInfo _enrichApk(AppInfo app) => PermissionAnalyzer.enrichAppInfo(app);
