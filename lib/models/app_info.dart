class TrackerInfo {
  final String id;
  final String name;
  final String category;
  final String purpose;
  final int riskWeight;

  const TrackerInfo({
    required this.id,
    required this.name,
    required this.category,
    required this.purpose,
    this.riskWeight = 4,
  });

  factory TrackerInfo.fromJson(Map<String, dynamic> json) {
    return TrackerInfo(
      id: json['id'] as String? ?? 'unknown',
      name: json['name'] as String? ?? 'Unknown tracker',
      category: json['category'] as String? ?? 'Unknown',
      purpose: json['purpose'] as String? ?? 'Collects app or device signals',
      riskWeight: json['riskWeight'] as int? ?? 4,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'purpose': purpose,
    'riskWeight': riskWeight,
  };
}

class RiskSignal {
  final String id;
  final String title;
  final String description;
  final String severity;
  final int weight;

  const RiskSignal({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.weight,
  });

  factory RiskSignal.fromJson(Map<String, dynamic> json) {
    return RiskSignal(
      id: json['id'] as String? ?? 'signal',
      title: json['title'] as String? ?? 'Privacy signal',
      description: json['description'] as String? ?? '',
      severity: json['severity'] as String? ?? 'medium',
      weight: json['weight'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'severity': severity,
    'weight': weight,
  };
}

class StaticScanFinding {
  final String id;
  final String title;
  final String description;
  final String severity;
  final int weight;
  final String evidence;

  const StaticScanFinding({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    this.weight = 0,
    this.evidence = '',
  });

  factory StaticScanFinding.fromJson(Map<String, dynamic> json) {
    return StaticScanFinding(
      id: json['id'] as String? ?? 'static_finding',
      title: json['title'] as String? ?? 'Static scan finding',
      description: json['description'] as String? ?? '',
      severity: json['severity'] as String? ?? 'medium',
      weight: json['weight'] as int? ?? 0,
      evidence: json['evidence'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'severity': severity,
    'weight': weight,
    'evidence': evidence,
  };
}

class AppInfo {
  final String packageName;
  final String appName;
  final String? iconPath;
  final List<String> permissions;
  final RiskLevel riskLevel;
  final int dangerousPermissionCount;
  final int privacyScore;
  final bool isSystemApp;
  final String
  installSource; // 'System', 'Play Store', 'Galaxy Store', 'Unknown'
  final String installerPackageName; // raw installer e.g. 'com.android.vending'
  final List<TrackerInfo> trackers;
  final List<RiskSignal> riskSignals;
  final List<String> malwareIndicators;
  final List<StaticScanFinding> staticFindings;
  final List<String> signerSha256Digests;
  final List<String> nativeArchitectures;
  final int serviceCount;
  final int receiverCount;
  final int activityCount;
  final int providerCount;
  final int targetSdkVersion;
  final int minSdkVersion;
  final int apkSizeBytes;
  final int apkFileCount;
  final int dexFileCount;
  final int nativeLibraryCount;
  final int assetFileCount;
  final String apkSha256;
  final DateTime? firstInstallTime;
  final DateTime? lastUpdateTime;
  final bool hasLauncher;
  final bool declaresAccessibilityService;
  final bool declaresDeviceAdmin;
  final bool requestsOverlayPermission;
  final bool runsAtBoot;
  final bool keepsDeviceAwake;
  final bool usesForegroundService;
  final bool usesExactAlarm;
  final bool requestsBatteryOptimizationBypass;
  final bool hasSmsAccess;
  final bool hasCallAccess;
  final bool hasContactsAccess;
  final bool hasInternetAccess;
  final bool contactsInternetCombo;
  final bool smsCallInternetCombo;
  final bool hiddenLauncher;
  final bool fakeSystemRisk;
  final bool isDebuggable;
  final bool usesKnownPacker;
  final bool hasNativeLibraries;
  final bool staticAnalysisLimitReached;

  AppInfo({
    required this.packageName,
    required this.appName,
    this.iconPath,
    required this.permissions,
    required this.riskLevel,
    required this.dangerousPermissionCount,
    required this.privacyScore,
    required this.isSystemApp,
    required this.installSource,
    this.installerPackageName = '',
    this.trackers = const [],
    this.riskSignals = const [],
    this.malwareIndicators = const [],
    this.staticFindings = const [],
    this.signerSha256Digests = const [],
    this.nativeArchitectures = const [],
    this.serviceCount = 0,
    this.receiverCount = 0,
    this.activityCount = 0,
    this.providerCount = 0,
    this.targetSdkVersion = 0,
    this.minSdkVersion = 0,
    this.apkSizeBytes = 0,
    this.apkFileCount = 0,
    this.dexFileCount = 0,
    this.nativeLibraryCount = 0,
    this.assetFileCount = 0,
    this.apkSha256 = '',
    this.firstInstallTime,
    this.lastUpdateTime,
    this.hasLauncher = true,
    this.declaresAccessibilityService = false,
    this.declaresDeviceAdmin = false,
    this.requestsOverlayPermission = false,
    this.runsAtBoot = false,
    this.keepsDeviceAwake = false,
    this.usesForegroundService = false,
    this.usesExactAlarm = false,
    this.requestsBatteryOptimizationBypass = false,
    this.hasSmsAccess = false,
    this.hasCallAccess = false,
    this.hasContactsAccess = false,
    this.hasInternetAccess = false,
    this.contactsInternetCombo = false,
    this.smsCallInternetCombo = false,
    this.hiddenLauncher = false,
    this.fakeSystemRisk = false,
    this.isDebuggable = false,
    this.usesKnownPacker = false,
    this.hasNativeLibraries = false,
    this.staticAnalysisLimitReached = false,
  });

  AppInfo copyWith({
    String? packageName,
    String? appName,
    String? iconPath,
    List<String>? permissions,
    RiskLevel? riskLevel,
    int? dangerousPermissionCount,
    int? privacyScore,
    bool? isSystemApp,
    String? installSource,
    String? installerPackageName,
    List<TrackerInfo>? trackers,
    List<RiskSignal>? riskSignals,
    List<String>? malwareIndicators,
    List<StaticScanFinding>? staticFindings,
    List<String>? signerSha256Digests,
    List<String>? nativeArchitectures,
    int? serviceCount,
    int? receiverCount,
    int? activityCount,
    int? providerCount,
    int? targetSdkVersion,
    int? minSdkVersion,
    int? apkSizeBytes,
    int? apkFileCount,
    int? dexFileCount,
    int? nativeLibraryCount,
    int? assetFileCount,
    String? apkSha256,
    DateTime? firstInstallTime,
    DateTime? lastUpdateTime,
    bool? hasLauncher,
    bool? declaresAccessibilityService,
    bool? declaresDeviceAdmin,
    bool? requestsOverlayPermission,
    bool? runsAtBoot,
    bool? keepsDeviceAwake,
    bool? usesForegroundService,
    bool? usesExactAlarm,
    bool? requestsBatteryOptimizationBypass,
    bool? hasSmsAccess,
    bool? hasCallAccess,
    bool? hasContactsAccess,
    bool? hasInternetAccess,
    bool? contactsInternetCombo,
    bool? smsCallInternetCombo,
    bool? hiddenLauncher,
    bool? fakeSystemRisk,
    bool? isDebuggable,
    bool? usesKnownPacker,
    bool? hasNativeLibraries,
    bool? staticAnalysisLimitReached,
  }) {
    return AppInfo(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      iconPath: iconPath ?? this.iconPath,
      permissions: permissions ?? this.permissions,
      riskLevel: riskLevel ?? this.riskLevel,
      dangerousPermissionCount:
          dangerousPermissionCount ?? this.dangerousPermissionCount,
      privacyScore: privacyScore ?? this.privacyScore,
      isSystemApp: isSystemApp ?? this.isSystemApp,
      installSource: installSource ?? this.installSource,
      installerPackageName: installerPackageName ?? this.installerPackageName,
      trackers: trackers ?? this.trackers,
      riskSignals: riskSignals ?? this.riskSignals,
      malwareIndicators: malwareIndicators ?? this.malwareIndicators,
      staticFindings: staticFindings ?? this.staticFindings,
      signerSha256Digests: signerSha256Digests ?? this.signerSha256Digests,
      nativeArchitectures: nativeArchitectures ?? this.nativeArchitectures,
      serviceCount: serviceCount ?? this.serviceCount,
      receiverCount: receiverCount ?? this.receiverCount,
      activityCount: activityCount ?? this.activityCount,
      providerCount: providerCount ?? this.providerCount,
      targetSdkVersion: targetSdkVersion ?? this.targetSdkVersion,
      minSdkVersion: minSdkVersion ?? this.minSdkVersion,
      apkSizeBytes: apkSizeBytes ?? this.apkSizeBytes,
      apkFileCount: apkFileCount ?? this.apkFileCount,
      dexFileCount: dexFileCount ?? this.dexFileCount,
      nativeLibraryCount: nativeLibraryCount ?? this.nativeLibraryCount,
      assetFileCount: assetFileCount ?? this.assetFileCount,
      apkSha256: apkSha256 ?? this.apkSha256,
      firstInstallTime: firstInstallTime ?? this.firstInstallTime,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      hasLauncher: hasLauncher ?? this.hasLauncher,
      declaresAccessibilityService:
          declaresAccessibilityService ?? this.declaresAccessibilityService,
      declaresDeviceAdmin: declaresDeviceAdmin ?? this.declaresDeviceAdmin,
      requestsOverlayPermission:
          requestsOverlayPermission ?? this.requestsOverlayPermission,
      runsAtBoot: runsAtBoot ?? this.runsAtBoot,
      keepsDeviceAwake: keepsDeviceAwake ?? this.keepsDeviceAwake,
      usesForegroundService:
          usesForegroundService ?? this.usesForegroundService,
      usesExactAlarm: usesExactAlarm ?? this.usesExactAlarm,
      requestsBatteryOptimizationBypass:
          requestsBatteryOptimizationBypass ??
          this.requestsBatteryOptimizationBypass,
      hasSmsAccess: hasSmsAccess ?? this.hasSmsAccess,
      hasCallAccess: hasCallAccess ?? this.hasCallAccess,
      hasContactsAccess: hasContactsAccess ?? this.hasContactsAccess,
      hasInternetAccess: hasInternetAccess ?? this.hasInternetAccess,
      contactsInternetCombo:
          contactsInternetCombo ?? this.contactsInternetCombo,
      smsCallInternetCombo: smsCallInternetCombo ?? this.smsCallInternetCombo,
      hiddenLauncher: hiddenLauncher ?? this.hiddenLauncher,
      fakeSystemRisk: fakeSystemRisk ?? this.fakeSystemRisk,
      isDebuggable: isDebuggable ?? this.isDebuggable,
      usesKnownPacker: usesKnownPacker ?? this.usesKnownPacker,
      hasNativeLibraries: hasNativeLibraries ?? this.hasNativeLibraries,
      staticAnalysisLimitReached:
          staticAnalysisLimitReached ?? this.staticAnalysisLimitReached,
    );
  }

  factory AppInfo.fromJson(Map<String, dynamic> json) {
    final permissions = List<String>.from(json['permissions'] as List? ?? []);
    final trackers = (json['trackers'] as List? ?? [])
        .whereType<Map>()
        .map((item) => TrackerInfo.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    final riskSignals = (json['riskSignals'] as List? ?? [])
        .whereType<Map>()
        .map((item) => RiskSignal.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    final staticFindings = (json['staticFindings'] as List? ?? [])
        .whereType<Map>()
        .map(
          (item) => StaticScanFinding.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
    return AppInfo(
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      iconPath: json['iconPath'] as String?,
      permissions: permissions,
      riskLevel: _riskLevelFromString(json['riskLevel'] as String?),
      dangerousPermissionCount: json['dangerousPermissionCount'] as int? ?? 0,
      privacyScore: json['privacyScore'] as int? ?? 0,
      isSystemApp: json['isSystemApp'] as bool? ?? false,
      installSource: json['installSource'] as String? ?? 'Unknown',
      installerPackageName: json['installerPackageName'] as String? ?? '',
      trackers: trackers,
      riskSignals: riskSignals,
      malwareIndicators: List<String>.from(
        json['malwareIndicators'] as List? ?? [],
      ),
      staticFindings: staticFindings,
      signerSha256Digests: List<String>.from(
        json['signerSha256Digests'] as List? ?? [],
      ),
      nativeArchitectures: List<String>.from(
        json['nativeArchitectures'] as List? ?? [],
      ),
      serviceCount: json['serviceCount'] as int? ?? 0,
      receiverCount: json['receiverCount'] as int? ?? 0,
      activityCount: json['activityCount'] as int? ?? 0,
      providerCount: json['providerCount'] as int? ?? 0,
      targetSdkVersion: json['targetSdkVersion'] as int? ?? 0,
      minSdkVersion: json['minSdkVersion'] as int? ?? 0,
      apkSizeBytes: json['apkSizeBytes'] as int? ?? 0,
      apkFileCount: json['apkFileCount'] as int? ?? 0,
      dexFileCount: json['dexFileCount'] as int? ?? 0,
      nativeLibraryCount: json['nativeLibraryCount'] as int? ?? 0,
      assetFileCount: json['assetFileCount'] as int? ?? 0,
      apkSha256: json['apkSha256'] as String? ?? '',
      firstInstallTime: _dateFromJson(json['firstInstallTime']),
      lastUpdateTime: _dateFromJson(json['lastUpdateTime']),
      hasLauncher: json['hasLauncher'] as bool? ?? true,
      declaresAccessibilityService:
          json['declaresAccessibilityService'] as bool? ?? false,
      declaresDeviceAdmin: json['declaresDeviceAdmin'] as bool? ?? false,
      requestsOverlayPermission:
          json['requestsOverlayPermission'] as bool? ?? false,
      runsAtBoot: json['runsAtBoot'] as bool? ?? false,
      keepsDeviceAwake: json['keepsDeviceAwake'] as bool? ?? false,
      usesForegroundService: json['usesForegroundService'] as bool? ?? false,
      usesExactAlarm: json['usesExactAlarm'] as bool? ?? false,
      requestsBatteryOptimizationBypass:
          json['requestsBatteryOptimizationBypass'] as bool? ?? false,
      hasSmsAccess: json['hasSmsAccess'] as bool? ?? false,
      hasCallAccess: json['hasCallAccess'] as bool? ?? false,
      hasContactsAccess: json['hasContactsAccess'] as bool? ?? false,
      hasInternetAccess: json['hasInternetAccess'] as bool? ?? false,
      contactsInternetCombo: json['contactsInternetCombo'] as bool? ?? false,
      smsCallInternetCombo: json['smsCallInternetCombo'] as bool? ?? false,
      hiddenLauncher: json['hiddenLauncher'] as bool? ?? false,
      fakeSystemRisk: json['fakeSystemRisk'] as bool? ?? false,
      isDebuggable: json['isDebuggable'] as bool? ?? false,
      usesKnownPacker: json['usesKnownPacker'] as bool? ?? false,
      hasNativeLibraries: json['hasNativeLibraries'] as bool? ?? false,
      staticAnalysisLimitReached:
          json['staticAnalysisLimitReached'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'packageName': packageName,
    'appName': appName,
    'iconPath': iconPath,
    'permissions': permissions,
    'riskLevel': riskLevel.name,
    'dangerousPermissionCount': dangerousPermissionCount,
    'privacyScore': privacyScore,
    'isSystemApp': isSystemApp,
    'installSource': installSource,
    'installerPackageName': installerPackageName,
    'trackers': trackers.map((tracker) => tracker.toJson()).toList(),
    'riskSignals': riskSignals.map((signal) => signal.toJson()).toList(),
    'malwareIndicators': malwareIndicators,
    'staticFindings': staticFindings
        .map((finding) => finding.toJson())
        .toList(),
    'signerSha256Digests': signerSha256Digests,
    'nativeArchitectures': nativeArchitectures,
    'serviceCount': serviceCount,
    'receiverCount': receiverCount,
    'activityCount': activityCount,
    'providerCount': providerCount,
    'targetSdkVersion': targetSdkVersion,
    'minSdkVersion': minSdkVersion,
    'apkSizeBytes': apkSizeBytes,
    'apkFileCount': apkFileCount,
    'dexFileCount': dexFileCount,
    'nativeLibraryCount': nativeLibraryCount,
    'assetFileCount': assetFileCount,
    'apkSha256': apkSha256,
    'firstInstallTime': firstInstallTime?.millisecondsSinceEpoch,
    'lastUpdateTime': lastUpdateTime?.millisecondsSinceEpoch,
    'hasLauncher': hasLauncher,
    'declaresAccessibilityService': declaresAccessibilityService,
    'declaresDeviceAdmin': declaresDeviceAdmin,
    'requestsOverlayPermission': requestsOverlayPermission,
    'runsAtBoot': runsAtBoot,
    'keepsDeviceAwake': keepsDeviceAwake,
    'usesForegroundService': usesForegroundService,
    'usesExactAlarm': usesExactAlarm,
    'requestsBatteryOptimizationBypass': requestsBatteryOptimizationBypass,
    'hasSmsAccess': hasSmsAccess,
    'hasCallAccess': hasCallAccess,
    'hasContactsAccess': hasContactsAccess,
    'hasInternetAccess': hasInternetAccess,
    'contactsInternetCombo': contactsInternetCombo,
    'smsCallInternetCombo': smsCallInternetCombo,
    'hiddenLauncher': hiddenLauncher,
    'fakeSystemRisk': fakeSystemRisk,
    'isDebuggable': isDebuggable,
    'usesKnownPacker': usesKnownPacker,
    'hasNativeLibraries': hasNativeLibraries,
    'staticAnalysisLimitReached': staticAnalysisLimitReached,
  };

  static RiskLevel _riskLevelFromString(String? value) {
    switch (value) {
      case 'medium':
        return RiskLevel.medium;
      case 'high':
      case 'dangerous':
        return RiskLevel.high;
      case 'critical':
        return RiskLevel.critical;
      case 'safe':
      default:
        return RiskLevel.safe;
    }
  }

  static DateTime? _dateFromJson(dynamic value) {
    if (value == null) return null;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String && value.isNotEmpty) {
      final millis = int.tryParse(value);
      if (millis != null) return DateTime.fromMillisecondsSinceEpoch(millis);
      return DateTime.tryParse(value);
    }
    return null;
  }
}

class PermissionChangeEvent {
  final String packageName;
  final String appName;
  final List<String> addedPermissions;
  final List<String> removedPermissions;
  final int beforeScore;
  final int afterScore;
  final RiskLevel beforeRisk;
  final RiskLevel afterRisk;
  final DateTime detectedAt;

  const PermissionChangeEvent({
    required this.packageName,
    required this.appName,
    required this.addedPermissions,
    required this.removedPermissions,
    required this.beforeScore,
    required this.afterScore,
    required this.beforeRisk,
    required this.afterRisk,
    required this.detectedAt,
  });

  bool get hasAddedPermissions => addedPermissions.isNotEmpty;

  factory PermissionChangeEvent.fromJson(Map<String, dynamic> json) {
    return PermissionChangeEvent(
      packageName: json['packageName'] as String? ?? '',
      appName: json['appName'] as String? ?? 'Unknown app',
      addedPermissions: List<String>.from(
        json['addedPermissions'] as List? ?? [],
      ),
      removedPermissions: List<String>.from(
        json['removedPermissions'] as List? ?? [],
      ),
      beforeScore: json['beforeScore'] as int? ?? 100,
      afterScore: json['afterScore'] as int? ?? 100,
      beforeRisk: AppInfo._riskLevelFromString(json['beforeRisk'] as String?),
      afterRisk: AppInfo._riskLevelFromString(json['afterRisk'] as String?),
      detectedAt: AppInfo._dateFromJson(json['detectedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'packageName': packageName,
    'appName': appName,
    'addedPermissions': addedPermissions,
    'removedPermissions': removedPermissions,
    'beforeScore': beforeScore,
    'afterScore': afterScore,
    'beforeRisk': beforeRisk.name,
    'afterRisk': afterRisk.name,
    'detectedAt': detectedAt.millisecondsSinceEpoch,
  };
}

enum RiskLevel { safe, medium, high, critical }

extension RiskLevelLabels on RiskLevel {
  String get label {
    switch (this) {
      case RiskLevel.safe:
        return 'Safe';
      case RiskLevel.medium:
        return 'Medium Risk';
      case RiskLevel.high:
        return 'High Risk';
      case RiskLevel.critical:
        return 'Critical';
    }
  }

  int get sortRank {
    switch (this) {
      case RiskLevel.critical:
        return 0;
      case RiskLevel.high:
        return 1;
      case RiskLevel.medium:
        return 2;
      case RiskLevel.safe:
        return 3;
    }
  }
}
