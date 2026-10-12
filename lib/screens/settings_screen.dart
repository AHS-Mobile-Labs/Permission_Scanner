import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:permission_scanner/screens/about_screen.dart';
import 'package:permission_scanner/screens/privacy_policy_screen.dart';
import 'package:permission_scanner/services/app_logger.dart';
import 'package:permission_scanner/services/app_providers.dart';
import 'package:permission_scanner/utils/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _isLoadingCache = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    try {
      final status = await Permission.notification.status;
      if (mounted) {
        setState(() {
          _notificationsEnabled = status.isGranted;
        });
      }
    } catch (e) {
      AppLogger.info('Could not check notification status: $e');
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final status = await Permission.notification.request();
      if (mounted) {
        setState(() {
          _notificationsEnabled = status.isGranted;
        });
        if (status.isPermanentlyDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Notifications are disabled in system settings.',
              ),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
      }
    } else {
      setState(() {
        _notificationsEnabled = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'To completely silence alerts, manage notification channels in system settings.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleClearCache() async {
    setState(() => _isLoadingCache = true);
    try {
      final cacheService = ref.read(cacheServiceProvider);
      await cacheService.init();
      await cacheService.clearCache();

      final scannerService = ref.read(permissionScannerServiceProvider);
      await scannerService.clearNativeIconCache();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App cache cleared successfully.')),
        );
      }

      await ref.read(installedAppsProvider.notifier).forceRefresh();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear cache', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error clearing cache: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingCache = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        _sectionHeader('Alerts & Monitoring'),
        _card([
          SwitchListTile(
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primaryContainer,
            title: const Text(
              'Permission Change Alerts',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            subtitle: const Text(
              'Notify when an installed application acquires new sensitive permissions after an update.',
              style: TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
          ),
        ]),
        const SizedBox(height: 20),

        _sectionHeader('Storage & Cache Management'),
        _card([
          ListTile(
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.cleaning_services_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            title: const Text(
              'Clear Application Cache',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            subtitle: const Text(
              'Resets local database cache and cached package icons. Triggers a fresh device scan.',
              style: TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
            trailing: _isLoadingCache
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textLight,
                  ),
            onTap: _isLoadingCache ? null : _handleClearCache,
          ),
        ]),
        const SizedBox(height: 20),

        _sectionHeader('Privacy & Policy'),
        _card([
          ListTile(
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.riskSafeContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.privacy_tip_outlined,
                color: AppColors.riskSafe,
                size: 20,
              ),
            ),
            title: const Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            subtitle: const Text(
              'Read our commitment to zero-telemetry offline analysis.',
              style: TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textLight,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              );
            },
          ),
        ]),
        const SizedBox(height: 20),

        _sectionHeader('About Application'),
        _card([
          ListTile(
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: AppColors.textDark,
                size: 20,
              ),
            ),
            title: const Text(
              'About Permission Scanner',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            subtitle: const Text(
              'Version 1.0.4 (Build 5) · Open Source Security Audit Tool',
              style: TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textLight,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),
          const Divider(height: 1, indent: 64, color: AppColors.divider),
          ListTile(
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.code_rounded,
                color: AppColors.textDark,
                size: 20,
              ),
            ),
            title: const Text(
              'GitHub Source Code',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            subtitle: const Text(
              'github.com/AHS-Mobile-Labs/Permission_Scanner',
              style: TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
            trailing: const Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: AppColors.textLight,
            ),
            onTap: () {
              launchUrl(
                Uri.parse(
                  'https://github.com/AHS-Mobile-Labs/Permission_Scanner',
                ),
                mode: LaunchMode.externalApplication,
              );
            },
          ),
        ]),
        const SizedBox(height: 24),

        // Offline guarantee callout
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.riskSafeContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.riskSafe.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.riskSafe,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '100% Offline & Private: Permission Scanner runs entirely on-device. No telemetry, identifiers, or package lists are transmitted to any server.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.riskSafe.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.textLight,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(children: children),
    );
  }
}
