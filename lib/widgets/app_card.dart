import 'package:flutter/material.dart';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/utils/app_colors.dart';
import 'package:permission_scanner/widgets/risk_badge.dart';

class AppCard extends StatelessWidget {
  final AppInfo app;
  final VoidCallback onTap;

  const AppCard({super.key, required this.app, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 56,
                  height: 56,
                  color: AppColors.background,
                  child: Icon(Icons.apps, size: 32, color: AppColors.primary),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.appName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      app.packageName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${app.permissions.length} permissions',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RiskBadge(riskLevel: app.riskLevel),
                  SizedBox(height: 8),
                  Text(
                    '${app.privacyScore}%',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
