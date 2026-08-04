import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/models.dart';
import '../../core/app_state.dart';
import '../../shared/theme/hermes_theme.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final skills = state.skills;

    // Filter by search and category
    var filtered = skills;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((s) =>
              s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (s.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
          .toList();
    }
    if (_selectedCategory != null) {
      filtered = filtered.where((s) => s.category == _selectedCategory).toList();
    }

    // Group by category
    final grouped = <String, List<SkillInfo>>{};
    for (final skill in filtered) {
      final cat = skill.category ?? 'Uncategorized';
      grouped.putIfAbsent(cat, () => []).add(skill);
    }
    final categories = grouped.keys.toList()..sort();

    // All distinct categories for filter
    final allCategories = <String>{};
    for (final s in skills) {
      if (s.category != null) allCategories.add(s.category!);
    }
    final sortedCategories = allCategories.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skills'),
        actions: [
          if (skills.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list_rounded),
              tooltip: 'Filter by category',
              onSelected: (cat) {
                setState(() {
                  _selectedCategory = _selectedCategory == cat ? null : cat;
                });
              },
              itemBuilder: (_) => [
                if (_selectedCategory != null)
                  const PopupMenuItem(
                    value: '',
                    child: Text('Clear filter'),
                  ),
                ...sortedCategories.map((cat) => PopupMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          if (_selectedCategory == cat)
                            const Icon(Icons.check, size: 18, color: HermesTheme.primary),
                          if (_selectedCategory == cat) const SizedBox(width: 8),
                          Text(cat),
                        ],
                      ),
                    )),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (q) => setState(() => _searchQuery = q),
              style: const TextStyle(color: HermesTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search skills...',
                hintStyle: const TextStyle(color: HermesTheme.textMuted),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: HermesTheme.textMuted, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: HermesTheme.textMuted, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: HermesTheme.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          // Category filter chips
          if (_selectedCategory != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  Chip(
                    label: Text(_selectedCategory!),
                    backgroundColor: HermesTheme.primary.withValues(alpha: 0.15),
                    labelStyle: const TextStyle(
                      color: HermesTheme.primary,
                      fontSize: 12,
                    ),
                    deleteIcon: const Icon(Icons.close_rounded,
                        size: 16, color: HermesTheme.primary),
                    onDeleted: () => setState(() => _selectedCategory = null),
                    side: const BorderSide(color: HermesTheme.primary, width: 0.5),
                  ),
                  const Spacer(),
                  Text(
                    '${filtered.length} skill${filtered.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: HermesTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          // Skills list
          Expanded(
            child: skills.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 48, color: HermesTheme.textMuted),
                        SizedBox(height: 12),
                        Text(
                          'No skills loaded',
                          style: TextStyle(
                            color: HermesTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 80),
                    children: categories.map((category) {
                      final catSkills = grouped[category]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                            child: Row(
                              children: [
                                Text(
                                  category,
                                  style: const TextStyle(
                                    color: HermesTheme.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${catSkills.length}',
                                  style: const TextStyle(
                                    color: HermesTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...catSkills.map((skill) => _SkillTile(skill: skill)),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SkillTile extends StatelessWidget {
  final SkillInfo skill;

  const _SkillTile({required this.skill});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: HermesTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: HermesTheme.border, width: 0.5),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        shape: const Border(),
        leading: Icon(
          skill.enabled ? Icons.auto_awesome_rounded : Icons.auto_awesome_outlined,
          color: skill.enabled ? HermesTheme.primary : HermesTheme.textMuted,
          size: 20,
        ),
        title: Text(
          skill.name,
          style: const TextStyle(
            color: HermesTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: skill.description != null && skill.description!.isNotEmpty
            ? Text(
                skill.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: HermesTheme.textMuted,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: skill.enabled
                ? HermesTheme.success.withValues(alpha: 0.15)
                : HermesTheme.textMuted.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            skill.enabled ? 'ON' : 'OFF',
            style: TextStyle(
              color: skill.enabled ? HermesTheme.success : HermesTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        children: [
          if (skill.description != null && skill.description!.isNotEmpty)
            Text(
              skill.description!,
              style: const TextStyle(
                color: HermesTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (skill.category != null)
                _Tag(label: skill.category!),
              const SizedBox(width: 6),
              _Tag(
                label: skill.enabled ? 'Enabled' : 'Disabled',
                color: skill.enabled ? HermesTheme.success : HermesTheme.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color? color;

  const _Tag({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? HermesTheme.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}