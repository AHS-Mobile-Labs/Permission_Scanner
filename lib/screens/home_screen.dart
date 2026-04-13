import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_scanner/services/app_providers.dart';
import 'package:permission_scanner/utils/app_colors.dart';
import 'package:permission_scanner/widgets/app_card.dart';
import 'package:permission_scanner/widgets/filter_sort_bar.dart';
import 'package:permission_scanner/screens/app_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAppsAsync = ref.watch(filteredAppsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_rounded, size: 22),
            onPressed: () {},
            tooltip: 'About',
          ),
        ],
      ),
      body: Column(
        children: [
          // Sticky search + filters
          Container(
            color: AppColors.background,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SearchBar(
                    onChanged: (value) {
                      ref.read(searchQueryProvider.notifier).state = value;
                    },
                    leading: const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.search_rounded,
                        color: AppColors.textLight,
                        size: 20,
                      ),
                    ),
                    hintText: 'Search apps...',
                  ),
                ),
                const FilterSortBar(),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Expanded(
            child: filteredAppsAsync.when(
              data: (apps) {
                if (apps.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No apps found',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 16),
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    return RepaintBoundary(
                      child: AppCard(
                        app: app,
                        onTap: () {
                          ref.read(selectedAppProvider.notifier).state = app;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AppDetailScreen(app: app),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const _HomeScreenSkeleton(),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: AppColors.riskDangerous,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load apps',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$error',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeScreenSkeleton extends StatefulWidget {
  const _HomeScreenSkeleton();

  @override
  State<_HomeScreenSkeleton> createState() => _HomeScreenSkeletonState();
}

class _HomeScreenSkeletonState extends State<_HomeScreenSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _bone(double width, double height) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.divider.withValues(
            alpha: 0.4 + _controller.value * 0.3,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 8,
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _bone(double.infinity, 76),
      ),
    );
  }
}
