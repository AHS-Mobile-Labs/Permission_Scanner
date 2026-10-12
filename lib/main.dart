import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_scanner/screens/about_screen.dart';
import 'package:permission_scanner/screens/dashboard_screen.dart';
import 'package:permission_scanner/screens/home_screen.dart';
import 'package:permission_scanner/screens/privacy_tools_screen.dart';
import 'package:permission_scanner/screens/settings_screen.dart';
import 'package:permission_scanner/screens/splash_screen.dart';
import 'package:permission_scanner/services/app_logger.dart';
import 'package:permission_scanner/services/app_providers.dart';
import 'package:permission_scanner/services/cache_service.dart';
import 'package:permission_scanner/services/notification_service.dart';
import 'package:permission_scanner/utils/app_colors.dart';

/// Top-level provider for programmatic navigation across bottom tabs.
final mainNavIndexProvider = StateProvider<int>((ref) => 0);

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
    unawaited(_initializeNotifications());
  }

  Future<void> _initializeNotifications() async {
    try {
      await NotificationService().init().timeout(const Duration(seconds: 5));
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        NotificationService().requestPermission();
      });
    } catch (e, stackTrace) {
      AppLogger.error('Notification init failed', e, stackTrace);
    }
  }

  void _handleSkip() {
    setState(() => _userSkippedLoading = true);
  }

  @override
  Widget build(BuildContext context) {
    final loadingProgress = ref.watch(loadingProgressProvider);

    final shouldShowSplash =
        (!loadingProgress.isComplete && !_userSkippedLoading) ||
        (loadingProgress.percentage < 5);

    if (shouldShowSplash) {
      return SplashScreen(onSkip: _handleSkip);
    }

    return const MainScreen();
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final Set<int> _visitedTabs = {0};

  static const _screens = <Widget>[
    DashboardScreen(),
    HomeScreen(),
    PrivacyToolsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(mainNavIndexProvider);
    _visitedTabs.add(selectedIndex);

    return PopScope(
      canPop: selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (selectedIndex != 0) {
          ref.read(mainNavIndexProvider.notifier).state = 0;
        }
      },
      child: Scaffold(
        appBar: selectedIndex == 0 ? null : _buildAppBar(selectedIndex),
        body: IndexedStack(
          index: selectedIndex,
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
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              ref.read(mainNavIndexProvider.notifier).state = index;
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.apps_outlined),
                selectedIcon: Icon(Icons.apps_rounded),
                label: 'Apps',
              ),
              NavigationDestination(
                icon: Icon(Icons.tune_outlined),
                selectedIcon: Icon(Icons.tune_rounded),
                label: 'Tools',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(int index) {
    switch (index) {
      case 1:
        return AppBar(
          title: const Text('Installed Apps'),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline_rounded, size: 22),
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
        return AppBar(title: const Text('Privacy Tools'));
      case 3:
        return AppBar(title: const Text('Settings'));
      default:
        return AppBar(title: const Text('Permission Scanner'));
    }
  }
}
