class PermissionJustificationService {
  // Map of app capabilities to required permissions
  static const Map<String, List<String>> capabilityToPermissions = {
    'Take Photos': ['android.permission.CAMERA'],
    'Record Audio': [
      'android.permission.RECORD_AUDIO',
      'android.permission.MICROPHONE',
    ],
    'Access Photos': ['android.permission.READ_EXTERNAL_STORAGE'],
    'Access Location': [
      'android.permission.ACCESS_FINE_LOCATION',
      'android.permission.ACCESS_COARSE_LOCATION',
    ],
    'Access Contacts': [
      'android.permission.READ_CONTACTS',
      'android.permission.WRITE_CONTACTS',
    ],
    'Send SMS': ['android.permission.SEND_SMS'],
    'Make Calls': ['android.permission.CALL_PHONE'],
    'Access Calendar': [
      'android.permission.READ_CALENDAR',
      'android.permission.WRITE_CALENDAR',
    ],
    'Access Phone State': ['android.permission.READ_PHONE_STATE'],
    'Read Call Logs': [
      'android.permission.READ_CALL_LOG',
      'android.permission.READ_PHONE_STATE',
    ],
    'Use Bluetooth': ['android.permission.BLUETOOTH'],
    'Access Files': [
      'android.permission.READ_EXTERNAL_STORAGE',
      'android.permission.WRITE_EXTERNAL_STORAGE',
    ],
  };

  /// Get all possible app capabilities
  static List<String> getAllCapabilities() {
    return capabilityToPermissions.keys.toList();
  }

  /// Get permissions needed for a capability
  static List<String> getPermissionsForCapability(String capability) {
    return capabilityToPermissions[capability] ?? [];
  }

  /// Get capabilities that align with given permissions
  static List<String> matchCapabilitiesToPermissions(List<String> permissions) {
    final matches = <String>[];
    for (final capability in capabilityToPermissions.keys) {
      final requiredPerms = capabilityToPermissions[capability]!;
      if (requiredPerms.every((perm) => permissions.contains(perm))) {
        matches.add(capability);
      }
    }
    return matches;
  }

  /// Check if permission is justified based on app functionality
  static bool isPermissionJustified(
    String permission,
    List<String> appCapabilities,
  ) {
    for (final capability in appCapabilities) {
      final perms = capabilityToPermissions[capability] ?? [];
      if (perms.contains(permission)) {
        return true;
      }
    }
    return false;
  }

  /// Calculate justified permission count
  static int countJustifiedPermissions(
    List<String> permissions,
    List<String> appCapabilities,
  ) {
    return permissions
        .where((perm) => isPermissionJustified(perm, appCapabilities))
        .length;
  }

  /// Analyze app permissions against capabilities
  static Map<String, dynamic> analyzePermissions(
    List<String> permissions,
    List<String> appCapabilities,
  ) {
    final justified = permissions
        .where((p) => isPermissionJustified(p, appCapabilities))
        .toList();
    final unjustified = permissions
        .where((p) => !isPermissionJustified(p, appCapabilities))
        .toList();

    return {
      'justifiedPermissions': justified,
      'unjustifiedPermissions': unjustified,
      'justifiedCount': justified.length,
      'unjustifiedCount': unjustified.length,
      'justificationPercentage': permissions.isEmpty
          ? 0
          : (justified.length / permissions.length * 100).toStringAsFixed(1),
    };
  }
}
