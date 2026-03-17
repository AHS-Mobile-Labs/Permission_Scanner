import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/services/permission_justification_service.dart';
import 'package:permission_scanner/services/cache_service.dart';

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
    capabilitySelection = {
      for (final cap in PermissionJustificationService.getAllCapabilities())
        cap: selectedCapabilities.contains(cap),
    };
  }

  @override
  Widget build(BuildContext context) {
    final analysis = PermissionJustificationService.analyzePermissions(
      widget.app.permissions,
      selectedCapabilities,
    );

    return AlertDialog(
      title: Text('Verify ${widget.app.appName}'),
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
            ...PermissionJustificationService.getAllCapabilities().map(
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
            const SizedBox(height: 16),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✅ Justified Permissions: ${analysis['justifiedCount']}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '⚠️ Unjustified Permissions: ${analysis['unjustifiedCount']}',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Justification Score: ${analysis['justificationPercentage']}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            if (analysis['unjustifiedCount'] > 0) ...[
              const SizedBox(height: 12),
              ExpansionTile(
                title: const Text('Unjustified Permissions'),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final perm
                            in analysis['unjustifiedPermissions']
                                as List<String>)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              '• ${perm.replaceAll('android.permission.', '')}',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
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
