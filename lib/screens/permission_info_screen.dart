import 'package:flutter/material.dart';
import 'package:permission_scanner/models/permission_info.dart';
import 'package:permission_scanner/utils/app_colors.dart';
import 'package:permission_scanner/utils/permission_database.dart';
import 'package:permission_scanner/widgets/permission_item.dart';

enum _PermissionFilter { all, dangerous, standard }

class PermissionInfoScreen extends StatefulWidget {
  const PermissionInfoScreen({super.key});

  @override
  State<PermissionInfoScreen> createState() => _PermissionInfoScreenState();
}

class _PermissionInfoScreenState extends State<PermissionInfoScreen> {
  final _searchController = TextEditingController();
  _PermissionFilter _filter = _PermissionFilter.all;
  bool _dangerousExpanded = true;
  bool _standardExpanded = true;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final permissions = permissionDatabase.values.toList()
      ..sort((a, b) {
        final groupCompare = a.group.compareTo(b.group);
        if (groupCompare != 0) return groupCompare;
        return a.displayName.compareTo(b.displayName);
      });
    final dangerousCount = permissions.where((p) => p.isDangerous).length;
    final standardCount = permissions.length - dangerousCount;
    final filteredPermissions = permissions.where(_matchesFilters).toList();
    final dangerousPerms = filteredPermissions
        .where((permission) => permission.isDangerous)
        .toList();
    final standardPerms = filteredPermissions
        .where((permission) => !permission.isDangerous)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Permission Library'),
        foregroundColor: AppColors.textDark,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.divider),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: _buildHeaderCard(
              totalCount: permissions.length,
              dangerousCount: dangerousCount,
              standardCount: standardCount,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSearchField(),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildFilterBar(),
          ),
          const SizedBox(height: 14),
          if (filteredPermissions.isEmpty)
            _buildEmptyState()
          else ...[
            if (dangerousPerms.isNotEmpty)
              _buildExpandableSection(
                title: 'Dangerous Permissions',
                count: dangerousPerms.length,
                color: AppColors.riskDangerous,
                containerColor: AppColors.riskDangerousContainer,
                icon: Icons.warning_rounded,
                expanded: _dangerousExpanded,
                onToggle: () =>
                    setState(() => _dangerousExpanded = !_dangerousExpanded),
                children: dangerousPerms,
              ),
            if (dangerousPerms.isNotEmpty && standardPerms.isNotEmpty)
              const SizedBox(height: 12),
            if (standardPerms.isNotEmpty)
              _buildExpandableSection(
                title: 'Standard Permissions',
                count: standardPerms.length,
                color: AppColors.riskSafe,
                containerColor: AppColors.riskSafeContainer,
                icon: Icons.verified_rounded,
                expanded: _standardExpanded,
                onToggle: () =>
                    setState(() => _standardExpanded = !_standardExpanded),
                children: standardPerms,
              ),
          ],
        ],
      ),
    );
  }

  bool _matchesFilters(PermissionInfo permission) {
    final matchesType = switch (_filter) {
      _PermissionFilter.all => true,
      _PermissionFilter.dangerous => permission.isDangerous,
      _PermissionFilter.standard => !permission.isDangerous,
    };
    if (!matchesType) return false;

    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;

    return permission.displayName.toLowerCase().contains(query) ||
        permission.description.toLowerCase().contains(query) ||
        permission.group.toLowerCase().contains(query) ||
        permission.name.toLowerCase().contains(query);
  }

  Widget _buildHeaderCard({
    required int totalCount,
    required int dangerousCount,
    required int standardCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Android Permission Reference',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Browse permissions by risk level and data access.',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  label: 'Total',
                  value: totalCount,
                  color: AppColors.primary,
                  backgroundColor: AppColors.primaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatTile(
                  label: 'Dangerous',
                  value: dangerousCount,
                  color: AppColors.riskDangerous,
                  backgroundColor: AppColors.riskDangerousContainer,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatTile(
                  label: 'Standard',
                  value: standardCount,
                  color: AppColors.riskSafe,
                  backgroundColor: AppColors.riskSafeContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required String label,
    required int value,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMedium,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _query = value),
      style: const TextStyle(color: AppColors.textDark, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.cardBackground,
        hintText: 'Search permission, group, or Android name',
        hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textLight,
          size: 20,
        ),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textLight,
                  size: 20,
                ),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
                tooltip: 'Clear',
              ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SegmentedButton<_PermissionFilter>(
      segments: const [
        ButtonSegment(value: _PermissionFilter.all, label: Text('All')),
        ButtonSegment(
          value: _PermissionFilter.dangerous,
          label: Text('Dangerous'),
        ),
        ButtonSegment(
          value: _PermissionFilter.standard,
          label: Text('Standard'),
        ),
      ],
      selected: {_filter},
      onSelectionChanged: (selection) =>
          setState(() => _filter = selection.first),
      showSelectedIcon: false,
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required int count,
    required Color color,
    required Color containerColor,
    required IconData icon,
    required bool expanded,
    required VoidCallback onToggle,
    required List<PermissionInfo> children,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Material(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onToggle,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: containerColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: containerColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: color,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              children: children
                  .map((permission) => PermissionItem(permission: permission))
                  .toList(),
            ),
          ),
          crossFadeState: expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
          sizeCurve: Curves.easeInOut,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              color: AppColors.textLight,
              size: 32,
            ),
            SizedBox(height: 10),
            Text(
              'No permissions found',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Try another search term or filter.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textLight, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
