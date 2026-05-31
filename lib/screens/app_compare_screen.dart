import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/services/app_providers.dart';
import 'package:permission_scanner/utils/app_colors.dart';
import 'package:permission_scanner/widgets/risk_badge.dart';

class AppCompareScreen extends ConsumerStatefulWidget {
  const AppCompareScreen({super.key});

  @override
  ConsumerState<AppCompareScreen> createState() => _AppCompareScreenState();
}

class _AppCompareScreenState extends ConsumerState<AppCompareScreen> {
  String? _leftPackage;
  String? _rightPackage;

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(installedAppsProvider);

    return appsAsync.when(
      data: (apps) {
        final sorted = List<AppInfo>.from(apps)
          ..sort((a, b) => a.appName.compareTo(b.appName));
        if (sorted.isEmpty) {
          return const Center(child: Text('No apps available'));
        }
        _leftPackage ??= sorted.first.packageName;
        _rightPackage ??= sorted.length > 1
            ? sorted[1].packageName
            : sorted.first.packageName;
        final left = sorted.firstWhere(
          (app) => app.packageName == _leftPackage,
          orElse: () => sorted.first,
        );
        final right = sorted.firstWhere(
          (app) => app.packageName == _rightPackage,
          orElse: () => sorted.first,
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Row(
              children: [
                Expanded(
                  child: _appPicker(
                    sorted,
                    _leftPackage,
                    (value) => setState(() => _leftPackage = value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _appPicker(
                    sorted,
                    _rightPackage,
                    (value) => setState(() => _rightPackage = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _summaryCard(left)),
                const SizedBox(width: 10),
                Expanded(child: _summaryCard(right)),
              ],
            ),
            const SizedBox(height: 16),
            _comparisonTable(left, right),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Unable to load apps: $error')),
    );
  }

  Widget _appPicker(
    List<AppInfo> apps,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: apps
              .map(
                (app) => DropdownMenuItem(
                  value: app.packageName,
                  child: Text(
                    app.appName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _summaryCard(AppInfo app) {
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
          Text(
            app.appName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          RiskBadge(riskLevel: app.riskLevel),
          const SizedBox(height: 14),
          Text(
            '${app.privacyScore}/100',
            style: TextStyle(
              color: _scoreColor(app.privacyScore),
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Privacy score',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonTable(AppInfo left, AppInfo right) {
    final rows = [
      _MetricRow(
        'Permission count',
        left.permissions.length.toString(),
        right.permissions.length.toString(),
      ),
      _MetricRow(
        'Dangerous permissions',
        left.dangerousPermissionCount.toString(),
        right.dangerousPermissionCount.toString(),
      ),
      _MetricRow(
        'Tracker count',
        left.trackers.length.toString(),
        right.trackers.length.toString(),
      ),
      _MetricRow(
        'Background services',
        left.serviceCount.toString(),
        right.serviceCount.toString(),
      ),
      _MetricRow(
        'Auto-start behavior',
        left.runsAtBoot ? 'Yes' : 'No',
        right.runsAtBoot ? 'Yes' : 'No',
      ),
      _MetricRow(
        'Internet data risk',
        _internetRisk(left),
        _internetRisk(right),
      ),
      _MetricRow(
        'Open source status',
        _openSourceStatus(left),
        _openSourceStatus(right),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(children: rows.map((row) => _tableRow(row)).toList()),
    );
  }

  Widget _tableRow(_MetricRow row) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.label,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: _valueText(row.left)),
          Expanded(child: _valueText(row.right)),
        ],
      ),
    );
  }

  Widget _valueText(String value) {
    return Text(
      value,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.textDark,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  String _internetRisk(AppInfo app) {
    if (!app.hasInternetAccess) return 'Offline';
    if (app.contactsInternetCombo || app.smsCallInternetCombo) return 'High';
    if (app.trackers.isNotEmpty) return 'Medium';
    return 'Low';
  }

  String _openSourceStatus(AppInfo app) {
    final package = app.packageName.toLowerCase();
    if (package.contains('signal') ||
        package.contains('fdroid') ||
        package.contains('mozilla')) {
      return 'Likely open';
    }
    return app.installSource == 'Unknown' ? 'Unknown' : 'Not verified';
  }

  Color _scoreColor(int score) {
    if (score >= 85) return AppColors.riskSafe;
    if (score >= 65) return AppColors.riskMedium;
    if (score >= 40) return AppColors.riskDangerous;
    return AppColors.riskCritical;
  }
}

class _MetricRow {
  final String label;
  final String left;
  final String right;

  const _MetricRow(this.label, this.left, this.right);
}
