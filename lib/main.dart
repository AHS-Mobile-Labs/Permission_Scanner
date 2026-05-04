import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_scanner/screens/home_screen.dart';
import 'package:permission_scanner/screens/permission_info_screen.dart';
import 'package:permission_scanner/screens/dashboard_screen.dart';
import 'package:permission_scanner/screens/splash_screen.dart';
import 'package:permission_scanner/screens/about_screen.dart';
import 'package:permission_scanner/utils/app_colors.dart';
import 'package:permission_scanner/services/notification_service.dart';
import 'package:permission_scanner/services/cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CacheService().init(); // Fast init - only opens meta and apps boxes
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
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Show splash for minimum 300ms for UX polish, then switch to main app
    // Apps will load asynchronously in the background via providers
    _hideSplash();
  }

  void _hideSplash() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Initialize notification service in background (non-blocking)
    try {
      await NotificationService().init();
      // Request notification permission after UI is visible (non-blocking)
      Future.delayed(const Duration(seconds: 1), () {
        NotificationService().requestPermission();
      });
    } catch (e) {
      debugPrint('Notification init error: $e');
    }

    if (mounted) {
      setState(() => _showSplash = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _showSplash ? const SplashScreen() : const MainScreen();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const _screens = <Widget>[
    HomeScreen(),
    PermissionInfoScreen(),
    DashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.apps_rounded),
              selectedIcon: Icon(Icons.apps_rounded),
              label: 'Apps',
            ),
            NavigationDestination(
              icon: Icon(Icons.shield_outlined),
              selectedIcon: Icon(Icons.shield_rounded),
              label: 'Permissions',
            ),
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
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
      case 1:
        return AppBar(title: const Text('Permission Info'));
      case 2:
        return AppBar(title: const Text('Security Dashboard'));
      default:
        return AppBar(title: const Text('Permission Scanner'));
    }
  }
}
