import 'package:flutter/material.dart';
import 'package:permission_scanner/models/permission_info.dart';
import 'package:permission_scanner/utils/app_colors.dart';

class PermissionItem extends StatefulWidget {
  final PermissionInfo permission;
  final bool isJustified;

  const PermissionItem({
    super.key,
    required this.permission,
    this.isJustified = false,
  });

  @override
  State<PermissionItem> createState() => _PermissionItemState();
}

class _PermissionItemState extends State<PermissionItem> {
  bool _expanded = false;

  IconData get _groupIcon {
    switch (widget.permission.group) {
      case 'Camera':
        return Icons.camera_alt_rounded;
      case 'Microphone':
        return Icons.mic_rounded;
      case 'Contacts':
        return Icons.contacts_rounded;
      case 'Location':
        return Icons.location_on_rounded;
      case 'SMS':
        return Icons.sms_rounded;
      case 'Call Log':
        return Icons.call_rounded;
      case 'Storage':
        return Icons.folder_rounded;
      case 'Phone':
        return Icons.phone_android_rounded;
      case 'Network':
        return Icons.wifi_rounded;
      case 'Vibration':
        return Icons.vibration_rounded;
      case 'Device Power':
        return Icons.battery_charging_full_rounded;
      default:
        return Icons.shield_rounded;
    }
  }

  String get _whyItMatters {
    if (widget.permission.isDangerous) {
      switch (widget.permission.group) {
        case 'Camera':
          return 'Apps with camera access can potentially capture photos or videos without your knowledge.';
        case 'Microphone':
          return 'Microphone access can be used to record audio in the background.';
        case 'Contacts':
          return 'Contact access exposes your personal relationships and phone numbers.';
        case 'Location':
          return 'Location tracking can reveal your daily routines and frequently visited places.';
        case 'SMS':
          return 'SMS access can expose private messages and be used for premium SMS fraud.';
        case 'Call Log':
          return 'Call log access reveals who you communicate with and how often.';
        case 'Storage':
          return 'Storage access can expose photos, documents, and other personal files.';
        case 'Phone':
          return 'Phone access can be used to make calls or read device identifiers.';
        default:
          return 'This permission accesses sensitive device features or user data.';
      }
    }
    return 'This is a standard permission that does not access sensitive data.';
  }

  @override
  Widget build(BuildContext context) {
    final isDangerous = widget.permission.isDangerous;
    final accentColor = isDangerous
        ? AppColors.riskDangerous
        : AppColors.riskSafe;
    final bgColor = isDangerous
        ? AppColors.riskDangerousContainer
        : AppColors.riskSafeContainer;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: widget.isJustified
            ? AppColors.riskSafeContainer.withValues(alpha: 0.5)
            : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_groupIcon, color: accentColor, size: 20),
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
                                    widget.permission.displayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ),
                                if (widget.isJustified)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.riskSafeContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Justified',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.riskSafe,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.permission.description,
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.expand_more_rounded,
                          color: AppColors.textLight,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Why it matters',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _whyItMatters,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMedium,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
