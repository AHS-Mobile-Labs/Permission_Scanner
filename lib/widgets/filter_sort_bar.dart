import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_scanner/services/app_providers.dart';

class FilterSortBar extends ConsumerWidget {
  const FilterSortBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortOption = ref.watch(sortOptionProvider);
    final appType = ref.watch(appTypeProvider);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // App Type Tabs
          Row(
            children: [
              Expanded(
                child: SegmentedButton<AppType>(
                  segments: const [
                    ButtonSegment(
                      value: AppType.userApps,
                      label: Text('📥 User Apps'),
                    ),
                    ButtonSegment(
                      value: AppType.systemApps,
                      label: Text('⚙️ System'),
                    ),
                    ButtonSegment(
                      value: AppType.unknownSource,
                      label: Text('🔓 Unknown'),
                    ),
                  ],
                  selected: {appType},
                  onSelectionChanged: (value) {
                    ref.read(appTypeProvider.notifier).state = value.first;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Sort Dropdown
          DropdownButton<SortOption>(
            isExpanded: true,
            value: sortOption,
            items: [
              DropdownMenuItem(
                value: SortOption.name,
                child: const Text('📝 Sort by Name'),
              ),
              DropdownMenuItem(
                value: SortOption.risk,
                child: const Text('🔴 Sort by Risk Level'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                ref.read(sortOptionProvider.notifier).state = value;
              }
            },
          ),
        ],
      ),
    );
  }
}
