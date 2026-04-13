import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/services/permission_justification_service.dart';
import 'package:permission_scanner/services/cache_service.dart';
import 'package:permission_scanner/utils/app_colors.dart';
import 'package:permission_scanner/utils/permission_database.dart';

class PermissionVerificationDialog extends ConsumerStatefulWidget {
  final AppInfo app;
  final CacheService cacheService;

  const PermissionVerificationDialog({
    super.key,
    required this.app,
    required this.cacheService,
  });

  @override
  ConsumerState<PermissionVerificationDialog> createState() =>
      _PermissionVerificationDialogState();
}

class _PermissionVerificationDialogState
    extends ConsumerState<PermissionVerificationDialog> {
  late List<String> selectedCapabilities;
  late Map<String, bool> capabilitySelection;

  @override
  void initState() {
    super.initState();
    selectedCapabilities = widget.cacheService.getAppCapabilities(
      widget.app.packageName,
    );

    final relevantCapabilities = _getRelevantCapabilities();
    capabilitySelection = {
      for (final cap in relevantCapabilities)
        cap: selectedCapabilities.contains(cap),
    };
  }

  List<String> _getRelevantCapabilities() {
    final relevantCaps = <String>[];

    for (final capability
        in PermissionJustificationService.getAllCapabilities()) {
      final requiredPerms =
          PermissionJustificationService.getPermissionsForCapability(
            capability,
          );

      if (!requiredPerms.any((perm) => widget.app.permissions.contains(perm))) {
        continue;
      }

      if (requiredPerms.any((perm) => dangerousPermissions.contains(perm))) {
        relevantCaps.add(capability);
      }
    }

    return relevantCaps;
  }

  @override
  Widget build(BuildContext context) {
    final relevantCapabilities = _getRelevantCapabilities();

    if (relevantCapabilities.isEmpty) {
      return AlertDialog(
        title: Text(widget.app.appName),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: AppColors.riskSafe,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'This app only uses safe permissions.\nNo verification needed.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMedium, fontSize: 14),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context, <String>[]),
            child: const Text('Got it'),
          ),
        ],
      );
    }

    final selectedCount = capabilitySelection.values.where((v) => v).length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.app.appName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Select features this app uses',
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
              const SizedBox(height: 20),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: relevantCapabilities.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final capability = relevantCapabilities[index];
                    final isChecked = capabilitySelection[capability] ?? false;
                    return Material(
                      color: isChecked
                          ? AppColors.primaryContainer.withValues(alpha: 0.5)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            capabilitySelection[capability] = !isChecked;
                            selectedCapabilities = capabilitySelection.entries
                                .where((e) => e.value)
                                .map((e) => e.key)
                                .toList();
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: isChecked
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isChecked
                                        ? AppColors.primary
                                        : AppColors.border,
                                    width: 2,
                                  ),
                                ),
                                child: isChecked
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  capability,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isChecked
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    '$selectedCount selected',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textMedium,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      widget.cacheService.saveAppCapabilities(
                        widget.app.packageName,
                        selectedCapabilities,
                      );
                      Navigator.pop(context, selectedCapabilities);
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
