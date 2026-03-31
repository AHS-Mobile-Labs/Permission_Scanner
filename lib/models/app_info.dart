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
    );
  }

  factory AppInfo.fromJson(Map<String, dynamic> json) {
    final permissions = List<String>.from(json['permissions'] as List? ?? []);
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
  };

  static RiskLevel _riskLevelFromString(String? value) {
    switch (value) {
      case 'medium':
        return RiskLevel.medium;
      case 'dangerous':
        return RiskLevel.dangerous;
      default:
        return RiskLevel.safe;
    }
  }
}

enum RiskLevel { safe, medium, dangerous }
