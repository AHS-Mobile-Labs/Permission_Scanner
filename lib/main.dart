import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_scanner/screens/home_screen.dart';
import 'package:permission_scanner/screens/permission_info_screen.dart';
import 'package:permission_scanner/screens/dashboard_screen.dart';
import 'package:permission_scanner/screens/splash_screen.dart';
import 'package:permission_scanner/utils/app_colors.dart';
import 'package:permission_scanner/services/notification_service.dart';
import 'package:permission_scanner/services/cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Permission Scanner',
      theme: AppTheme.lightTheme(),
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _initialized = false;
  double _progress = 0.0;
  String _statusMessage = 'Starting up...';

  static const Duration _initTimeout = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  void _updateProgress(double progress, String message) {
    if (mounted) {
      setState(() {
        _progress = progress;
        _statusMessage = message;
      });
    }
  }

  Future<void> _initApp() async {
    try {
      await Future.any([
        _performInit(),
        Future.delayed(_initTimeout).then((_) {
          // Timeout reached — proceed with whatever is ready
          if (!_initialized && mounted) {
            debugPrint('Init timeout reached, proceeding with partial init');
            setState(() => _initialized = true);
          }
        }),
      ]);
    } catch (e) {
      debugPrint('Error during app init: $e');
      // Proceed to main screen even on error to avoid permanent splash
      if (mounted) {
        setState(() => _initialized = true);
      }
    }
  }

  Future<void> _performInit() async {
    _updateProgress(0.1, 'Initializing storage...');

    // Run cache and notification init concurrently.
    // NotificationService.init() only sets up the plugin — it no longer
    // requests permission (that is deferred to after the main UI loads).
    await Future.wait<bool>([
      _safeInit(() => CacheService().init()),
      _safeInit(() => NotificationService().init()),
    ]);

    _updateProgress(0.7, 'Preparing interface...');

    // Small yield to let the progress UI repaint before the heavier
    // widget tree of MainScreen is built.
    await Future.delayed(const Duration(milliseconds: 120));

    _updateProgress(1.0, 'Ready!');

    if (mounted) {
      setState(() => _initialized = true);
    }

    // Defer the notification-permission dialog until the main UI is visible
    // so it never blocks startup.
    Future.delayed(const Duration(seconds: 2), () {
      NotificationService().requestPermission();
    });
  }

  /// Wraps an async init step so that an individual failure does not crash
  /// the entire startup sequence.
  Future<bool> _safeInit(Future<void> Function() work) async {
    try {
      await work();
      return true;
    } catch (e) {
      debugPrint('Init step failed: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return SplashScreen(progress: _progress, statusMessage: _statusMessage);
    }
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

  final List<Widget> _screens = [
    const HomeScreen(),
    const PermissionInfoScreen(),
    const DashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.apps), label: 'Apps'),
          NavigationDestination(icon: Icon(Icons.info), label: 'Permissions'),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Dashboard',
          ),
        ],
      ),
    );
  }
}
