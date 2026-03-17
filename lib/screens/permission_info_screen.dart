import 'package:flutter/material.dart';
import 'package:permission_scanner/utils/app_colors.dart';
import 'package:permission_scanner/utils/permission_database.dart';
import 'package:permission_scanner/widgets/permission_item.dart';

class PermissionInfoScreen extends StatelessWidget {
  const PermissionInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dangerousPerms = permissionDatabase.values
        .where((p) => p.isDangerous)
        .toList();
    final safePerms = permissionDatabase.values
        .where((p) => !p.isDangerous)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text('Permission Info'), elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: AppColors.riskDangerous.withOpacity(0.1),
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.riskDangerous.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: AppColors.riskDangerous),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Dangerous Permissions (${dangerousPerms.length})',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.riskDangerous,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'These permissions may access sensitive user data or device features.',
                    style: TextStyle(fontSize: 12, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: dangerousPerms.length,
              separatorBuilder: (_, __) => SizedBox(height: 4),
              itemBuilder: (context, index) {
                return PermissionItem(permission: dangerousPerms[index]);
              },
            ),
            SizedBox(height: 24),
            Container(
              color: AppColors.riskSafe.withOpacity(0.1),
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.riskSafe.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.riskSafe),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Safe Permissions (${safePerms.length})',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.riskSafe,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'These permissions are generally safe and don\'t access sensitive data.',
                    style: TextStyle(fontSize: 12, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: safePerms.length,
              separatorBuilder: (_, __) => SizedBox(height: 4),
              itemBuilder: (context, index) {
                return PermissionItem(permission: safePerms[index]);
              },
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
