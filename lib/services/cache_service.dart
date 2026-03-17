import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/models/permission_justification.dart';

class CacheService {
  static const String _boxName = 'apps_cache';
  static const String _historyBoxName = 'permission_history';
  static const String _justificationBoxName = 'permission_justifications';
  static const String _appCapabilitiesBoxName = 'app_capabilities';

  late Box<AppInfo> _box;
  late Box<String> _historyBox;
  late Box<String> _justificationBox;
  late Box<String> _capabilitiesBox;

  Future<void> init() async {
    await Hive.initFlutter();
    try {
      _box = await Hive.openBox<AppInfo>(_boxName);
      _historyBox = await Hive.openBox<String>(_historyBoxName);
      _justificationBox = await Hive.openBox<String>(_justificationBoxName);
      _capabilitiesBox = await Hive.openBox<String>(_appCapabilitiesBoxName);
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

  Future<void> savePermissionHistory(PermissionHistory history) async {
    try {
      final key =
          '${history.packageName}_${history.scannedAt.toIso8601String()}';
      await _historyBox.put(key, jsonEncode(history.toJson()));
    } catch (e) {
      print('Error saving permission history: $e');
    }
  }

  List<PermissionHistory> getPermissionHistory(String packageName) {
    try {
      final histories = <PermissionHistory>[];
      for (final key in _historyBox.keys) {
        if (key.toString().startsWith(packageName)) {
          final jsonStr = _historyBox.get(key);
          if (jsonStr != null) {
            histories.add(PermissionHistory.fromJson(jsonDecode(jsonStr)));
          }
        }
      }
      histories.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
      return histories.take(30).toList(); // Keep last 30 scans
    } catch (e) {
      print('Error reading permission history: $e');
      return [];
    }
  }

  Future<void> savePermissionJustification(
    PermissionJustification justification,
  ) async {
    try {
      final key = '${justification.packageName}_${justification.permission}';
      await _justificationBox.put(key, jsonEncode(justification.toJson()));
    } catch (e) {
      print('Error saving permission justification: $e');
    }
  }

  PermissionJustification? getPermissionJustification(
    String packageName,
    String permission,
  ) {
    try {
      final key = '${packageName}_$permission';
      final jsonStr = _justificationBox.get(key);
      if (jsonStr != null) {
        return PermissionJustification.fromJson(jsonDecode(jsonStr));
      }
    } catch (e) {
      print('Error reading permission justification: $e');
    }
    return null;
  }

  List<PermissionJustification> getAllJustifications(String packageName) {
    try {
      final justifications = <PermissionJustification>[];
      for (final key in _justificationBox.keys) {
        if (key.toString().startsWith(packageName)) {
          final jsonStr = _justificationBox.get(key);
          if (jsonStr != null) {
            justifications.add(
              PermissionJustification.fromJson(jsonDecode(jsonStr)),
            );
          }
        }
      }
      return justifications;
    } catch (e) {
      print('Error reading justifications: $e');
      return [];
    }
  }

  Future<void> saveAppCapabilities(
    String packageName,
    List<String> capabilities,
  ) async {
    try {
      await _capabilitiesBox.put(packageName, jsonEncode(capabilities));
    } catch (e) {
      print('Error saving app capabilities: $e');
    }
  }

  List<String> getAppCapabilities(String packageName) {
    try {
      final json = _capabilitiesBox.get(packageName);
      if (json != null) {
        return List<String>.from(jsonDecode(json) as List);
      }
    } catch (e) {
      print('Error reading app capabilities: $e');
    }
    return [];
  }

  Future<void> clearCache() async {
    try {
      await _box.clear();
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  Future<void> clearAllData() async {
    try {
      await _box.clear();
      await _historyBox.clear();
      await _justificationBox.clear();
      await _capabilitiesBox.clear();
    } catch (e) {
      print('Error clearing all data: $e');
    }
  }
}
