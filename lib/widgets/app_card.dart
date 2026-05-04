import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/utils/app_colors.dart';
import 'package:permission_scanner/widgets/risk_badge.dart';

class AppCard extends StatelessWidget {
  final AppInfo app;
  final VoidCallback onTap;

  const AppCard({super.key, required this.app, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dangerousRatio = app.permissions.isEmpty
        ? 0.0
        : app.dangerousPermissionCount / app.permissions.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // App Icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 48,
                    height: 48,
                    color: AppColors.surfaceVariant,
                    child: app.iconPath != null && app.iconPath!.isNotEmpty
                        ? (app.iconPath!.startsWith('/')
                              // Optimized: File path (no base64 decode needed)
                              ? Image.file(
                                  File(app.iconPath!),
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.medium,
                                  cacheWidth: 96,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.apps_rounded,
                                    size: 26,
                                    color: AppColors.primary,
                                  ),
                                )
                              // Fallback: Still base64 (for backwards compatibility)
                              : Image.memory(
                                  base64Decode(app.iconPath!),
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.medium,
                                  cacheWidth: 96,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.apps_rounded,
                                    size: 26,
                                    color: AppColors.primary,
                                  ),
                                ))
                        : const Icon(
                            Icons.apps_rounded,
                            size: 26,
                            color: AppColors.primary,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
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
                          RiskBadge(riskLevel: app.riskLevel, compact: true),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        app.packageName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Risk bar
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: dangerousRatio,
                                minHeight: 4,
                                backgroundColor: AppColors.divider,
                                valueColor: AlwaysStoppedAnimation(
                                  dangerousRatio > 0.5
                                      ? AppColors.riskDangerous
                                      : dangerousRatio > 0.2
                                      ? AppColors.riskMedium
                                      : AppColors.riskSafe,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${app.permissions.length} perms',
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textLight,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
