import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/services/permission_justification_service.dart';
import 'package:permission_scanner/services/cache_service.dart';
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

    // Get only relevant capabilities (those with dangerous permissions that the app has)
    final relevantCapabilities = _getRelevantCapabilities();
    capabilitySelection = {
      for (final cap in relevantCapabilities)
        cap: selectedCapabilities.contains(cap),
    };
  }

  /// Get only capabilities that have dangerous permissions the app actually requests
  List<String> _getRelevantCapabilities() {
    final relevantCaps = <String>[];

    for (final capability
        in PermissionJustificationService.getAllCapabilities()) {
      final requiredPerms =
          PermissionJustificationService.getPermissionsForCapability(
            capability,
          );

      // Skip if app doesn't have any of these permissions
      if (!requiredPerms.any((perm) => widget.app.permissions.contains(perm))) {
        continue;
      }

      // Only include if it has at least one dangerous permission
      if (requiredPerms.any((perm) => dangerousPermissions.contains(perm))) {
        relevantCaps.add(capability);
      }
    }

    return relevantCaps;
  }

  @override
  Widget build(BuildContext context) {
    final relevantCapabilities = _getRelevantCapabilities();

    // If no relevant capabilities, show message
    if (relevantCapabilities.isEmpty) {
      return AlertDialog(
        title: Text('${widget.app.appName}'),
        content: const Text(
          'This app only uses safe permissions. No justification needed.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context, []),
            child: const Text('OK'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text('${widget.app.appName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select features this app uses:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ...relevantCapabilities.map(
              (capability) => CheckboxListTile(
                dense: true,
                title: Text(capability),
                value: capabilitySelection[capability] ?? false,
                onChanged: (value) {
                  setState(() {
                    capabilitySelection[capability] = value ?? false;
                    selectedCapabilities = capabilitySelection.entries
                        .where((e) => e.value)
                        .map((e) => e.key)
                        .toList();
                  });
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.cacheService.saveAppCapabilities(
              widget.app.packageName,
              selectedCapabilities,
            );
            Navigator.pop(context, selectedCapabilities);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
