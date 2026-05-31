import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_scanner/screens/home_screen.dart';
import 'package:permission_scanner/screens/dashboard_screen.dart';
import 'package:permission_scanner/screens/splash_screen.dart';
import 'package:permission_scanner/screens/about_screen.dart';
import 'package:permission_scanner/screens/app_compare_screen.dart';
import 'package:permission_scanner/screens/privacy_tools_screen.dart';
import 'package:permission_scanner/utils/app_colors.dart';
import 'package:permission_scanner/services/notification_service.dart';
import 'package:permission_scanner/services/cache_service.dart';
import 'package:permission_scanner/services/app_providers.dart';
import 'package:permission_scanner/services/app_logger.dart';

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        AppLogger.error(
          'Flutter framework error',
          details.exception,
          details.stack,
        );
      };
      PlatformDispatcher.instance.onError = (error, stackTrace) {
        AppLogger.error('Uncaught platform error', error, stackTrace);
        return true;
      };

      runApp(const ProviderScope(child: MyApp()));

      // Never block the first frame. Hive/cache warmup runs only after the
      // native/Flutter splash has been painted, preventing blank-start ANRs.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(
          CacheService().init().timeout(const Duration(seconds: 8)).catchError((
            Object error,
            StackTrace stackTrace,
          ) {
            AppLogger.error('Deferred cache warmup failed', error, stackTrace);
          }),
        );
      });
    },
    (error, stackTrace) {
      AppLogger.error('Uncaught zone error', error, stackTrace);
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Permission Scanner',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.system,
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends ConsumerStatefulWidget {
  const AppInitializer({super.key});

  @override
  ConsumerState<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends ConsumerState<AppInitializer> {
  bool _userSkippedLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize notification service in background (non-blocking)
    unawaited(_initializeNotifications());
  }

  Future<void> _initializeNotifications() async {
    try {
      await NotificationService().init().timeout(const Duration(seconds: 5));
      // Request notification permission after UI is visible (non-blocking)
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        NotificationService().requestPermission();
      });
    } catch (e, stackTrace) {
      AppLogger.error('Notification init failed', e, stackTrace);
    }
  }

  void _handleSkip() {
    // User tapped skip - mark as skipped and move to main screen
    setState(() => _userSkippedLoading = true);
  }

  @override
  Widget build(BuildContext context) {
    // Watch the loading progress provider
    final loadingProgress = ref.watch(loadingProgressProvider);

    // Show splash if:
    // 1. Loading not yet complete AND user hasn't skipped
    // 2. Keep showing splash for minimum visual polish
    final shouldShowSplash =
        (!loadingProgress.isComplete && !_userSkippedLoading) ||
        (loadingProgress.percentage < 5);

    if (shouldShowSplash) {
      return SplashScreen(onSkip: _handleSkip);
    }

    // Loading complete or user skipped - show main app
    return const MainScreen();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final Set<int> _visitedTabs = {0};

  static const _screens = <Widget>[
    DashboardScreen(),
    HomeScreen(),
    AppCompareScreen(),
    PrivacyToolsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0 ? null : _buildAppBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: List.generate(_screens.length, (index) {
          return _visitedTabs.contains(index)
              ? _screens[index]
              : const SizedBox.shrink();
        }),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
        ),
        child: NavigationBar(
          backgroundColor: AppColors.cardBackground,
          indicatorColor: AppColors.primaryContainer,
          surfaceTintColor: Colors.transparent,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
              _visitedTabs.add(index);
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.apps_rounded),
              selectedIcon: Icon(Icons.apps_rounded),
              label: 'Apps',
            ),
            NavigationDestination(
              icon: Icon(Icons.compare_arrows_rounded),
              selectedIcon: Icon(Icons.compare_arrows_rounded),
              label: 'Compare',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_rounded),
              selectedIcon: Icon(Icons.tune_rounded),
              label: 'Tools',
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    switch (_selectedIndex) {
      case 0:
        return AppBar(
          title: const Text('Security Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.shield_rounded, size: 22),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                );
              },
              tooltip: 'About',
            ),
          ],
        );
      case 1:
        return AppBar(
          title: const Text('Permission Scanner'),
          actions: [
            IconButton(
              icon: const Icon(Icons.shield_rounded, size: 22),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                );
              },
              tooltip: 'About',
            ),
          ],
        );
      case 2:
        return AppBar(title: const Text('Compare Apps'));
      case 3:
        return AppBar(title: const Text('Privacy Tools'));
      default:
        return AppBar(title: const Text('Permission Scanner'));
    }
  }
}
