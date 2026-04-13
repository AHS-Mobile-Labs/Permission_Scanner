import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_scanner/services/app_providers.dart';
import 'package:permission_scanner/utils/app_colors.dart';

class FilterSortBar extends ConsumerWidget {
  const FilterSortBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortOption = ref.watch(sortOptionProvider);
    final appType = ref.watch(appTypeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // App Type Segmented Control
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<AppType>(
              segments: const [
                ButtonSegment(value: AppType.userApps, label: Text('User')),
                ButtonSegment(value: AppType.systemApps, label: Text('System')),
                ButtonSegment(
                  value: AppType.unknownSource,
                  label: Text('Unknown'),
                ),
              ],
              selected: {appType},
              onSelectionChanged: (value) {
                ref.read(appTypeProvider.notifier).state = value.first;
              },
            ),
          ),
          const SizedBox(height: 10),
          // Sort dropdown
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SortOption>(
                isExpanded: true,
                value: sortOption,
                icon: const Icon(
                  Icons.sort_rounded,
                  size: 18,
                  color: AppColors.textLight,
                ),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
                items: const [
                  DropdownMenuItem(
                    value: SortOption.name,
                    child: Text('Sort by Name'),
                  ),
                  DropdownMenuItem(
                    value: SortOption.risk,
                    child: Text('Sort by Risk Level'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref.read(sortOptionProvider.notifier).state = value;
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
