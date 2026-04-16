// ═══════════════════════════════════════════════════════════════════
// ACTIVITY_SEARCH_FIELD.DART — Searchable Activity Picker
// Used by all quick log forms and the expanded entry form.
// Shows suggestions ranked by: recency → frequency → alphabetical.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/kitab_theme.dart';
import '../../../data/models/activity.dart';
import '../../../data/models/category.dart' as domain;



class ActivitySearchField extends ConsumerStatefulWidget {
  final ValueChanged<Activity> onSelected;
  final Activity? initialActivity;

  const ActivitySearchField({
    super.key,
    required this.onSelected,
    this.initialActivity,
  });

  @override
  ConsumerState<ActivitySearchField> createState() =>
      _ActivitySearchFieldState();
}

class _ActivitySearchFieldState extends ConsumerState<ActivitySearchField> {
  late final TextEditingController _controller;
  List<Activity> _allActivities = [];
  List<Activity> _filtered = [];
  Map<String, domain.Category> _categories = {};
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialActivity?.name ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _loadActivities() async {
    final activities = await ref
        .read(activityRepositoryProvider)
        .getByUser(ref.read(currentUserIdProvider));
    final categories = await ref
        .read(categoryRepositoryProvider)
        .getByUser(ref.read(currentUserIdProvider));

    if (mounted) {
      setState(() {
        _allActivities =
            activities.where((a) => !a.isArchived).toList();
        _categories = {for (final c in categories) c.id: c};
        _filterActivities(_controller.text);
      });
    }
  }

  void _filterActivities(String query) {
    if (query.isEmpty) {
      _filtered = List.from(_allActivities);
    } else {
      _filtered = _allActivities
          .where((a) =>
              a.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'Activity',
            hintText: 'Search or pick an activity',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _filterActivities('');
                        _showSuggestions = true;
                      });
                    },
                  )
                : null,
          ),
          onTap: () {
            if (_allActivities.isEmpty) _loadActivities();
            setState(() => _showSuggestions = true);
          },
          onChanged: (query) {
            setState(() {
              _filterActivities(query);
              _showSuggestions = true;
            });
          },
        ),

        // Suggestions dropdown
        if (_showSuggestions && _filtered.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: KitabRadii.borderSm,
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final activity = _filtered[index];
                final category = _categories[activity.categoryId];

                return ListTile(
                  dense: true,
                  leading: Text(
                    category?.icon ?? '📁',
                    style: const TextStyle(fontSize: 18),
                  ),
                  title: Text(
                    activity.isPrivate ? '••••••••' : activity.name,
                    style: KitabTypography.body,
                  ),
                  subtitle: Text(
                    category?.name ?? '',
                    style: KitabTypography.caption
                        .copyWith(color: KitabColors.gray500),
                  ),
                  onTap: () {
                    _controller.text = activity.name;
                    setState(() => _showSuggestions = false);
                    widget.onSelected(activity);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
