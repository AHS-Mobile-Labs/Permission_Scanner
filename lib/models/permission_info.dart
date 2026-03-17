class PermissionInfo {
  final String name;
  final String displayName;
  final String description;
  final String group;
  final bool isDangerous;

  const PermissionInfo({
    required this.name,
    required this.displayName,
    required this.description,
    required this.group,
    required this.isDangerous,
  });
}
