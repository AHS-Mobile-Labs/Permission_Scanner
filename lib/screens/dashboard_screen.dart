import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:permission_scanner/services/app_providers.dart';
import 'package:permission_scanner/utils/app_colors.dart';
import 'package:permission_scanner/widgets/stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Risk Dashboard'), elevation: 0),
      body: SingleChildScrollView(
        child: statsAsync.when(
          data: (stats) => Column(
            children: [
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    StatCard(
                      title: 'Total Apps',
                      count: stats.totalApps,
                      color: AppColors.primary,
                    ),
                    StatCard(
                      title: 'Safe Apps',
                      count: stats.safeApps,
                      color: AppColors.riskSafe,
                    ),
                    StatCard(
                      title: 'Medium Risk',
                      count: stats.mediumApps,
                      color: AppColors.riskMedium,
                    ),
                    StatCard(
                      title: 'Dangerous Apps',
                      count: stats.dangerousApps,
                      color: AppColors.riskDangerous,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Risk Distribution',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                margin: EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          color: AppColors.riskSafe,
                          value: stats.safeApps.toDouble(),
                          title: '${stats.safeApps}',
                          radius: 50,
                        ),
                        PieChartSectionData(
                          color: AppColors.riskMedium,
                          value: stats.mediumApps.toDouble(),
                          title: '${stats.mediumApps}',
                          radius: 50,
                        ),
                        PieChartSectionData(
                          color: AppColors.riskDangerous,
                          value: stats.dangerousApps.toDouble(),
                          title: '${stats.dangerousApps}',
                          radius: 50,
                        ),
                      ],
                      centerSpaceRadius: 0,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Permission Summary',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildStatRow(
                          'Total Dangerous Permissions',
                          '${stats.totalDangerousPermissions}',
                          AppColors.riskDangerous,
                        ),
                        SizedBox(height: 12),
                        _buildStatRow(
                          'Average per High-Risk App',
                          stats.dangerousApps > 0
                              ? '${(stats.totalDangerousPermissions / stats.dangerousApps).toStringAsFixed(1)}'
                              : '0',
                          AppColors.riskMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32),
            ],
          ),
          loading: () => Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: AppColors.textLight)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
