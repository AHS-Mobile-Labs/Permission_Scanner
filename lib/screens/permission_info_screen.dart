import 'package:flutter/material.dart';
import 'package:permission_scanner/utils/app_colors.dart';
import 'package:permission_scanner/utils/permission_database.dart';
import 'package:permission_scanner/widgets/permission_item.dart';

class PermissionInfoScreen extends StatefulWidget {
  const PermissionInfoScreen({super.key});

  @override
  State<PermissionInfoScreen> createState() => _PermissionInfoScreenState();
}

class _PermissionInfoScreenState extends State<PermissionInfoScreen> {
  bool _dangerousExpanded = true;
  bool _safeExpanded = false;

  @override
  Widget build(BuildContext context) {
    final dangerousPerms = permissionDatabase.values
        .where((p) => p.isDangerous)
        .toList();
    final safePerms = permissionDatabase.values
        .where((p) => !p.isDangerous)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Permission Info')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          children: [
            // Info banner
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.info_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Permission Reference',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Tap any permission to learn why it matters',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Dangerous section
            _buildExpandableSection(
              title: 'Dangerous Permissions',
              count: dangerousPerms.length,
              color: AppColors.riskDangerous,
              bgColor: AppColors.riskDangerousContainer,
              icon: Icons.error_rounded,
              subtitle: 'May access sensitive user data or device features',
              expanded: _dangerousExpanded,
              onToggle: () =>
                  setState(() => _dangerousExpanded = !_dangerousExpanded),
              children: dangerousPerms,
            ),

            const SizedBox(height: 8),

            // Safe section
            _buildExpandableSection(
              title: 'Standard Permissions',
              count: safePerms.length,
              color: AppColors.riskSafe,
              bgColor: AppColors.riskSafeContainer,
              icon: Icons.check_circle_rounded,
              subtitle: 'Generally safe, don\'t access sensitive data',
              expanded: _safeExpanded,
              onToggle: () => setState(() => _safeExpanded = !_safeExpanded),
              children: safePerms,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required int count,
    required Color color,
    required Color bgColor,
    required IconData icon,
    required String subtitle,
    required bool expanded,
    required VoidCallback onToggle,
    required List children,
  }) {
    return Column(
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Material(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$title ($count)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: color,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Expandable list
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              children: children
                  .map<Widget>((perm) => PermissionItem(permission: perm))
                  .toList(),
            ),
          ),
          crossFadeState: expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
          sizeCurve: Curves.easeInOut,
        ),
      ],
    );
  }
}
