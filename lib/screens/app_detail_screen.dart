import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/utils/app_colors.dart';
import 'package:permission_scanner/utils/permission_database.dart';
import 'package:permission_scanner/widgets/permission_item.dart';
import 'package:permission_scanner/widgets/risk_badge.dart';
import 'package:permission_scanner/widgets/permission_verification_dialog.dart';
import 'package:permission_scanner/services/permission_justification_service.dart';
import 'package:permission_scanner/services/cache_service.dart';

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

  static Uint8List _decodeBase64Icon(String base64String) {
    return base64Decode(base64String);
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
                            widget.app.iconPath!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.memory(
                              _decodeBase64Icon(widget.app.iconPath!),
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
                      letterSpacing: -0.3,
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
              letterSpacing: -0.5,
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
      case RiskLevel.dangerous:
        return AppColors.riskDangerousContainer;
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
