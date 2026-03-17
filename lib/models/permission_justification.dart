class PermissionJustification {
  final String packageName;
  final String permission;
  final bool isJustified;
  final String? reason;
  final DateTime addedAt;

  PermissionJustification({
    required this.packageName,
    required this.permission,
    required this.isJustified,
    this.reason,
    required this.addedAt,
  });

  factory PermissionJustification.fromJson(Map<String, dynamic> json) {
    return PermissionJustification(
      packageName: json['packageName'] as String,
      permission: json['permission'] as String,
      isJustified: json['isJustified'] as bool,
      reason: json['reason'] as String?,
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'packageName': packageName,
    'permission': permission,
    'isJustified': isJustified,
    'reason': reason,
    'addedAt': addedAt.toIso8601String(),
  };
}

class PermissionHistory {
  final String packageName;
  final String appName;
  final int totalPermissions;
  final int dangerousPermissions;
  final int justifiedPermissions;
  final DateTime scannedAt;

  PermissionHistory({
    required this.packageName,
    required this.appName,
    required this.totalPermissions,
    required this.dangerousPermissions,
    required this.justifiedPermissions,
    required this.scannedAt,
  });

  factory PermissionHistory.fromJson(Map<String, dynamic> json) {
    return PermissionHistory(
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      totalPermissions: json['totalPermissions'] as int,
      dangerousPermissions: json['dangerousPermissions'] as int,
      justifiedPermissions: json['justifiedPermissions'] as int,
      scannedAt: DateTime.parse(json['scannedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'packageName': packageName,
    'appName': appName,
    'totalPermissions': totalPermissions,
    'dangerousPermissions': dangerousPermissions,
    'justifiedPermissions': justifiedPermissions,
    'scannedAt': scannedAt.toIso8601String(),
  };
}
