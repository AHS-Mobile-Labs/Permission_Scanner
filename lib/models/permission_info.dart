class PermissionInfo {
  final String name;
  final String displayName;
  final String description;
  final String group;
  final bool isDangerous;
  final bool isDeveloperOnly;

  const PermissionInfo({
    required this.name,
    required this.displayName,
    required this.description,
    required this.group,
    required this.isDangerous,
    this.isDeveloperOnly = false,
  });
}
