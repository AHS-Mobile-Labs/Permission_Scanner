import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_scanner/models/app_info.dart';

class CacheService {
  static const String _boxName = 'apps_cache';
  late Box<AppInfo> _box;

  Future<void> init() async {
    await Hive.initFlutter();
    try {
      _box = await Hive.openBox<AppInfo>(_boxName);
    } catch (e) {
      print('Error initializing cache: $e');
    }
  }

  Future<void> saveApps(List<AppInfo> apps) async {
    try {
      await _box.clear();
      await _box.addAll(apps);
    } catch (e) {
      print('Error saving apps to cache: $e');
    }
  }

  List<AppInfo> getCachedApps() {
    try {
      return _box.values.toList();
    } catch (e) {
      print('Error reading cached apps: $e');
      return [];
    }
  }

  Future<void> clearCache() async {
    try {
      await _box.clear();
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }
}
