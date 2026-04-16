// ═══════════════════════════════════════════════════════════════════
// ACTIVITIES_LIST_SCREEN.DART — List of user's activity templates
// Supports: show/hide archived, multi-select for mass archive/delete.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/kitab_theme.dart';
import '../../../data/models/activity.dart';
import '../../../data/models/category.dart' as domain;
import '../../../core/widgets/kitab_toast.dart';
import '../../home/providers/home_providers.dart';
import 'activity_detail_screen.dart';
import 'activity_form_screen.dart';

/// Provider: active activities only.
final _activeActivitiesProvider = StreamProvider<List<Activity>>((ref) {
  return ref.watch(activityRepositoryProvider).watchActiveByUser(ref.watch(currentUserIdProvider));
});

/// Provider: ALL activities including archived.
final _allActivitiesProvider = FutureProvider<List<Activity>>((ref) async {
  return ref.watch(activityRepositoryProvider).getByUser(ref.watch(currentUserIdProvider));
});

/// Provider for categories.
final _categoriesProvider = StreamProvider<List<domain.Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchByUser(ref.watch(currentUserIdProvider));
});

class ActivitiesListScreen extends ConsumerStatefulWidget {
  const ActivitiesListScreen({super.key});

  @override
  ConsumerState<ActivitiesListScreen> createState() => _ActivitiesListScreenState();
}

class _ActivitiesListScreenState extends ConsumerState<ActivitiesListScreen> {
  bool _showArchived = false;
  bool _selectMode = false;
  final Set<String> _selectedIds = {};

  void _refreshProviders() {
    ref.invalidate(_activeActivitiesProvider);
    ref.invalidate(_allActivitiesProvider);
    // Also refresh Home screen so deleted/archived activities disappear
    ref.invalidate(activeActivitiesProvider);
    ref.invalidate(scheduledTodayProvider);
    ref.invalidate(homeSummaryProvider);
  }

  void _toggleSelectMode() {
    setState(() {
      _selectMode = !_selectMode;
      if (!_selectMode) _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selectMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _massArchive(List<Activity> activities) async {
    final selected = activities.where((a) => _selectedIds.contains(a.id)).toList();
    final archiveCount = selected.where((a) => !a.isArchived).length;
    final unarchiveCount = selected.where((a) => a.isArchived).length;

    String action;
    if (archiveCount > 0 && unarchiveCount > 0) {
      action = 'Toggle archive for ${selected.length} activities?';
    } else if (archiveCount > 0) {
      action = 'Archive $archiveCount ${archiveCount == 1 ? 'activity' : 'activities'}?';
    } else {
      action = 'Unarchive $unarchiveCount ${unarchiveCount == 1 ? 'activity' : 'activities'}?';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(action),
        content: const Text(
          'Archived activities are hidden from the Home screen and quick log suggestions. '
          'Their history and entries are preserved. You can unarchive them anytime.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(activityRepositoryProvider);
      for (final activity in selected) {
        await repo.setArchived(activity.id, !activity.isArchived);
      }
      _refreshProviders();
      setState(() { _selectedIds.clear(); _selectMode = false; });
      if (mounted) {
        KitabToast.success(context, '${selected.length} ${selected.length == 1 ? 'activity' : 'activities'} updated');
      }
    }
  }

  Future<void> _massDelete() async {
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $count ${count == 1 ? 'activity' : 'activities'}?'),
        content: const Text(
          'This will permanently remove the selected activities. '
          'Historical entries will remain in the Book but won\'t be linked to a template anymore. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: KitabColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(activityRepositoryProvider);
      for (final id in _selectedIds) {
        await repo.delete(id);
      }
      _refreshProviders();
      setState(() { _selectedIds.clear(); _selectMode = false; });
      if (mounted) {
        KitabToast.success(context, '$count ${count == 1 ? 'activity' : 'activities'} deleted');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = _showArchived
        ? ref.watch(_allActivitiesProvider)
        : ref.watch(_activeActivitiesProvider);
    final categoriesAsync = ref.watch(_categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: _selectMode
            ? Text('${_selectedIds.length} selected', style: KitabTypography.h2)
            : Text('My Activities', style: KitabTypography.h2),
        leading: _selectMode
            ? IconButton(icon: const Icon(Icons.close), onPressed: _toggleSelectMode)
            : null,
        actions: [
          if (_selectMode) ...[
            // Archive/Unarchive selected
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              tooltip: 'Archive / Unarchive',
              onPressed: _selectedIds.isEmpty ? null : () {
                final activities = activitiesAsync.valueOrNull ?? [];
                _massArchive(activities);
              },
            ),
            // Delete selected
            IconButton(
              icon: const Icon(Icons.delete_outline, color: KitabColors.error),
              tooltip: 'Delete',
              onPressed: _selectedIds.isEmpty ? null : _massDelete,
            ),
          ] else ...[
            // Select mode toggle
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: 'Select activities',
              onPressed: _toggleSelectMode,
            ),
            // Show archived toggle
            IconButton(
              icon: Icon(
                _showArchived ? Icons.visibility : Icons.visibility_off,
                color: _showArchived ? KitabColors.primary : KitabColors.gray400,
              ),
              tooltip: _showArchived ? 'Hide archived' : 'Show archived',
              onPressed: () {
                setState(() => _showArchived = !_showArchived);
                if (_showArchived) ref.invalidate(_allActivitiesProvider);
              },
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ActivityFormScreen()));
                _refreshProviders();
              },
            ),
          ],
        ],
      ),
      body: activitiesAsync.when(
        data: (activities) {
          if (activities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📋', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: KitabSpacing.md),
                  Text('No activities yet', style: KitabTypography.h3),
                  const SizedBox(height: KitabSpacing.sm),
                  Text('Create your first activity to start tracking',
                      style: KitabTypography.body.copyWith(color: KitabColors.gray500)),
                  const SizedBox(height: KitabSpacing.lg),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ActivityFormScreen()));
                      _refreshProviders();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Activity'),
                  ),
                ],
              ),
            );
          }

          final sorted = [...activities]..sort((a, b) {
            if (a.isArchived != b.isArchived) return a.isArchived ? 1 : -1;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

          final categories = categoriesAsync.valueOrNull ?? [];
          final categoryMap = {for (final c in categories) c.id: c};

          return ListView.builder(
            padding: const EdgeInsets.all(KitabSpacing.lg),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final activity = sorted[index];
              final category = categoryMap[activity.categoryId];
              final isSelected = _selectedIds.contains(activity.id);

              return Opacity(
                opacity: activity.isArchived ? 0.5 : 1.0,
                child: Row(
                  children: [
                    if (_selectMode)
                      Checkbox(
                        value: isSelected,
                        onChanged: (_) => _toggleSelection(activity.id),
                        activeColor: KitabColors.primary,
                      ),
                    Expanded(
                      child: ListTile(
                        leading: Text(category?.icon ?? '📁', style: const TextStyle(fontSize: 24)),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                activity.isPrivate ? '••••••••' : activity.name,
                                style: KitabTypography.body,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (activity.isArchived) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: KitabColors.gray300,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('Archived', style: KitabTypography.caption.copyWith(fontSize: 9)),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          category?.name ?? 'Uncategorized',
                          style: KitabTypography.caption.copyWith(color: KitabColors.gray500),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (activity.isPrivate)
                              const Icon(Icons.lock, color: KitabColors.gray400, size: 18),
                            const Icon(Icons.chevron_right, color: KitabColors.gray400),
                          ],
                        ),
                        onTap: () {
                          if (_selectMode) {
                            _toggleSelection(activity.id);
                            return;
                          }
                          Navigator.push(context,
                            MaterialPageRoute(builder: (_) => ActivityDetailScreen(activity: activity)),
                          ).then((_) => _refreshProviders());
                        },
                        onLongPress: !_selectMode ? () {
                          setState(() => _selectMode = true);
                          _toggleSelection(activity.id);
                        } : null,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
