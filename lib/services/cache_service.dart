import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/models/permission_justification.dart';

class CacheService {
  static const String _boxName = 'apps_cache_v2';
  static const String _historyBoxName = 'permission_history';
  static const String _justificationBoxName = 'permission_justifications';
  static const String _appCapabilitiesBoxName = 'app_capabilities';
  static const String _metaBoxName = 'cache_meta';

  late Box<String> _appsBox;
  late Box<String> _historyBox;
  late Box<String> _justificationBox;
  late Box<String> _capabilitiesBox;
  late Box<String> _metaBox;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    try {
      _appsBox = await Hive.openBox<String>(_boxName);
      _historyBox = await Hive.openBox<String>(_historyBoxName);
      _justificationBox = await Hive.openBox<String>(_justificationBoxName);
      _capabilitiesBox = await Hive.openBox<String>(_appCapabilitiesBoxName);
      _metaBox = await Hive.openBox<String>(_metaBoxName);
      _initialized = true;
    } catch (e) {
      print('Error initializing cache: $e');
    }
  }

  // ── Apps cache (stored as JSON strings) ────────────────────────────

  Future<void> saveApps(List<AppInfo> apps) async {
    try {
      await _appsBox.clear();
      for (int i = 0; i < apps.length; i++) {
        await _appsBox.put('app_$i', jsonEncode(apps[i].toJson()));
      }
    } catch (e) {
      print('Error saving apps to cache: $e');
    }
  }

  List<AppInfo> getCachedApps() {
    try {
      final apps = <AppInfo>[];
      for (final value in _appsBox.values) {
        try {
          apps.add(AppInfo.fromJson(jsonDecode(value)));
        } catch (_) {}
      }
      return apps;
    } catch (e) {
      print('Error reading cached apps: $e');
      return [];
    }
  }

  // ── Fingerprint for change detection ───────────────────────────────

  String? getCachedFingerprint() {
    try {
      return _metaBox.get('apps_fingerprint');
    } catch (_) {
      return null;
    }
  }

  Future<void> saveFingerprint(String fingerprint) async {
    try {
      await _metaBox.put('apps_fingerprint', fingerprint);
    } catch (e) {
      print('Error saving fingerprint: $e');
    }
  }

  /// Returns true if the installed apps have changed since last scan.
  bool hasAppsChanged(String currentFingerprint) {
    final cached = getCachedFingerprint();
    return cached == null || cached != currentFingerprint;
  }

  // ── Permission history ─────────────────────────────────────────────

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
      await _appsBox.clear();
      await _metaBox.delete('apps_fingerprint');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  Future<void> clearAllData() async {
    try {
      await _appsBox.clear();
      await _historyBox.clear();
      await _justificationBox.clear();
      await _capabilitiesBox.clear();
      await _metaBox.clear();
    } catch (e) {
      print('Error clearing all data: $e');
    }
  }
}
