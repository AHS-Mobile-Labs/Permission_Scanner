import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/services/permission_justification_service.dart';
import 'package:permission_scanner/utils/permission_database.dart';

class PermissionAnalyzer {
  static const Map<String, int> _permissionWeights = {
    'android.permission.ACCESS_BACKGROUND_LOCATION': 14,
    'android.permission.ACCESS_FINE_LOCATION': 10,
    'android.permission.ACCESS_COARSE_LOCATION': 7,
    'android.permission.CAMERA': 8,
    'android.permission.RECORD_AUDIO': 10,
    'android.permission.READ_SMS': 16,
    'android.permission.SEND_SMS': 18,
    'android.permission.RECEIVE_SMS': 12,
    'android.permission.READ_CALL_LOG': 14,
    'android.permission.WRITE_CALL_LOG': 14,
    'android.permission.READ_CONTACTS': 10,
    'android.permission.WRITE_CONTACTS': 10,
    'android.permission.READ_PHONE_STATE': 8,
    'android.permission.READ_PHONE_NUMBERS': 10,
    'android.permission.ANSWER_PHONE_CALLS': 11,
    'android.permission.CALL_PHONE': 12,
    'android.permission.BODY_SENSORS': 12,
    'android.permission.BLUETOOTH_SCAN': 7,
    'android.permission.BLUETOOTH_CONNECT': 5,
    'android.permission.READ_CALENDAR': 8,
    'android.permission.WRITE_CALENDAR': 8,
    'android.permission.READ_EXTERNAL_STORAGE': 6,
    'android.permission.WRITE_EXTERNAL_STORAGE': 6,
    'android.permission.READ_MEDIA_IMAGES': 5,
    'android.permission.READ_MEDIA_VIDEO': 5,
    'android.permission.READ_MEDIA_AUDIO': 4,
    'android.permission.ACTIVITY_RECOGNITION': 5,
    'android.permission.POST_NOTIFICATIONS': 2,
  };

  static RiskLevel analyzeRiskLevel(int dangerousPermissionCount) {
    if (dangerousPermissionCount == 0) return RiskLevel.safe;
    if (dangerousPermissionCount <= 3) return RiskLevel.medium;
    if (dangerousPermissionCount <= 7) return RiskLevel.high;
    return RiskLevel.critical;
  }

  static RiskLevel riskLevelForScore(int score) {
    if (score >= 85) return RiskLevel.safe;
    if (score >= 65) return RiskLevel.medium;
    if (score >= 40) return RiskLevel.high;
    return RiskLevel.critical;
  }

  static int calculatePrivacyScore(List<String> permissions) {
    var penalty = 0;
    for (final permission in permissions) {
      penalty +=
          _permissionWeights[permission] ??
          (dangerousPermissions.contains(permission) ? 6 : 0);
    }
    return (100 - penalty).clamp(0, 100).toInt();
  }

  static int countDangerousPermissions(List<String> permissions) {
    return permissions.where((p) => dangerousPermissions.contains(p)).length;
  }

  static AppInfo enrichAppInfo(AppInfo baseInfo) {
    final permissionSet = baseInfo.permissions.toSet();
    final trackers = _deduplicateTrackers([
      ...baseInfo.trackers,
      ..._inferTrackers(baseInfo),
    ]);
    final dangerousCount = countDangerousPermissions(baseInfo.permissions);
    final signals = <RiskSignal>[];
    var penalty = 0;

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
      penalty += weight;
    }

    for (final permission in permissionSet) {
      penalty +=
          _permissionWeights[permission] ??
          (dangerousPermissions.contains(permission) ? 6 : 0);
    }

    if (dangerousCount > 0) {
      addSignal(
        id: 'dangerous_permissions',
        title: '$dangerousCount sensitive permissions',
        description:
            'This app requests permissions that can expose personal data, sensors, messages, files, or device identity.',
        severity: dangerousCount >= 7
            ? 'critical'
            : dangerousCount >= 4
            ? 'high'
            : 'medium',
        weight: (dangerousCount * 2).clamp(4, 16),
      );
    }

    if (_hasAny(permissionSet, const [
      'android.permission.CAMERA',
      'android.permission.RECORD_AUDIO',
    ])) {
      addSignal(
        id: 'sensor_access',
        title: 'Camera or microphone access',
        description:
            'Sensor permissions deserve extra attention because they can capture the room around you.',
        severity: 'high',
        weight: 8,
      );
    }

    if (_hasAny(permissionSet, const [
      'android.permission.ACCESS_BACKGROUND_LOCATION',
      'android.permission.ACCESS_FINE_LOCATION',
      'android.permission.ACCESS_COARSE_LOCATION',
    ])) {
      addSignal(
        id: 'location_access',
        title: 'Location intelligence',
        description:
            'Location permissions can reveal routines, home/work patterns, and places you visit.',
        severity:
            permissionSet.contains(
              'android.permission.ACCESS_BACKGROUND_LOCATION',
            )
            ? 'critical'
            : 'high',
        weight:
            permissionSet.contains(
              'android.permission.ACCESS_BACKGROUND_LOCATION',
            )
            ? 14
            : 8,
      );
    }

    if (baseInfo.declaresAccessibilityService) {
      addSignal(
        id: 'accessibility_service',
        title: 'Accessibility service declared',
        description:
            'Accessibility services can read screen content and automate taps. This is powerful and commonly abused by spyware and banking malware.',
        severity: 'critical',
        weight: 24,
      );
    }

    if (baseInfo.requestsOverlayPermission) {
      addSignal(
        id: 'overlay_permission',
        title: 'Display over other apps',
        description:
            'Overlay permission can place fake screens on top of real apps and is a common phishing technique.',
        severity: 'high',
        weight: 18,
      );
    }

    if (baseInfo.declaresDeviceAdmin) {
      addSignal(
        id: 'device_admin',
        title: 'Device admin capability',
        description:
            'Device admin can make an app hard to remove and can enforce device-level controls.',
        severity: 'critical',
        weight: 22,
      );
    }

    if (baseInfo.contactsInternetCombo) {
      addSignal(
        id: 'contacts_internet_combo',
        title: 'Contacts plus internet',
        description:
            'The app can read contacts and also communicate online, which increases data-exfiltration risk.',
        severity: 'high',
        weight: 12,
      );
    }

    if (baseInfo.smsCallInternetCombo) {
      addSignal(
        id: 'sms_call_internet_combo',
        title: 'SMS or calls plus internet',
        description:
            'Messaging or call access combined with internet access can expose verification codes, call history, or phone identity.',
        severity: 'critical',
        weight: 16,
      );
    }

    if (baseInfo.hiddenLauncher) {
      addSignal(
        id: 'hidden_launcher',
        title: 'Hidden launcher behavior',
        description:
            'The app has no visible launcher entry. Legitimate helpers can do this, but stalkerware and droppers often hide this way.',
        severity: baseInfo.isSystemApp ? 'medium' : 'high',
        weight: baseInfo.isSystemApp ? 6 : 18,
      );
    }

    if (baseInfo.runsAtBoot ||
        baseInfo.usesForegroundService ||
        baseInfo.requestsBatteryOptimizationBypass ||
        baseInfo.keepsDeviceAwake) {
      addSignal(
        id: 'background_persistence',
        title: 'Persistent background behavior',
        description:
            'The app can keep work running after reboot, stay awake, or ask Android to reduce battery limits.',
        severity: 'medium',
        weight: 8,
      );
    }

    if (baseInfo.fakeSystemRisk) {
      addSignal(
        id: 'fake_system_app',
        title: 'Possible fake system app',
        description:
            'The app name resembles a system/security component, but it is not installed as a trusted system app.',
        severity: 'critical',
        weight: 24,
      );
    }

    if (baseInfo.usesKnownPacker) {
      addSignal(
        id: 'known_packer',
        title: 'Packed or shielded APK',
        description:
            'The APK contains signs of commercial packing/protection. This can be legitimate, but it also makes inspection harder.',
        severity: 'high',
        weight: 12,
      );
    }

    if (baseInfo.isDebuggable && !baseInfo.isSystemApp) {
      addSignal(
        id: 'debuggable_release',
        title: 'Debuggable build',
        description:
            'The app is marked debuggable, which is unusual for production apps and can increase tampering risk.',
        severity: 'medium',
        weight: 8,
      );
    }

    if (!baseInfo.isSystemApp &&
        baseInfo.installSource == 'Unknown' &&
        dangerousCount > 0) {
      addSignal(
        id: 'unknown_source_sensitive',
        title: 'Unknown source with sensitive access',
        description:
            'Sideloaded apps with sensitive permissions need stronger scrutiny because store review and update provenance are unclear.',
        severity: 'high',
        weight: 12,
      );
    }

    for (final tracker in trackers) {
      addSignal(
        id: 'tracker_${tracker.id}',
        title: tracker.name,
        description: tracker.purpose,
        severity: tracker.riskWeight >= 8 ? 'high' : 'medium',
        weight: tracker.riskWeight,
      );
    }

    if (baseInfo.declaresAccessibilityService &&
        baseInfo.requestsOverlayPermission &&
        (baseInfo.hasSmsAccess || baseInfo.hasCallAccess)) {
      addSignal(
        id: 'banking_trojan_pattern',
        title: 'Banking trojan pattern',
        description:
            'Accessibility, overlays, and SMS/call access together match a common banking trojan abuse pattern.',
        severity: 'critical',
        weight: 28,
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
        title: 'Stalkerware pattern',
        description:
            'Hidden launcher behavior combined with accessibility or location/message access is a stalkerware warning sign.',
        severity: 'critical',
        weight: 30,
      );
    }

    if (baseInfo.runsAtBoot &&
        baseInfo.hasSmsAccess &&
        baseInfo.hasInternetAccess) {
      addSignal(
        id: 'silent_sms_pattern',
        title: 'Silent SMS relay pattern',
        description:
            'Boot persistence with SMS and internet access can be abused to monitor or forward messages quietly.',
        severity: 'critical',
        weight: 24,
      );
    }

    final score = (100 - penalty).clamp(0, 100).toInt();
    final riskLevel = riskLevelForScore(score);
    final malwareIndicators = signals
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
      malwareIndicators: malwareIndicators,
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
          tracker.category.toLowerCase().contains('ad') ||
          tracker.id.contains('admob') ||
          tracker.id.contains('ads'),
    );

    if (hasAdId && !knownAdTracker) {
      trackers.add(
        const TrackerInfo(
          id: 'unknown_advertising_id',
          name: 'Unknown advertising identifier use',
          category: 'Advertising',
          purpose:
              'The app requests the Google advertising identifier, but no known ad SDK was identified in the lightweight scan.',
          riskWeight: 7,
        ),
      );
    }

    return trackers;
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
