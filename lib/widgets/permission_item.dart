import 'package:flutter/material.dart';
import 'package:permission_scanner/models/permission_info.dart';
import 'package:permission_scanner/utils/app_colors.dart';

class PermissionItem extends StatelessWidget {
  final PermissionInfo permission;

  const PermissionItem({super.key, required this.permission});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: permission.isDangerous
                    ? AppColors.riskDangerous.withOpacity(0.1)
                    : AppColors.riskSafe.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                permission.isDangerous ? Icons.warning : Icons.check_circle,
                color: permission.isDangerous
                    ? AppColors.riskDangerous
                    : AppColors.riskSafe,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    permission.displayName,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    permission.description,
                    style: TextStyle(color: AppColors.textLight, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
