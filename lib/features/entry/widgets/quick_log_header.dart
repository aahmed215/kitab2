// ═══════════════════════════════════════════════════════════════════
// QUICK_LOG_HEADER.DART — Shared header for all quick log sheets
// Shows: drag handle, activity search with inline suggestions,
// and category line when linked to a template.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/kitab_theme.dart';
import '../../../data/models/activity.dart';
import '../../../data/models/category.dart' as domain;

/// Shared header for quick log bottom sheets.
/// Provides activity search with inline suggestions and category display.
class QuickLogHeader extends ConsumerStatefulWidget {
  final String title;
  final Activity? initialActivity;
  final ValueChanged<Activity?> onActivityChanged;

  const QuickLogHeader({
    super.key,
    required this.title,
    this.initialActivity,
    required this.onActivityChanged,
  });

  @override
  ConsumerState<QuickLogHeader> createState() => QuickLogHeaderState();
}

class QuickLogHeaderState extends ConsumerState<QuickLogHeader> {
  late final TextEditingController _controller;
  List<Activity> _allActivities = [];
  List<Activity> _filtered = [];
  Map<String, domain.Category> _categories = {};
  bool _showSuggestions = false;
  Activity? _selectedActivity;
  domain.Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedActivity = widget.initialActivity;
    _controller = TextEditingController(text: widget.initialActivity?.name ?? '');
    _loadActivities();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    final userId = ref.read(currentUserIdProvider);
    final activities = await ref.read(activityRepositoryProvider).getByUser(userId);
    final categories = await ref.read(categoryRepositoryProvider).getByUser(userId);

    if (mounted) {
      setState(() {
        _allActivities = activities.where((a) => !a.isArchived).toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _categories = {for (final c in categories) c.id: c};
        if (_selectedActivity != null) {
          _selectedCategory = _categories[_selectedActivity!.categoryId];
        }
        _filterActivities(_controller.text);
      });
    }
  }

  void _filterActivities(String query) {
    if (query.isEmpty) {
      _filtered = List.from(_allActivities);
    } else {
      _filtered = _allActivities
          .where((a) => a.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  void _selectActivity(Activity activity) {
    _controller.text = activity.name;
    setState(() {
      _selectedActivity = activity;
      _selectedCategory = _categories[activity.categoryId];
      _showSuggestions = false;
    });
    widget.onActivityChanged(activity);
  }

  void _clearSelection() {
    setState(() {
      _selectedActivity = null;
      _selectedCategory = null;
    });
    widget.onActivityChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Drag handle
        Center(
          child: Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: KitabSpacing.lg),
            decoration: BoxDecoration(
              color: KitabColors.gray300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Title
        Text(widget.title, style: KitabTypography.h2),
        const SizedBox(height: KitabSpacing.md),

        // Activity search
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'Activity',
            hintText: 'Search or type a name...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _controller.clear();
                      _clearSelection();
                      setState(() {
                        _filterActivities('');
                        _showSuggestions = true;
                      });
                    },
                  )
                : null,
          ),
          onTap: () {
            setState(() => _showSuggestions = true);
          },
          onChanged: (query) {
            _clearSelection();
            setState(() {
              _filterActivities(query);
              _showSuggestions = query.isNotEmpty || _filtered.isNotEmpty;
            });
          },
        ),

        // Inline suggestions
        if (_showSuggestions && _filtered.isNotEmpty && _selectedActivity == null)
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
              borderRadius: KitabRadii.borderSm,
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final activity = _filtered[index];
                final category = _categories[activity.categoryId];
                return ListTile(
                  dense: true,
                  leading: Text(category?.icon ?? '📁', style: const TextStyle(fontSize: 18)),
                  title: Text(activity.name, style: KitabTypography.body),
                  subtitle: category != null
                      ? Text(category.name, style: KitabTypography.caption.copyWith(color: KitabColors.gray500))
                      : null,
                  onTap: () => _selectActivity(activity),
                );
              },
            ),
          ),

        // Category line (only when linked to a template)
        if (_selectedActivity != null && _selectedCategory != null) ...[
          const SizedBox(height: KitabSpacing.sm),
          Row(
            children: [
              Text(_selectedCategory!.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                _selectedCategory!.name,
                style: KitabTypography.bodySmall.copyWith(color: KitabColors.gray500),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// The currently entered activity name (for ad-hoc entries).
  String get activityName => _controller.text.trim();
}
