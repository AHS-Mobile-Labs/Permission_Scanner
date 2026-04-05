import 'package:flutter/material.dart';
import 'package:permission_scanner/utils/app_colors.dart';

class SplashScreen extends StatelessWidget {
  final double progress;
  final String statusMessage;

  const SplashScreen({
    super.key,
    this.progress = 0.0,
    this.statusMessage = 'Starting up...',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.security, size: 56, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'Permission Scanner',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              statusMessage,
              style: TextStyle(fontSize: 14, color: AppColors.textLight),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value > 0 ? value : null,
                    minHeight: 4,
                    color: AppColors.primary,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
