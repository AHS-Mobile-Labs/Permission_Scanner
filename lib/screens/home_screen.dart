import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_scanner/services/app_providers.dart';
import 'package:permission_scanner/utils/app_colors.dart';
import 'package:permission_scanner/widgets/app_card.dart';
import 'package:permission_scanner/screens/app_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAppsAsync = ref.watch(filteredAppsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Permission Scanner'), elevation: 0),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: SearchBar(
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
              leading: Icon(Icons.search, color: AppColors.textLight),
              hintText: 'Search apps...',
            ),
          ),
          Expanded(
            child: filteredAppsAsync.when(
              data: (apps) {
                if (apps.isEmpty) {
                  return Center(child: Text('No apps found'));
                }
                return ListView.builder(
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    return AppCard(
                      app: app,
                      onTap: () {
                        ref.read(selectedAppProvider.notifier).state = app;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AppDetailScreen(app: app),
                          ),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
