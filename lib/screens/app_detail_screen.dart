import 'package:flutter/material.dart';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/utils/app_colors.dart';
import 'package:permission_scanner/utils/permission_database.dart';
import 'package:permission_scanner/widgets/permission_item.dart';
import 'package:permission_scanner/widgets/risk_badge.dart';

class AppDetailScreen extends StatelessWidget {
  final AppInfo app;

  const AppDetailScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('App Details'), elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: AppColors.primary,
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.apps, size: 40, color: AppColors.primary),
                  ),
                  SizedBox(height: 16),
                  Text(
                    app.appName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    app.packageName,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            '${app.permissions.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Total Permissions',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 40),
                      Column(
                        children: [
                          Text(
                            '${app.dangerousPermissionCount}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Dangerous',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 40),
                      Column(
                        children: [
                          RiskBadge(riskLevel: app.riskLevel),
                          SizedBox(height: 4),
                          Text(
                            'Risk Level',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
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
                  'Permissions (${app.permissions.length})',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontSize: 16),
                ),
              ),
            ),
            SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: app.permissions.length,
              itemBuilder: (context, index) {
                final permissionName = app.permissions[index];
                final permissionInfo = permissionDatabase[permissionName];

                if (permissionInfo == null) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          permissionName,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  );
                }

                return PermissionItem(permission: permissionInfo);
              },
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
