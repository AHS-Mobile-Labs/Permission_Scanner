import 'package:flutter/material.dart';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/utils/app_colors.dart';

class RiskBadge extends StatelessWidget {
  final RiskLevel riskLevel;

  const RiskBadge({super.key, required this.riskLevel});

  Color get _color {
    switch (riskLevel) {
      case RiskLevel.safe:
        return AppColors.riskSafe;
      case RiskLevel.medium:
        return AppColors.riskMedium;
      case RiskLevel.dangerous:
        return AppColors.riskDangerous;
    }
  }

  String get _label {
    switch (riskLevel) {
      case RiskLevel.safe:
        return 'Safe';
      case RiskLevel.medium:
        return 'Medium';
      case RiskLevel.dangerous:
        return 'Dangerous';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
