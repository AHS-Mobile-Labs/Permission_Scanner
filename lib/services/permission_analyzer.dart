import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/services/permission_justification_service.dart';
import 'package:permission_scanner/utils/permission_database.dart';

class PermissionAnalyzer {
  static const Map<String, int> _permissionWeights = {
    'android.permission.ACCESS_BACKGROUND_LOCATION': 12,
    'android.permission.ACCESS_FINE_LOCATION': 8,
    'android.permission.ACCESS_COARSE_LOCATION': 4,
    'android.permission.CAMERA': 8,
    'android.permission.RECORD_AUDIO': 8,
    'android.permission.READ_SMS': 12,
    'android.permission.SEND_SMS': 14,
    'android.permission.RECEIVE_SMS': 8,
    'android.permission.READ_CALL_LOG': 12,
    'android.permission.WRITE_CALL_LOG': 10,
    'android.permission.READ_CONTACTS': 8,
    'android.permission.WRITE_CONTACTS': 6,
    'android.permission.READ_PHONE_STATE': 6,
    'android.permission.READ_PHONE_NUMBERS': 8,
    'android.permission.ANSWER_PHONE_CALLS': 8,
    'android.permission.CALL_PHONE': 10,
    'android.permission.BODY_SENSORS': 8,
    'android.permission.BODY_SENSORS_BACKGROUND': 10,
    'android.permission.BLUETOOTH_SCAN': 5,
    'android.permission.BLUETOOTH_CONNECT': 4,
    'android.permission.READ_CALENDAR': 6,
    'android.permission.WRITE_CALENDAR': 6,
    'android.permission.MANAGE_EXTERNAL_STORAGE': 12,
    'android.permission.READ_EXTERNAL_STORAGE': 6,
    'android.permission.WRITE_EXTERNAL_STORAGE': 6,
    'android.permission.READ_MEDIA_IMAGES': 5,
    'android.permission.READ_MEDIA_VIDEO': 5,
    'android.permission.READ_MEDIA_AUDIO': 4,
    'android.permission.ACTIVITY_RECOGNITION': 4,
    'android.permission.POST_NOTIFICATIONS': 2,
    'android.permission.NEARBY_WIFI_DEVICES': 4,
  };

  static RiskLevel analyzeRiskLevel(int dangerousPermissionCount) {
    if (dangerousPermissionCount <= 0) return RiskLevel.safe;
    if (dangerousPermissionCount <= 3) return RiskLevel.medium;
    if (dangerousPermissionCount <= 6) return RiskLevel.high;
    return RiskLevel.critical;
  }

  static RiskLevel riskLevelForScore(int score) {
    if (score >= 80) return RiskLevel.safe;
    if (score >= 60) return RiskLevel.medium;
    if (score >= 35) return RiskLevel.high;
    return RiskLevel.critical;
  }

  /// Calculates privacy score with deduplication and domain caps.
  /// Score scale is 0-100 (100 is cleanest, 0 is highest risk).
  static int calculatePrivacyScore(List<String> permissions) {
    final dummyApp = AppInfo(
      packageName: 'preview.package',
      appName: 'Preview App',
      permissions: permissions,
      riskLevel: RiskLevel.safe,
      dangerousPermissionCount: countDangerousPermissions(permissions),
      privacyScore: 100,
      isSystemApp: false,
      installSource: 'Unknown',
    );
    return enrichAppInfo(dummyApp).privacyScore;
  }

  static int countDangerousPermissions(List<String> permissions) {
    return permissions.where((p) => dangerousPermissions.contains(p)).length;
  }

  static AppInfo enrichAppInfo(AppInfo baseInfo) {
    final permissionSet = baseInfo.permissions.toSet();
    final nativeTrackers = _sanitizeTrackers(baseInfo);
    final trackers = _deduplicateTrackers([
      ...nativeTrackers,
      ..._inferTrackers(baseInfo),
    ]);
    final dangerousCount = countDangerousPermissions(baseInfo.permissions);
    final signals = <RiskSignal>[];

    // ── 1. Calculate Deduplicated Permission Penalties ──
    var rawPermPenalty = 0;
    final hasFineLocation = permissionSet.contains(
      'android.permission.ACCESS_FINE_LOCATION',
    );
    final hasManageStorage = permissionSet.contains(
      'android.permission.MANAGE_EXTERNAL_STORAGE',
    );
    final hasReadStorage = permissionSet.contains(
      'android.permission.READ_EXTERNAL_STORAGE',
    );

    for (final permission in permissionSet) {
      // Deduplicate fine/coarse location: fine already grants precise location
      if (permission == 'android.permission.ACCESS_COARSE_LOCATION' &&
          hasFineLocation) {
        continue;
      }
      // Deduplicate storage: MANAGE_EXTERNAL_STORAGE encompasses all other storage permissions
      if (hasManageStorage &&
          (permission == 'android.permission.READ_EXTERNAL_STORAGE' ||
              permission == 'android.permission.WRITE_EXTERNAL_STORAGE' ||
              permission == 'android.permission.READ_MEDIA_IMAGES' ||
              permission == 'android.permission.READ_MEDIA_VIDEO' ||
              permission == 'android.permission.READ_MEDIA_AUDIO')) {
        continue;
      }
      // Deduplicate media if general read storage is already granted
      if (hasReadStorage &&
          (permission == 'android.permission.READ_MEDIA_IMAGES' ||
              permission == 'android.permission.READ_MEDIA_VIDEO' ||
              permission == 'android.permission.READ_MEDIA_AUDIO')) {
        continue;
      }

      final weight =
          _permissionWeights[permission] ??
          (dangerousPermissions.contains(permission) ? 5 : 0);
      rawPermPenalty += weight;
    }

    // Cap base permission penalty to avoid dropping rich utility apps to 0 solely on declared permissions
    final permissionPenalty = rawPermPenalty.clamp(0, 50);

    // ── 2. Structural & Behavioral Risk Signals ──
    var signalPenalty = 0;

    void addSignal({
      required String id,
      required String title,
      required String description,
      required String severity,
      required int weight,
    }) {
      if (signals.any((signal) => signal.id == id)) return;
      signals.add(
        RiskSignal(
          id: id,
          title: title,
          description: description,
          severity: severity,
          weight: weight,
        ),
      );
      signalPenalty += weight;
    }

    // Contextual permission synergy signal (informational, small synergy penalty)
    if (dangerousCount >= 5) {
      addSignal(
        id: 'dangerous_permissions',
        title: '$dangerousCount sensitive permissions declared',
        description:
            'This application declares a broad set of sensitive permissions spanning multiple subsystem domains.',
        severity: dangerousCount >= 8 ? 'critical' : 'high',
        weight: dangerousCount >= 8 ? 6 : 3,
      );
    } else if (dangerousCount >= 1) {
      signals.add(
        RiskSignal(
          id: 'dangerous_permissions',
          title: '$dangerousCount sensitive permissions',
          description:
              'Declares permissions classified by Android as runtime sensitive.',
          severity: dangerousCount >= 3 ? 'medium' : 'low',
          weight:
              0, // No extra duplicate penalty; permissions already contributed
        ),
      );
    }

    // Sensor synergy (camera & microphone combined access)
    final hasCamera = permissionSet.contains('android.permission.CAMERA');
    final hasMic = permissionSet.contains('android.permission.RECORD_AUDIO');
    if (hasCamera && hasMic) {
      addSignal(
        id: 'sensor_access',
        title: 'Concurrent camera and microphone access',
        description:
            'The app can record audio and capture photos/videos simultaneously.',
        severity: 'high',
        weight: 4,
      );
    } else if (hasCamera || hasMic) {
      signals.add(
        RiskSignal(
          id: 'sensor_access',
          title: hasCamera
              ? 'Camera access declared'
              : 'Audio recording declared',
          description:
              'Hardware sensor permissions warrant attention when not expected for core app features.',
          severity: 'medium',
          weight: 0,
        ),
      );
    }

    // Location synergy
    if (permissionSet.contains(
      'android.permission.ACCESS_BACKGROUND_LOCATION',
    )) {
      addSignal(
        id: 'background_location',
        title: 'Background location tracking',
        description:
            'The app can track device movement and location even when not actively in use.',
        severity: 'critical',
        weight: 6,
      );
    }

    // High-privilege subsystem capabilities
    if (baseInfo.declaresAccessibilityService) {
      addSignal(
        id: 'accessibility_service',
        title: 'Accessibility service declared',
        description:
            'Accessibility services can read screen contents and interact with other apps. This requires high trust.',
        severity: 'critical',
        weight: 18,
      );
    }

    if (baseInfo.declaresDeviceAdmin) {
      addSignal(
        id: 'device_admin',
        title: 'Device administration capability',
        description:
            'Device admin privileges can enforce system policies and hinder uninstallation.',
        severity: 'critical',
        weight: 16,
      );
    }

    if (baseInfo.requestsOverlayPermission) {
      addSignal(
        id: 'overlay_permission',
        title: 'Display over other apps (System alert window)',
        description:
            'Overlay capability allows drawing floating windows or views over other running applications.',
        severity: 'high',
        weight: 8,
      );
    }

    if (baseInfo.contactsInternetCombo) {
      addSignal(
        id: 'contacts_internet_combo',
        title: 'Contacts access with network capability',
        description:
            'The app can read contact records and has full network access for potential external transmission.',
        severity: 'medium',
        weight: 5,
      );
    }

    if (baseInfo.smsCallInternetCombo) {
      addSignal(
        id: 'sms_call_internet_combo',
        title: 'Call/SMS access with network capability',
        description:
            'Combines telephony/messaging permissions with internet connectivity.',
        severity: 'high',
        weight: 6,
      );
    }

    if (baseInfo.hiddenLauncher) {
      addSignal(
        id: 'hidden_launcher',
        title: 'No launcher icon declared',
        description:
            'The application does not provide an entry in the system app launcher.',
        severity: baseInfo.isSystemApp ? 'medium' : 'high',
        weight: baseInfo.isSystemApp ? 4 : 10,
      );
    }

    if (baseInfo.runsAtBoot ||
        baseInfo.usesForegroundService ||
        baseInfo.requestsBatteryOptimizationBypass ||
        baseInfo.keepsDeviceAwake) {
      addSignal(
        id: 'background_persistence',
        title: 'Persistent background execution',
        description:
            'Declares capabilities to run at boot, keep CPU awake, or request battery optimization exclusions.',
        severity: 'medium',
        weight: 4,
      );
    }

    if (baseInfo.fakeSystemRisk) {
      addSignal(
        id: 'fake_system_app',
        title: 'Non-system app mimicking system package',
        description:
            'The package name or label resembles core Android components, but is installed as a third-party app.',
        severity: 'critical',
        weight: 18,
      );
    }

    if (baseInfo.usesKnownPacker) {
      addSignal(
        id: 'known_packer',
        title: 'Protected or packed APK binary',
        description:
            'The APK exhibits signatures of commercial bytecode packing or obfuscation.',
        severity: 'medium',
        weight: 6,
      );
    }

    if (baseInfo.isDebuggable && !baseInfo.isSystemApp) {
      addSignal(
        id: 'debuggable_release',
        title: 'Debuggable build flag enabled',
        description:
            'The Android manifest has android:debuggable="true", which is unusual for production distribution.',
        severity: 'medium',
        weight: 6,
      );
    }

    if (!baseInfo.isSystemApp &&
        baseInfo.installSource == 'Unknown' &&
        dangerousCount > 0) {
      addSignal(
        id: 'unknown_source_sensitive',
        title: 'Sideloaded package with sensitive permissions',
        description:
            'Installed from an unrecognized source or direct APK file rather than an official app store.',
        severity: 'medium',
        weight: 6,
      );
    }

    // Heuristic abuse patterns
    if (baseInfo.declaresAccessibilityService &&
        baseInfo.requestsOverlayPermission &&
        (baseInfo.hasSmsAccess || baseInfo.hasCallAccess)) {
      addSignal(
        id: 'banking_trojan_pattern',
        title: 'Heuristic overlay and accessibility pattern',
        description:
            'Accessibility, overlay, and SMS/call privileges together form a high-risk combination often targeted in security audits.',
        severity: 'critical',
        weight: 14,
      );
    }

    if (baseInfo.hiddenLauncher &&
        baseInfo.declaresAccessibilityService &&
        (baseInfo.hasSmsAccess ||
            permissionSet.contains(
              'android.permission.ACCESS_BACKGROUND_LOCATION',
            ))) {
      addSignal(
        id: 'stalkerware_pattern',
        title: 'Heuristic background surveillance pattern',
        description:
            'Hidden launcher presence with accessibility or location/SMS access matches common background surveillance indicators.',
        severity: 'critical',
        weight: 14,
      );
    }

    if (baseInfo.runsAtBoot &&
        baseInfo.hasSmsAccess &&
        baseInfo.hasInternetAccess) {
      addSignal(
        id: 'silent_sms_pattern',
        title: 'Boot persistence with SMS and network access',
        description:
            'Can process messages upon boot with external communication channels.',
        severity: 'high',
        weight: 8,
      );
    }

    // ── 3. Static Findings from APK Inspection ──
    var staticFindingsPenalty = 0;
    for (final finding in baseInfo.staticFindings) {
      addSignal(
        id: 'static_${finding.id}',
        title: finding.title,
        description: finding.description,
        severity: finding.severity,
        weight: finding.weight,
      );
      staticFindingsPenalty += finding.weight;
    }
    staticFindingsPenalty = staticFindingsPenalty.clamp(0, 15);

    // ── 4. Trackers ──
    var trackersPenalty = 0;
    for (final tracker in trackers) {
      final trackerWeight = (tracker.riskWeight).clamp(1, 5);
      addSignal(
        id: 'tracker_${tracker.id}',
        title: tracker.name,
        description: tracker.purpose,
        severity: tracker.riskWeight >= 8 ? 'high' : 'medium',
        weight: trackerWeight,
      );
      trackersPenalty += trackerWeight;
    }
    trackersPenalty = trackersPenalty.clamp(0, 12);

    // ── 5. Total Calibrated Score Calculation ──
    final totalPenalty =
        (permissionPenalty +
                signalPenalty.clamp(0, 45) +
                staticFindingsPenalty +
                trackersPenalty)
            .clamp(0, 100);

    final score = (100 - totalPenalty).clamp(0, 100).toInt();
    final riskLevel = riskLevelForScore(score);

    // Heuristic signals that warrant manual scrutiny
    final heuristicSecuritySignals = signals
        .where(
          (signal) =>
              signal.severity == 'critical' ||
              signal.id.contains('pattern') ||
              signal.id == 'fake_system_app',
        )
        .map((signal) => signal.title)
        .toList();

    return baseInfo.copyWith(
      trackers: trackers,
      riskSignals: signals..sort((a, b) => b.weight.compareTo(a.weight)),
      malwareIndicators: heuristicSecuritySignals,
      dangerousPermissionCount: dangerousCount,
      privacyScore: score,
      riskLevel: riskLevel,
      hasSmsAccess:
          baseInfo.hasSmsAccess ||
          _hasAny(permissionSet, const [
            'android.permission.READ_SMS',
            'android.permission.SEND_SMS',
            'android.permission.RECEIVE_SMS',
            'android.permission.RECEIVE_MMS',
          ]),
      hasCallAccess:
          baseInfo.hasCallAccess ||
          _hasAny(permissionSet, const [
            'android.permission.READ_CALL_LOG',
            'android.permission.WRITE_CALL_LOG',
            'android.permission.READ_PHONE_STATE',
            'android.permission.READ_PHONE_NUMBERS',
            'android.permission.ANSWER_PHONE_CALLS',
            'android.permission.CALL_PHONE',
          ]),
      hasContactsAccess:
          baseInfo.hasContactsAccess ||
          _hasAny(permissionSet, const [
            'android.permission.READ_CONTACTS',
            'android.permission.WRITE_CONTACTS',
          ]),
      hasInternetAccess:
          baseInfo.hasInternetAccess ||
          permissionSet.contains('android.permission.INTERNET'),
    );
  }

  /// Analyze permissions with justification scoring.
  static Map<String, dynamic> analyzeWithJustification(
    AppInfo app,
    List<String> appCapabilities,
  ) {
    final analysis = PermissionJustificationService.analyzePermissions(
      app.permissions,
      appCapabilities,
    );

    final justifiedPercentage = app.permissions.isEmpty
        ? 0
        : (analysis['justifiedCount'] as int) / app.permissions.length * 100;

    final adjustedRisk = justifiedPercentage > 80
        ? _reduceRiskLevel(app.riskLevel)
        : app.riskLevel;

    return {
      'originalRisk': app.riskLevel,
      'adjustedRisk': adjustedRisk,
      'justifiedPercentage': justifiedPercentage.toStringAsFixed(1),
      'analysis': analysis,
    };
  }

  static RiskLevel _reduceRiskLevel(RiskLevel level) {
    if (level == RiskLevel.critical) return RiskLevel.high;
    if (level == RiskLevel.high) return RiskLevel.medium;
    if (level == RiskLevel.medium) return RiskLevel.safe;
    return RiskLevel.safe;
  }

  static List<TrackerInfo> _inferTrackers(AppInfo app) {
    final trackers = <TrackerInfo>[];
    final hasAdId = app.permissions.contains(
      'com.google.android.gms.permission.AD_ID',
    );
    final knownAdTracker = app.trackers.any(
      (tracker) =>
          !_isUnknownAdvertisingIdentifierTracker(tracker) &&
          _isKnownAdvertisingIdentifierConsumer(tracker),
    );

    if (hasAdId && !knownAdTracker && _hasCompletedTrackerScan(app)) {
      trackers.add(
        const TrackerInfo(
          id: 'unknown_ad_id',
          name: 'Advertising identifier requested',
          category: 'Advertising',
          purpose:
              'The app requests the Google advertising ID without a recognized major ad network SDK.',
          riskWeight: 4,
          evidence:
              'Permission com.google.android.gms.permission.AD_ID is requested.',
          confidence: 60,
        ),
      );
    }

    return trackers;
  }

  static List<TrackerInfo> _sanitizeTrackers(AppInfo app) {
    final hasKnownAdIdConsumer = app.trackers.any(
      (tracker) =>
          !_isUnknownAdvertisingIdentifierTracker(tracker) &&
          _isKnownAdvertisingIdentifierConsumer(tracker),
    );
    final hasCompletedScan = _hasCompletedTrackerScan(app);

    return app.trackers.where((tracker) {
      if (!_isUnknownAdvertisingIdentifierTracker(tracker)) return true;
      if (hasKnownAdIdConsumer) return false;
      return hasCompletedScan &&
          (tracker.evidence.isNotEmpty || tracker.confidence > 0);
    }).toList();
  }

  static bool _hasCompletedTrackerScan(AppInfo app) {
    return app.apkFileCount > 0 ||
        app.dexFileCount > 0 ||
        app.nativeLibraryCount > 0 ||
        app.staticAnalysisLimitReached ||
        app.staticFindings.isNotEmpty ||
        app.apkSha256.isNotEmpty;
  }

  static bool _isUnknownAdvertisingIdentifierTracker(TrackerInfo tracker) {
    return tracker.id == 'unknown_ad_id' ||
        tracker.id == 'unknown_advertising_id' ||
        tracker.name.toLowerCase().contains('advertising identifier');
  }

  static bool _isKnownAdvertisingIdentifierConsumer(TrackerInfo tracker) {
    final id = tracker.id.toLowerCase();
    final category = tracker.category.toLowerCase();
    return category.contains('advertising') ||
        category.contains('ads') ||
        category.contains('attribution') ||
        id == 'admob' ||
        id == 'facebook_sdk' ||
        id == 'facebook_audience_network' ||
        id == 'appsflyer' ||
        id == 'adjust' ||
        id == 'branch' ||
        id == 'kochava' ||
        id == 'airbridge' ||
        id == 'singular' ||
        id == 'tenjin' ||
        id == 'unity_ads' ||
        id == 'applovin' ||
        id == 'ironsource' ||
        id == 'inmobi' ||
        id == 'pangle' ||
        id == 'vungle' ||
        id == 'chartboost' ||
        id == 'tapjoy' ||
        id == 'mintegral' ||
        id == 'fyber';
  }

  static List<TrackerInfo> _deduplicateTrackers(List<TrackerInfo> trackers) {
    final byId = <String, TrackerInfo>{};
    for (final tracker in trackers) {
      byId[tracker.id] = tracker;
    }
    return byId.values.toList()
      ..sort((a, b) => b.riskWeight.compareTo(a.riskWeight));
  }

  static bool _hasAny(Set<String> permissions, List<String> candidates) {
    return candidates.any(permissions.contains);
  }
}
