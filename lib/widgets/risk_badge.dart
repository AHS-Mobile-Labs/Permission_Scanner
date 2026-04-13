import 'package:flutter/material.dart';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/utils/app_colors.dart';

class RiskBadge extends StatelessWidget {
  final RiskLevel riskLevel;
  final bool compact;

  const RiskBadge({super.key, required this.riskLevel, this.compact = false});

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

  Color get _bgColor {
    switch (riskLevel) {
      case RiskLevel.safe:
        return AppColors.riskSafeContainer;
      case RiskLevel.medium:
        return AppColors.riskMediumContainer;
      case RiskLevel.dangerous:
        return AppColors.riskDangerousContainer;
    }
  }

  String get _label {
    switch (riskLevel) {
      case RiskLevel.safe:
        return 'Safe';
      case RiskLevel.medium:
        return 'Medium';
      case RiskLevel.dangerous:
        return 'High Risk';
    }
  }

  IconData get _icon {
    switch (riskLevel) {
      case RiskLevel.safe:
        return Icons.check_circle_rounded;
      case RiskLevel.medium:
        return Icons.warning_amber_rounded;
      case RiskLevel.dangerous:
        return Icons.error_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: compact ? 10 : 12, color: _color),
          const SizedBox(width: 4),
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
