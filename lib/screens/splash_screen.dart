import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_scanner/utils/app_colors.dart';
import 'package:permission_scanner/services/app_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSkip;

  const SplashScreen({super.key, this.onSkip});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _showSkipButton = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Show skip button after 3 seconds if still loading
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showSkipButton = true);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleSkip() {
    // Dismiss skip button
    setState(() => _showSkipButton = false);
    // Notify parent to skip loading
    widget.onSkip?.call();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the loading progress provider
    final loadingProgress = ref.watch(loadingProgressProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main loading content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated App Icon
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        'asset/icon/Permission Scanner.png',
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // App Title
                const Text(
                  'Permission Scanner',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),

                // Company Attribution
                Text(
                  'by AHS Mobile Labs',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textLight,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),

                // Status Message - Animated with smooth transitions
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Text(
                    loadingProgress.message,
                    key: ValueKey(loadingProgress.message),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Progress Bar with Stage Indicator
                SizedBox(
                  width: 240,
                  child: Column(
                    children: [
                      // Stage Indicator (0-3)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(4, (index) {
                          final isCompleted = loadingProgress.stage > index;
                          final isActive = loadingProgress.stage == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted || isActive
                                  ? AppColors.primary
                                  : AppColors.divider,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 14),

                      // Progress Bar - Smooth animation
                      TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: 0,
                          end: loadingProgress.percentage / 100,
                        ),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: value > 0 ? value : null,
                                  minHeight: 4,
                                  color: AppColors.primary,
                                  backgroundColor: AppColors.divider,
                                ),
                              ),
                              if (value > 0) ...[
                                const SizedBox(height: 10),
                                Text(
                                  '${(value * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Skip Button - Appears after 3 seconds if still loading
          if (_showSkipButton && !loadingProgress.isComplete)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 400),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _handleSkip,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
