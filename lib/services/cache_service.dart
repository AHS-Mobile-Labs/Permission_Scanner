import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/models/permission_justification.dart';
import 'package:permission_scanner/services/app_logger.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  static const String _boxName = 'apps_cache_v2';
  static const String _historyBoxName = 'permission_history';
  static const String _justificationBoxName = 'permission_justifications';
  static const String _appCapabilitiesBoxName = 'app_capabilities';
  static const String _permissionChangesBoxName = 'permission_changes';
  static const String _metaBoxName = 'cache_meta';

  Box<String>? _appsBox;
  Box<String>? _historyBox;
  Box<String>? _justificationBox;
  Box<String>? _capabilitiesBox;
  Box<String>? _permissionChangesBox;
  Box<String>? _metaBox;

  bool _initialized = false;
  Future<void>? _initFuture;
  static bool _hiveInitialized = false;

  CacheService._internal();

  factory CacheService() {
    return _instance;
  }

  Future<void> init() {
    if (_initialized) return Future.value();
    final activeInit = _initFuture;
    if (activeInit != null) return activeInit;
    final future = _performInit();
    _initFuture = future;
    return future;
  }

  Future<void> _performInit() async {
    try {
      if (!_hiveInitialized) {
        await Hive.initFlutter();
        _hiveInitialized = true;
      }
      // Only open critical boxes here. Larger/less-used boxes stay lazy so the
      // splash can render before disk-heavy history data is touched.
      _metaBox = await _openStringBox(_metaBoxName);
      _appsBox = await _openStringBox(_boxName);
      _initialized = true;
    } catch (e, stackTrace) {
      _initFuture = null;
      AppLogger.error('Error initializing cache', e, stackTrace);
    }
  }

  Future<Box<String>> _openStringBox(String name) async {
    if (Hive.isBoxOpen(name)) return Hive.box<String>(name);
    try {
      return await Hive.openBox<String>(name);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Hive box "$name" failed to open; recreating it',
        e,
        stackTrace,
      );
      await Hive.deleteBoxFromDisk(name);
      return Hive.openBox<String>(name);
    }
  }

  Future<Box<String>?> _ensureAppsBoxOpen() async {
    await init();
    return _appsBox;
  }

  Future<Box<String>?> _ensureMetaBoxOpen() async {
    await init();
    return _metaBox;
  }

  Future<Box<String>?> _ensureHistoryBoxOpen() async {
    try {
      await init();
      _historyBox ??= await _openStringBox(_historyBoxName);
      return _historyBox;
    } catch (e, stackTrace) {
      AppLogger.error('Error opening permission history cache', e, stackTrace);
      return null;
    }
  }

  Future<Box<String>?> _ensureJustificationBoxOpen() async {
    try {
      await init();
      _justificationBox ??= await _openStringBox(_justificationBoxName);
      return _justificationBox;
    } catch (e, stackTrace) {
      AppLogger.error('Error opening justification cache', e, stackTrace);
      return null;
    }
  }

  Future<Box<String>?> _ensureCapabilitiesBoxOpen() async {
    try {
      await init();
      _capabilitiesBox ??= await _openStringBox(_appCapabilitiesBoxName);
      return _capabilitiesBox;
    } catch (e, stackTrace) {
      AppLogger.error('Error opening capabilities cache', e, stackTrace);
      return null;
    }
  }

  Future<Box<String>?> _ensurePermissionChangesBoxOpen() async {
    try {
      await init();
      _permissionChangesBox ??= await _openStringBox(_permissionChangesBoxName);
      return _permissionChangesBox;
    } catch (e, stackTrace) {
      AppLogger.error('Error opening permission changes cache', e, stackTrace);
      return null;
    }
  }

  // ── Apps cache (stored as JSON strings) ────────────────────────────

  Future<void> saveApps(List<AppInfo> apps) async {
    try {
      final box = await _ensureAppsBoxOpen();
      if (box == null) return;
      await box.clear();

      // Batch write all apps at once instead of sequential puts
      // This reduces I/O operations from N to 1
      final batch = await compute(_encodeAppsForCache, apps);
      await box.putAll(batch);
    } catch (e, stackTrace) {
      AppLogger.error('Error saving apps to cache', e, stackTrace);
    }
  }

  List<AppInfo> getCachedApps() {
    try {
      final box = _appsBox;
      if (box == null || !box.isOpen) return [];
      final apps = <AppInfo>[];
      for (final value in box.values) {
        try {
          apps.add(AppInfo.fromJson(jsonDecode(value)));
        } catch (_) {}
      }
      return apps;
    } catch (e, stackTrace) {
      AppLogger.error('Error reading cached apps', e, stackTrace);
      return [];
    }
  }

  Future<List<AppInfo>> getCachedAppsAsync() async {
    try {
      final box = await _ensureAppsBoxOpen();
      if (box == null || !box.isOpen || box.isEmpty) return [];
      return compute(_decodeCachedApps, box.values.toList(growable: false));
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error reading cached apps asynchronously',
        e,
        stackTrace,
      );
      return [];
    }
  }

  // ── Fingerprint for change detection ───────────────────────────────

  String? getCachedFingerprint() {
    try {
      final box = _metaBox;
      if (box == null || !box.isOpen) return null;
      return box.get('apps_fingerprint');
    } catch (_) {
      return null;
    }
  }

  Future<void> saveFingerprint(String fingerprint) async {
    try {
      final box = await _ensureMetaBoxOpen();
      await box?.put('apps_fingerprint', fingerprint);
    } catch (e, stackTrace) {
      AppLogger.error('Error saving fingerprint', e, stackTrace);
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
      final box = await _ensureHistoryBoxOpen();
      if (box == null) return;
      final key =
          '${history.packageName}_${history.scannedAt.toIso8601String()}';
      await box.put(key, jsonEncode(history.toJson()));
    } catch (e, stackTrace) {
      AppLogger.error('Error saving permission history', e, stackTrace);
    }
  }

  Future<List<PermissionHistory>> getPermissionHistory(
    String packageName,
  ) async {
    try {
      final box = await _ensureHistoryBoxOpen();
      if (box == null) return [];
      final histories = <PermissionHistory>[];
      for (final key in box.keys) {
        if (key.toString().startsWith(packageName)) {
          final jsonStr = box.get(key);
          if (jsonStr != null) {
            histories.add(PermissionHistory.fromJson(jsonDecode(jsonStr)));
          }
        }
      }
      histories.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
      return histories.take(30).toList(); // Keep last 30 scans
    } catch (e, stackTrace) {
      AppLogger.error('Error reading permission history', e, stackTrace);
      return [];
    }
  }

  Future<void> savePermissionChangeEvents(
    List<PermissionChangeEvent> events,
  ) async {
    if (events.isEmpty) return;
    try {
      final box = await _ensurePermissionChangesBoxOpen();
      if (box == null) return;
      final batch = <String, String>{};
      for (final event in events) {
        final key =
            '${event.packageName}_${event.detectedAt.millisecondsSinceEpoch}';
        batch[key] = jsonEncode(event.toJson());
      }
      await box.putAll(batch);
      await _trimPermissionChangeEvents();
    } catch (e, stackTrace) {
      AppLogger.error('Error saving permission change events', e, stackTrace);
    }
  }

  Future<List<PermissionChangeEvent>> getPermissionChangeEvents({
    int limit = 50,
  }) async {
    try {
      final box = await _ensurePermissionChangesBoxOpen();
      if (box == null) return [];
      final events = <PermissionChangeEvent>[];
      for (final value in box.values) {
        try {
          events.add(PermissionChangeEvent.fromJson(jsonDecode(value)));
        } catch (_) {}
      }
      events.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
      return events.take(limit).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error reading permission change events', e, stackTrace);
      return [];
    }
  }

  Future<void> _trimPermissionChangeEvents() async {
    try {
      final box = await _ensurePermissionChangesBoxOpen();
      if (box == null) return;
      final events = await getPermissionChangeEvents(limit: 500);
      if (events.length < 500) return;
      final keepKeys = events
          .take(250)
          .map(
            (event) =>
                '${event.packageName}_${event.detectedAt.millisecondsSinceEpoch}',
          )
          .toSet();
      final keysToDelete = box.keys
          .where((key) => !keepKeys.contains(key.toString()))
          .toList();
      await box.deleteAll(keysToDelete);
    } catch (_) {}
  }

  Future<void> savePermissionJustification(
    PermissionJustification justification,
  ) async {
    try {
      final box = await _ensureJustificationBoxOpen();
      if (box == null) return;
      final key = '${justification.packageName}_${justification.permission}';
      await box.put(key, jsonEncode(justification.toJson()));
    } catch (e, stackTrace) {
      AppLogger.error('Error saving permission justification', e, stackTrace);
    }
  }

  Future<PermissionJustification?> getPermissionJustification(
    String packageName,
    String permission,
  ) async {
    try {
      final box = await _ensureJustificationBoxOpen();
      if (box == null) return null;
      final key = '${packageName}_$permission';
      final jsonStr = box.get(key);
      if (jsonStr != null) {
        return PermissionJustification.fromJson(jsonDecode(jsonStr));
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error reading permission justification', e, stackTrace);
    }
    return null;
  }

  Future<List<PermissionJustification>> getAllJustifications(
    String packageName,
  ) async {
    try {
      final box = await _ensureJustificationBoxOpen();
      if (box == null) return [];
      final justifications = <PermissionJustification>[];
      for (final key in box.keys) {
        if (key.toString().startsWith(packageName)) {
          final jsonStr = box.get(key);
          if (jsonStr != null) {
            justifications.add(
              PermissionJustification.fromJson(jsonDecode(jsonStr)),
            );
          }
        }
      }
      return justifications;
    } catch (e, stackTrace) {
      AppLogger.error('Error reading justifications', e, stackTrace);
      return [];
    }
  }

  Future<void> saveAppCapabilities(
    String packageName,
    List<String> capabilities,
  ) async {
    try {
      final box = await _ensureCapabilitiesBoxOpen();
      await box?.put(packageName, jsonEncode(capabilities));
    } catch (e, stackTrace) {
      AppLogger.error('Error saving app capabilities', e, stackTrace);
    }
  }

  Future<List<String>> getAppCapabilities(String packageName) async {
    try {
      final box = await _ensureCapabilitiesBoxOpen();
      final json = box?.get(packageName);
      if (json != null) {
        return List<String>.from(jsonDecode(json) as List);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error reading app capabilities', e, stackTrace);
    }
    return [];
  }

  Future<void> clearCache() async {
    try {
      final appsBox = await _ensureAppsBoxOpen();
      final metaBox = await _ensureMetaBoxOpen();
      await appsBox?.clear();
      await metaBox?.delete('apps_fingerprint');
    } catch (e, stackTrace) {
      AppLogger.error('Error clearing cache', e, stackTrace);
    }
  }

  Future<void> clearAllData() async {
    try {
      // Clear boxes only if they're open
      final ops = <Future<dynamic>>[];
      final appsBox = await _ensureAppsBoxOpen();
      final metaBox = await _ensureMetaBoxOpen();
      if (appsBox != null) ops.add(appsBox.clear());
      if (metaBox != null) ops.add(metaBox.clear());
      if (_historyBox?.isOpen ?? false) ops.add(_historyBox!.clear());
      if (_justificationBox?.isOpen ?? false) {
        ops.add(_justificationBox!.clear());
      }
      if (_capabilitiesBox?.isOpen ?? false) {
        ops.add(_capabilitiesBox!.clear());
      }
      if (_permissionChangesBox?.isOpen ?? false) {
        ops.add(_permissionChangesBox!.clear());
      }
      await Future.wait(ops);
    } catch (e, stackTrace) {
      AppLogger.error('Error clearing all data', e, stackTrace);
    }
  }
}

Map<String, String> _encodeAppsForCache(List<AppInfo> apps) {
  final batch = <String, String>{};
  for (int i = 0; i < apps.length; i++) {
    batch['app_$i'] = jsonEncode(apps[i].toJson());
  }
  return batch;
}

List<AppInfo> _decodeCachedApps(List<String> values) {
  final apps = <AppInfo>[];
  for (final value in values) {
    try {
      apps.add(AppInfo.fromJson(jsonDecode(value)));
    } catch (_) {
      // Corrupt entries are ignored; the next scan refreshes the cache.
    }
  }
  return apps;
}
