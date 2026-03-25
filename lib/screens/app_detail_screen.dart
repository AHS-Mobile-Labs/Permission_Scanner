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
    _initializeData();
  }

  void _initializeData() async {
    await cacheService.init();
    appCapabilities = cacheService.getAppCapabilities(widget.app.packageName);
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
    // Normal mode: show only dangerous/privacy-sensitive permissions
    return widget.app.permissions.where((permission) {
      return dangerousPermissions.contains(permission) ||
          permissionDatabase.containsKey(permission);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Details'), elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child:
                        widget.app.iconPath != null &&
                            widget.app.iconPath!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              _decodeBase64Icon(widget.app.iconPath!),
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.apps,
                                    size: 40,
                                    color: AppColors.primary,
                                  ),
                            ),
                          )
                        : Icon(Icons.apps, size: 40, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.app.appName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.app.packageName,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            '${widget.app.permissions.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Total Permissions',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 40),
                      Column(
                        children: [
                          Text(
                            '${widget.app.dangerousPermissionCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Dangerous',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 40),
                      Column(
                        children: [
                          RiskBadge(riskLevel: widget.app.riskLevel),
                          const SizedBox(height: 4),
                          Text(
                            'Risk Level',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showVerificationDialog,
                    icon: const Icon(Icons.verified_user),
                    label: const Text('Verify App'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (appCapabilities.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '✅ Verified App Capabilities',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: appCapabilities
                            .map(
                              (cap) => Chip(
                                label: Text(cap),
                                backgroundColor: Colors.green.shade100,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Justified Permissions: ${permissionAnalysis['justifiedCount']}/${widget.app.permissions.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Permissions (${_getFilteredPermissions().length})',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(fontSize: 16),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        showDeveloperPermissions = !showDeveloperPermissions;
                      });
                    },
                    icon: Icon(
                      showDeveloperPermissions
                          ? Icons.arrow_drop_up
                          : Icons.arrow_drop_down,
                    ),
                    label: const Text('Dev Permissions'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _getFilteredPermissions().length,
              itemBuilder: (context, index) {
                final filteredPermissions = _getFilteredPermissions();
                final permissionName = filteredPermissions[index];

                final permissionInfo = permissionDatabase[permissionName];
                final isJustified =
                    (permissionAnalysis['justifiedPermissions'] as List<String>)
                        .contains(permissionName);

                if (permissionInfo == null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Card(
                      color: isJustified ? Colors.green.shade50 : null,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            if (isJustified)
                              const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Text('✅'),
                              ),
                            Expanded(
                              child: Text(
                                permissionName,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return GestureDetector(
                  child: Container(
                    color: isJustified ? Colors.green.shade50 : null,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: PermissionItem(permission: permissionInfo),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
