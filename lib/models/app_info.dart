class AppInfo {
  final String packageName;
  final String appName;
  final String? iconPath;
  final List<String> permissions;
  final RiskLevel riskLevel;
  final int dangerousPermissionCount;
  final int privacyScore;

  AppInfo({
    required this.packageName,
    required this.appName,
    this.iconPath,
    required this.permissions,
    required this.riskLevel,
    required this.dangerousPermissionCount,
    required this.privacyScore,
  });

  factory AppInfo.fromJson(Map<String, dynamic> json) {
    final permissions = List<String>.from(json['permissions'] as List? ?? []);
    return AppInfo(
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      iconPath: json['iconPath'] as String?,
      permissions: permissions,
      riskLevel: RiskLevel.safe,
      dangerousPermissionCount: 0,
      privacyScore: 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'packageName': packageName,
    'appName': appName,
    'iconPath': iconPath,
    'permissions': permissions,
  };
}

enum RiskLevel { safe, medium, dangerous }
