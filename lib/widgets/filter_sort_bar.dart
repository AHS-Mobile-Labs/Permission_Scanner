import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_scanner/services/app_providers.dart';

class FilterSortBar extends ConsumerWidget {
  const FilterSortBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortOption = ref.watch(sortOptionProvider);
    final riskFilter = ref.watch(riskFilterProvider);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Sort Dropdown
          DropdownButton<SortOption>(
            isExpanded: true,
            value: sortOption,
            items: [
              DropdownMenuItem(
                value: SortOption.nameAsc,
                child: const Text('📝 Sort by Name (A-Z)'),
              ),
              DropdownMenuItem(
                value: SortOption.nameDesc,
                child: const Text('📝 Sort by Name (Z-A)'),
              ),
              DropdownMenuItem(
                value: SortOption.riskHigh,
                child: const Text('🔴 High Risk First'),
              ),
              DropdownMenuItem(
                value: SortOption.riskLow,
                child: const Text('🟢 Safe First'),
              ),
              DropdownMenuItem(
                value: SortOption.privacyHigh,
                child: const Text('🛡️ High Privacy Score'),
              ),
              DropdownMenuItem(
                value: SortOption.privacyLow,
                child: const Text('⚠️ Low Privacy Score'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                ref.read(sortOptionProvider.notifier).state = value;
              }
            },
          ),
          const SizedBox(height: 12),
          // Risk Level Filter
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: riskFilter == PermissionFilter.all,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(riskFilterProvider.notifier).state =
                        PermissionFilter.all;
                  }
                },
              ),
              FilterChip(
                label: const Text('🟢 Safe'),
                selected: riskFilter == PermissionFilter.safe,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(riskFilterProvider.notifier).state =
                        PermissionFilter.safe;
                  }
                },
              ),
              FilterChip(
                label: const Text('🟡 Medium'),
                selected: riskFilter == PermissionFilter.medium,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(riskFilterProvider.notifier).state =
                        PermissionFilter.medium;
                  }
                },
              ),
              FilterChip(
                label: const Text('🔴 Dangerous'),
                selected: riskFilter == PermissionFilter.dangerous,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(riskFilterProvider.notifier).state =
                        PermissionFilter.dangerous;
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
