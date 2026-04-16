// ═══════════════════════════════════════════════════════════════════
// ROUTINE_FORM_SCREEN.DART — Create/Edit Routine Template
// A routine chains activities together for habit stacking.
// No category — routines span multiple categories.
// See SPEC.md §6 for full specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/kitab_theme.dart';
import '../../../data/models/activity.dart';
import '../../../data/models/routine.dart';
import '../../../core/widgets/kitab_toast.dart';
import '../activities/widgets/goal_config_section.dart';
import '../activities/widgets/schedule_config_section.dart';

const _uuid = Uuid();

class RoutineFormScreen extends ConsumerStatefulWidget {
  final Routine? existingRoutine;
  const RoutineFormScreen({super.key, this.existingRoutine});

  @override
  ConsumerState<RoutineFormScreen> createState() => _RoutineFormScreenState();
}

class _RoutineFormScreenState extends ConsumerState<RoutineFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  bool _isPrivate = false;

  // Activity sequence
  List<_SequenceItem> _sequence = [];
  List<Activity> _allActivities = [];

  // Schedule
  bool _hasSchedule = false;
  late ScheduleState _schedule;

  // Goals
  bool _hasGoals = false;
  List<GoalConfig> _goals = [];

  bool _hasChanges = false;
  bool _saving = false;
  bool get _isEditing => widget.existingRoutine != null;

  void _changed([VoidCallback? fn]) {
    setState(() {
      _hasChanges = true;
      fn?.call();
    });
  }

  @override
  void initState() {
    super.initState();
    final r = widget.existingRoutine;
    _nameController = TextEditingController(text: r?.name ?? '');
    _descriptionController = TextEditingController(text: r?.description ?? '');
    _isPrivate = r?.isPrivate ?? false;

    // Parse schedule
    _hasSchedule = r?.schedule != null;
    if (r?.schedule != null) {
      final versions = r!.schedule!['versions'] as List<dynamic>?;
      if (versions != null && versions.isNotEmpty) {
        final config = (versions.last as Map<String, dynamic>)['config'] as Map<String, dynamic>?;
        _schedule = config != null ? ScheduleState.fromJson(config) : ScheduleState();
      } else {
        _schedule = ScheduleState();
      }
    } else {
      _schedule = ScheduleState();
    }

    // Parse goals
    if (r?.goals != null) {
      _hasGoals = true;
      final versions = r!.goals!['versions'] as List<dynamic>?;
      if (versions != null && versions.isNotEmpty) {
        final goalsList = (versions.last as Map<String, dynamic>)['goals'] as List<dynamic>?;
        if (goalsList != null) {
          _goals = goalsList.map((g) => GoalConfig.fromJson(Map<String, dynamic>.from(g))).toList();
        }
      }
    }

    // Parse activity sequence
    if (r != null) {
      _sequence = r.activitySequence.map((seq) => _SequenceItem(
        activityId: seq['activity_id'] as String? ?? '',
      )).toList();
    }

    _loadActivities();
  }

  Future<void> _loadActivities() async {
    final userId = ref.read(currentUserIdProvider);
    final activities = await ref.read(activityRepositoryProvider).getByUser(userId);
    setState(() {
      _allActivities = activities.where((a) => !a.isArchived).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    });

    // Resolve names for existing sequence items
    for (final item in _sequence) {
      final activity = _allActivities.where((a) => a.id == item.activityId).firstOrNull;
      if (activity != null) {
        setState(() => item.activity = activity);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Routine' : 'Create Routine', style: KitabTypography.h2),
          actions: [
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEditing ? 'Save' : 'Create'),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.all(KitabSpacing.lg),
              children: [
                // ═══ IDENTITY ═══
                Text('Details', style: KitabTypography.h3),
                const SizedBox(height: KitabSpacing.md),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Routine Name *',
                    hintText: 'e.g., Morning Routine, Evening Wind Down',
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofocus: !_isEditing,
                  onChanged: (_) => _changed(),
                ),
                const SizedBox(height: KitabSpacing.md),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Optional — what is this routine for?',
                  ),
                  maxLines: 2,
                  onChanged: (_) => _changed(),
                ),
                const SizedBox(height: KitabSpacing.md),
                SwitchListTile(
                  title: const Text('Private'),
                  subtitle: const Text('Hide name and details from others'),
                  value: _isPrivate,
                  onChanged: (v) => _changed(() => _isPrivate = v),
                  contentPadding: EdgeInsets.zero,
                ),

                const Divider(height: KitabSpacing.xl),

                // ═══ ACTIVITY SEQUENCE ═══
                Text('Activity Sequence', style: KitabTypography.h3),
                const SizedBox(height: KitabSpacing.xs),
                Text(
                  'Add activities in the order you want to do them. Minimum 2.',
                  style: KitabTypography.caption.copyWith(color: KitabColors.gray500),
                ),
                const SizedBox(height: KitabSpacing.md),
                _buildSequenceList(),
                const SizedBox(height: KitabSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _allActivities.isEmpty ? null : _addActivity,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Activity'),
                ),
                if (_allActivities.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: KitabSpacing.xs),
                    child: Text(
                      'Create some activities first before building a routine.',
                      style: KitabTypography.caption.copyWith(color: KitabColors.warning),
                    ),
                  ),

                const Divider(height: KitabSpacing.xl),

                // ═══ SCHEDULE ═══
                SwitchListTile(
                  title: Text('Schedule', style: KitabTypography.h3),
                  subtitle: const Text('Set a recurring schedule for this routine'),
                  value: _hasSchedule,
                  onChanged: (v) => _changed(() {
                    _hasSchedule = v;
                    if (!v) {
                      // No schedule → no goals
                      _hasGoals = false;
                      _goals.clear();
                    }
                  }),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_hasSchedule) ...[
                  const SizedBox(height: KitabSpacing.md),
                  ScheduleConfigSection(
                    state: _schedule,
                    hijriEnabled: true,
                    onChanged: () => _changed(),
                    fmt: ref.watch(dateFormatterProvider),
                  ),
                ],

                // ═══ GOALS (only when scheduled) ═══
                if (_hasSchedule) ...[
                  const Divider(height: KitabSpacing.xl),
                  SwitchListTile(
                    title: Text('Goals', style: KitabTypography.h3),
                    subtitle: const Text('Track routine completion targets'),
                    value: _hasGoals,
                    onChanged: (v) => _changed(() {
                      _hasGoals = v;
                      if (v && _goals.isEmpty) {
                        // Default: complete all activities per period
                        _goals.add(GoalConfig(
                          isPrimary: true,
                          goalType: 'completion',
                          completionComparison: '=',
                          completionCount: _sequence.length,
                        ));
                      }
                    }),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_hasGoals) ...[
                    const SizedBox(height: KitabSpacing.md),
                    _buildRoutineGoal(),
                  ],
                ],

                const Divider(height: KitabSpacing.xl),

                // ═══ SUMMARY ═══
                Text('Summary', style: KitabTypography.h3),
                const SizedBox(height: KitabSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(KitabSpacing.md),
                  decoration: BoxDecoration(
                    color: KitabColors.gray100.withValues(alpha: 0.5),
                    borderRadius: KitabRadii.borderMd,
                  ),
                  child: Text(_summary, style: KitabTypography.body.copyWith(color: KitabColors.gray600)),
                ),

                const SizedBox(height: KitabSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Activity Sequence List ───
  Widget _buildSequenceList() {
    if (_sequence.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(KitabSpacing.lg),
        decoration: BoxDecoration(
          border: Border.all(color: KitabColors.gray200),
          borderRadius: KitabRadii.borderMd,
        ),
        child: Center(
          child: Text(
            'No activities added yet',
            style: KitabTypography.body.copyWith(color: KitabColors.gray400),
          ),
        ),
      );
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _sequence.length,
      onReorder: (oldIndex, newIndex) {
        _changed(() {
          if (newIndex > oldIndex) newIndex--;
          final item = _sequence.removeAt(oldIndex);
          _sequence.insert(newIndex, item);
        });
      },
      itemBuilder: (context, index) {
        final item = _sequence[index];
        final name = item.activity?.name ?? 'Unknown Activity';

        return Card(
          key: ValueKey('${item.activityId}_$index'),
          margin: const EdgeInsets.only(bottom: KitabSpacing.xs),
          child: ListTile(
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: KitabColors.primary.withValues(alpha: 0.1),
              child: Text('${index + 1}', style: KitabTypography.caption.copyWith(
                color: KitabColors.primary, fontWeight: FontWeight.w600,
              )),
            ),
            title: Text(name, style: KitabTypography.body),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: KitabColors.error),
                  onPressed: () => _changed(() => _sequence.removeAt(index)),
                ),
                const Icon(Icons.drag_handle, size: 18, color: KitabColors.gray300),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Add Activity Picker ───
  void _addActivity() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(KitabSpacing.md),
                child: Text('Add Activity', style: KitabTypography.h3),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _allActivities.length,
                  itemBuilder: (_, index) {
                    final activity = _allActivities[index];

                    // Check if duplicate is allowed
                    final alreadyInSequence = _sequence.any((s) => s.activityId == activity.id);
                    final allowsDuplicate = _activityAllowsMultiple(activity);
                    final isDisabled = alreadyInSequence && !allowsDuplicate;

                    return ListTile(
                      title: Text(activity.name),
                      subtitle: isDisabled
                          ? Text('Already added (single entry per period)',
                              style: KitabTypography.caption.copyWith(color: KitabColors.gray400))
                          : alreadyInSequence
                              ? Text('Already added — can add again (multiple entries allowed)',
                                  style: KitabTypography.caption.copyWith(color: KitabColors.primary))
                              : null,
                      enabled: !isDisabled,
                      trailing: isDisabled
                          ? const Icon(Icons.block, color: KitabColors.gray300, size: 18)
                          : const Icon(Icons.add_circle_outline, color: KitabColors.primary, size: 20),
                      onTap: isDisabled ? null : () {
                        _changed(() {
                          _sequence.add(_SequenceItem(
                            activityId: activity.id,
                            activity: activity,
                          ));
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Check if an activity allows multiple entries per period.
  bool _activityAllowsMultiple(Activity activity) {
    if (activity.schedule == null) return true; // No schedule = log whenever
    final versions = activity.schedule!['versions'] as List<dynamic>?;
    if (versions == null || versions.isEmpty) return true;
    final config = (versions.last as Map<String, dynamic>)['config'] as Map<String, dynamic>?;
    if (config == null) return true;
    return (config['expected_entries'] as String? ?? 'once') == 'multiple';
  }

  // ─── Routine-specific Goal UI ───
  Widget _buildRoutineGoal() {
    // Ensure we have at least one goal
    if (_goals.isEmpty) {
      _goals.add(GoalConfig(
        isPrimary: true,
        goalType: 'completion',
        completionComparison: '=',
        completionCount: _sequence.length,
      ));
    }
    final goal = _goals.first;
    final periodLabel = switch (_schedule.frequency) {
      'daily' => 'day',
      'weekly' => 'week',
      'monthly' => 'month',
      'yearly' => 'year',
      _ => 'period',
    };

    return Container(
      padding: const EdgeInsets.all(KitabSpacing.md),
      decoration: BoxDecoration(
        color: KitabColors.gray100.withValues(alpha: 0.5),
        borderRadius: KitabRadii.borderMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Complete activities per $periodLabel:', style: KitabTypography.body),
          const SizedBox(height: KitabSpacing.sm),

          // Option 1: Complete all
          RadioListTile<bool>(
            title: Text('All ${_sequence.length} activities'),
            value: true,
            groupValue: goal.completionComparison == '=' && goal.completionCount == _sequence.length,
            onChanged: (_) => _changed(() {
              goal.completionComparison = '=';
              goal.completionCount = _sequence.length;
            }),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),

          // Option 2: At least X
          RadioListTile<bool>(
            title: const Text('At least...'),
            value: true,
            groupValue: goal.completionComparison == '>=' ||
                (goal.completionComparison == '=' && goal.completionCount != _sequence.length),
            onChanged: (_) => _changed(() {
              goal.completionComparison = '>=';
              if (goal.completionCount >= _sequence.length) {
                goal.completionCount = (_sequence.length * 0.75).ceil().clamp(1, _sequence.length - 1);
              }
            }),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),

          // Count input (only when "at least" is selected)
          if (goal.completionComparison == '>=') ...[
            const SizedBox(height: KitabSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: KitabSpacing.xl),
              child: Row(
                children: [
                  SizedBox(width: 70, child: TextFormField(
                    initialValue: '${goal.completionCount}',
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'Count',
                      suffixText: '/ ${_sequence.length}',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _changed(() {
                      goal.completionCount = (int.tryParse(v) ?? 1).clamp(1, _sequence.length);
                    }),
                  )),
                  const SizedBox(width: KitabSpacing.sm),
                  Text('activities per $periodLabel',
                      style: KitabTypography.body.copyWith(color: KitabColors.gray500)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Summary ───
  String get _summary {
    final name = _nameController.text.trim().isEmpty ? 'This routine' : _nameController.text.trim();
    final buf = StringBuffer(name);

    if (_sequence.isEmpty) {
      buf.write(' has no activities yet.');
    } else {
      final names = _sequence
          .map((s) => s.activity?.name ?? 'activity')
          .join(' → ');
      buf.write(' chains ${_sequence.length} activities: $names.');
    }

    if (_hasSchedule) {
      buf.write(' Repeats ${_schedule.frequency}');
      if (_schedule.calendar == 'hijri') buf.write(' (Hijri calendar)');
      buf.write('.');
    }

    if (!_hasSchedule && _sequence.isNotEmpty) {
      buf.write(' Run as a checklist anytime.');
    }

    if (_hasGoals && _goals.isNotEmpty) {
      final g = _goals.first;
      final per = _schedule.frequency == 'daily' ? 'day' : _schedule.frequency;
      if (g.completionComparison == '=' && g.completionCount == _sequence.length) {
        buf.write(' Goal: complete all ${_sequence.length} activities per $per.');
      } else {
        buf.write(' Goal: complete ${_compLabel(g.completionComparison)} ${g.completionCount} of ${_sequence.length} activities per $per.');
      }
    }

    return buf.toString();
  }

  String _compLabel(String comp) {
    return switch (comp) {
      '>=' => 'at least',
      '<=' => 'at most',
      '=' => 'exactly',
      '>' => 'more than',
      '<' => 'less than',
      _ => comp,
    };
  }

  // ─── Save ───
  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      KitabToast.error(context, 'Routine name is required');
      return;
    }
    if (_sequence.length < 2) {
      KitabToast.error(context, 'Add at least 2 activities');
      return;
    }

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final existing = widget.existingRoutine;

      Map<String, dynamic>? scheduleJson;
      if (_hasSchedule) {
        scheduleJson = {
          'versions': [{
            'effective_from': _schedule.startDate.toIso8601String(),
            'effective_to': null,
            'config': _schedule.toJson(),
          }],
        };
      }

      Map<String, dynamic>? goalsJson;
      if (_hasGoals && _goals.isNotEmpty) {
        if (!_goals.any((g) => g.isPrimary)) _goals.first.isPrimary = true;
        goalsJson = {
          'versions': [{
            'effective_from': now.toIso8601String(),
            'effective_to': null,
            'goals': _goals.map((g) => g.toJson()).toList(),
          }],
        };
      }

      final activitySequence = _sequence.asMap().entries.map((e) => {
        'activity_id': e.value.activityId,
        'sort_order': e.key,
      }).toList();

      final routine = Routine(
        id: existing?.id ?? _uuid.v4(),
        userId: ref.read(currentUserIdProvider),
        name: name,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        isArchived: existing?.isArchived ?? false,
        isPrivate: _isPrivate,
        activitySequence: activitySequence,
        schedule: scheduleJson,
        goals: goalsJson,
        primaryGoalId: _goals.where((g) => g.isPrimary).map((g) => g.id).firstOrNull,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );

      await ref.read(routineRepositoryProvider).save(routine);
      _hasChanges = false;
      if (mounted) {
        Navigator.pop(context);
        KitabToast.success(context, _isEditing ? 'Routine updated' : 'Routine created');
      }
    } catch (e) {
      if (mounted) KitabToast.error(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─── Discard confirmation ───
  void _confirmDiscard() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes that will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep Editing')),
          FilledButton(
            onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }
}

/// Tracks an activity in the sequence.
class _SequenceItem {
  final String activityId;
  Activity? activity;

  _SequenceItem({required this.activityId, this.activity});
}
