// ═══════════════════════════════════════════════════════════════════
// ACTIVITY_FORM_SCREEN.DART — Create/Edit Activity Template
// Full form: Identity, Schedule, Fields, Goals, Summary, Privacy.
// See SPEC.md §5 for full specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/engines/schedule_migration_engine.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/prayer_time_service.dart';
import '../../../core/theme/kitab_theme.dart';
import '../../../core/utils/provider_refresh.dart';
import '../../../core/widgets/kitab_toast.dart';
import '../../../data/models/activity.dart';
import '../../../data/models/category.dart' as domain;
import 'widgets/field_config_section.dart';
import 'widgets/goal_config_section.dart';
import 'widgets/schedule_config_section.dart';

const _uuid = Uuid();

final _categoriesProvider = StreamProvider<List<domain.Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchByUser(ref.watch(currentUserIdProvider));
});

class ActivityFormScreen extends ConsumerStatefulWidget {
  final Activity? existingActivity;
  const ActivityFormScreen({super.key, this.existingActivity});

  @override
  ConsumerState<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends ConsumerState<ActivityFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  String? _selectedCategoryId;
  bool _isPrivate = false;

  bool _hasSchedule = false;
  late ScheduleState _schedule;

  List<FieldConfig> _fields = [];

  bool _hasGoals = false;

  // Track unsaved changes
  bool _hasChanges = false;

  /// Call this instead of raw setState to also mark changes.
  void _changed([VoidCallback? fn]) {
    setState(() {
      _hasChanges = true;
      fn?.call();
    });
  }
  List<GoalConfig> _goals = [];

  bool _saving = false;
  bool get _isEditing => widget.existingActivity != null;

  @override
  void initState() {
    super.initState();
    final a = widget.existingActivity;
    _nameController = TextEditingController(text: a?.name ?? '');
    _descriptionController = TextEditingController(text: a?.description ?? '');
    _selectedCategoryId = a?.categoryId;
    _isPrivate = a?.isPrivate ?? false;
    _hasSchedule = a?.schedule != null;

    if (a?.schedule != null) {
      final versions = a!.schedule!['versions'] as List<dynamic>?;
      if (versions != null && versions.isNotEmpty) {
        final config = (versions.last as Map<String, dynamic>)['config'] as Map<String, dynamic>?;
        _schedule = config != null ? ScheduleState.fromJson(config) : ScheduleState();
      } else {
        _schedule = ScheduleState();
      }
    } else {
      _schedule = ScheduleState();
    }

    if (a?.fields != null) {
      _fields = a!.fields.map((f) => FieldConfig.fromJson(Map<String, dynamic>.from(f))).toList();
    }

    if (a?.goals != null) {
      _hasGoals = true;
      final versions = a!.goals!['versions'] as List<dynamic>?;
      if (versions != null && versions.isNotEmpty) {
        final goalsList = (versions.last as Map<String, dynamic>)['goals'] as List<dynamic>?;
        if (goalsList != null) {
          _goals = goalsList.map((g) => GoalConfig.fromJson(Map<String, dynamic>.from(g))).toList();
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String get _summary {
    final name = _nameController.text.trim().isEmpty ? 'This activity' : _nameController.text.trim();
    final buf = StringBuffer(name);

    if (_hasSchedule) {
      buf.write(' is a ${_schedule.frequency} activity');
      if (_schedule.calendar == 'hijri') buf.write(' (Hijri calendar)');
    } else {
      buf.write(' has no schedule — log whenever');
    }

    if (_fields.isNotEmpty) {
      buf.write('. Each entry captures ${_fields.map((f) => f.label.toLowerCase()).join(', ')}');
    }

    if (_hasGoals && _goals.isNotEmpty) {
      final per = _hasSchedule ? ' per ${_schedule.frequency == 'daily' ? 'day' : _schedule.frequency}' : '';
      for (final g in _goals) {
        buf.write('. ');
        final label = g.name.isNotEmpty ? '${g.name}: ' : (g.isPrimary && _goals.length > 1 ? 'Primary goal: ' : 'Goal: ');
        buf.write(label);

        switch (g.goalType) {
          case 'completion':
            buf.write('Do this ${_compLabel(g.completionComparison)} ${g.completionCount} times$per');
          case 'target':
            if (g.condition.fieldLabel != null) {
              buf.write('${g.condition.fieldLabel} ${_compLabel(g.condition.comparison)} ');
              if (g.condition.useCalculatedTarget) {
                buf.write('${g.condition.calcTargetAggregation} of ${g.condition.calcTargetScope.replaceAll('_', ' ')}');
              } else {
                buf.write('${g.condition.targetText ?? g.condition.targetValue ?? '?'}');
              }
            }
          case 'combined':
            buf.write('${g.conditions.length} conditions (${g.combineLogic == 'all' ? 'all must be met' : 'any one met'})');
        }

        if (g.hasSuccessRate) {
          buf.write(' — success rate: ${g.successRateValue}${g.successRateType == 'percentage' ? '%' : ' entries'}');
        }
      }

      if (_hasSchedule) {
        buf.write('. Your streak counts consecutive ${_schedule.frequency == 'daily' ? 'day' : _schedule.frequency}s where ${_goals.length > 1 ? 'goals are' : 'this goal is'} met');
      }
    }

    buf.write('.');
    return buf.toString();
  }

  String _compLabel(String c) => switch (c) {
    '>=' => 'at least', '<=' => 'at most', '>' => 'more than',
    '<' => 'less than', '=' => 'exactly', 'between' => 'between',
    'not_between' => 'not between', 'contains' => 'contains',
    'not_contains' => 'does not contain',
    'at_location' => 'at', 'not_at_location' => 'not at',
    _ => c,
  };

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(_categoriesProvider);
    final settings = ref.watch(userSettingsProvider);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _hasChanges) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Discard changes?'),
              content: const Text('You have unsaved changes that will be lost.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep Editing')),
                FilledButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('Discard')),
              ],
            ),
          );
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Activity' : 'New Activity', style: KitabTypography.h2),
        actions: [
          if (_isEditing)
            PopupMenuButton(
              itemBuilder: (_) => [
                PopupMenuItem(value: 'archive', child: Text(widget.existingActivity!.isArchived ? 'Unarchive' : 'Archive')),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: KitabColors.error))),
              ],
              onSelected: (v) async {
                if (v == 'archive') {
                  await ref.read(activityRepositoryProvider).setArchived(widget.existingActivity!.id, !widget.existingActivity!.isArchived);
                  _hasChanges = false;
                  if (mounted) {
                    KitabToast.success(context, widget.existingActivity!.isArchived ? 'Activity unarchived' : 'Activity archived');
                    Navigator.pop(context);
                  }
                } else if (v == 'delete') { _confirmDelete(); }
              },
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
                decoration: const InputDecoration(labelText: 'Activity Name *', hintText: 'e.g., Morning Run, Read Quran'),
                textCapitalization: TextCapitalization.words,
                autofocus: !_isEditing,
                onChanged: (_) => _changed(), // Refresh summary
              ),
              const SizedBox(height: KitabSpacing.md),
              categoriesAsync.when(
                data: (categories) {
                  if (_selectedCategoryId == null && categories.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _selectedCategoryId = categories.first.id);
                    });
                  }
                  return DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Category *'),
                    items: [
                      // "+ New Category" at the top
                      DropdownMenuItem(
                        value: '__new__',
                        child: Row(children: [
                          Icon(Icons.add_circle_outline, size: 18, color: KitabColors.primary),
                          const SizedBox(width: 8),
                          Text('New Category', style: TextStyle(color: KitabColors.primary)),
                        ]),
                      ),
                      ...categories.map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Row(children: [Text(c.icon, style: const TextStyle(fontSize: 18)), const SizedBox(width: 8), Text(c.name)]),
                      )),
                    ],
                    onChanged: (id) {
                      if (id == '__new__') {
                        _showNewCategoryDialog(context, categories);
                      } else {
                        setState(() => _selectedCategoryId = id);
                      }
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, st) => Text('Error: $e'),
              ),
              const SizedBox(height: KitabSpacing.md),
              TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description (optional)'), maxLines: 2),
              const SizedBox(height: KitabSpacing.md),
              SwitchListTile(title: const Text('Private Activity'), subtitle: const Text('Blur name throughout the app'),
                value: _isPrivate, onChanged: (v) => _changed(() => _isPrivate = v), contentPadding: EdgeInsets.zero),

              const Divider(height: KitabSpacing.xxl),

              // ═══ SCHEDULE ═══
              SwitchListTile(title: Text('Schedule', style: KitabTypography.h3), subtitle: const Text('Set when this activity should happen'),
                value: _hasSchedule, onChanged: (v) => _changed(() {
                  _hasSchedule = v;
                  if (v && !_hasGoals) {
                    // Auto-create Completion Goal when schedule is turned on
                    _hasGoals = true;
                    _goals.add(GoalConfig(
                      name: 'Completion Goal',
                      goalType: 'completion',
                      completionComparison: '=',
                      completionCount: 1,
                      isPrimary: true,
                      isAutoCreated: true,
                    ));
                  }
                  if (!v) {
                    // Remove auto-created Completion Goal if it hasn't been modified
                    final autoCreated = _goals.where((g) => g.isAutoCreated && g.goalType == 'completion').toList();
                    for (final g in autoCreated) {
                      if (g.name == 'Completion Goal' && g.completionCount == 1 && g.completionComparison == '=') {
                        _goals.remove(g);
                      }
                    }
                    // Remove Completion type from remaining goals
                    for (final g in _goals) {
                      if (g.goalType == 'completion') g.goalType = 'target';
                    }
                    if (_goals.isEmpty) _hasGoals = false;
                  }
                }), contentPadding: EdgeInsets.zero),
              if (_hasSchedule) ...[
                const SizedBox(height: KitabSpacing.md),
                ScheduleConfigSection(
                  state: _schedule,
                  hijriEnabled: settings.islamicPersonalization,
                  onChanged: () => _changed(),
                  todayPrayerTimes: _getTodayPrayerTimes(ref),
                  fmt: ref.watch(dateFormatterProvider),
                ),
              ],

              const Divider(height: KitabSpacing.xxl),

              // ═══ FIELDS ═══
              FieldConfigSection(fields: _fields, onChanged: (f) => _changed(() => _fields = f)),

              const Divider(height: KitabSpacing.xxl),

              // ═══ GOALS ═══
              SwitchListTile(title: Text('Goals', style: KitabTypography.h3), subtitle: const Text('Set targets to achieve'),
                value: _hasGoals, onChanged: (v) { _changed(() {
                  _hasGoals = v;
                  // No auto-creation here — only schedule toggle auto-creates
                }); },
                contentPadding: EdgeInsets.zero),
              if (_hasGoals) ...[
                const SizedBox(height: KitabSpacing.md),
                GoalConfigSection(
                  goals: _goals, fields: _fields,
                  hasSchedule: _hasSchedule, frequency: _schedule.frequency,
                  hasTimeWindow: _schedule.hasTimeWindow,
                  windowStart: _schedule.windowStart,
                  windowEnd: _schedule.windowEnd,
                  onChanged: (g) => _changed(() => _goals = g),
                ),
              ],

              const Divider(height: KitabSpacing.xxl),

              // ═══ SUMMARY ═══
              Text('Summary', style: KitabTypography.h3),
              const SizedBox(height: KitabSpacing.sm),
              Container(
                padding: const EdgeInsets.all(KitabSpacing.md),
                decoration: BoxDecoration(
                  color: KitabColors.primary.withValues(alpha: 0.05),
                  borderRadius: KitabRadii.borderMd,
                  border: Border.all(color: KitabColors.primary.withValues(alpha: 0.15)),
                ),
                child: Text(_summary, style: KitabTypography.body.copyWith(fontStyle: FontStyle.italic)),
              ),

              const SizedBox(height: KitabSpacing.xxl),

              // ═══ SAVE ═══
              SizedBox(width: double.infinity, child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEditing ? 'Save Changes' : 'Create Activity'),
              )),
              const SizedBox(height: KitabSpacing.xl),
            ],
          ),
        ),
      ),
    ),
    );
  }

  /// Show inline new category dialog. Uses same emoji+color picker pattern.
  /// Get today's prayer times from the provider (uses real location when available).
  Map<String, String> _getTodayPrayerTimes(WidgetRef ref) {
    return ref.watch(todayPrayerTimesProvider).valueOrNull ?? {};
  }

  void _showNewCategoryDialog(BuildContext context, List<domain.Category> existing) {
    final nameController = TextEditingController();
    String selectedEmoji = '📁';
    String selectedColor = '#0D7377';

    // Simple inline dialog — reuses pattern from categories_screen
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('New Category'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Category Name *'),
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                ),
                const SizedBox(height: KitabSpacing.md),
                // Simple emoji + color row
                Row(
                  children: [
                    // Emoji
                    GestureDetector(
                      onTap: () {
                        // Cycle through a few common emojis
                        const emojis = ['📁', '💪', '🕌', '📚', '💼', '🏠', '❤️', '🧠', '🎯', '🎨', '🏃', '🧘', '🌙', '💰'];
                        final idx = emojis.indexOf(selectedEmoji);
                        setDialogState(() => selectedEmoji = emojis[(idx + 1) % emojis.length]);
                      },
                      child: Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(color: KitabColors.gray300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(child: Text(selectedEmoji, style: const TextStyle(fontSize: 24))),
                      ),
                    ),
                    const SizedBox(width: KitabSpacing.md),
                    // Color dots
                    Expanded(
                      child: Wrap(
                        spacing: 6, runSpacing: 6,
                        children: ['#0D7377', '#C8963E', '#C43D3D', '#3498DB', '#2D8659', '#9B59B6', '#E67E22', '#1ABC9C']
                            .map((c) => GestureDetector(
                                  onTap: () => setDialogState(() => selectedColor = c),
                                  child: Container(
                                    width: 24, height: 24,
                                    decoration: BoxDecoration(
                                      color: Color(int.parse(c.replaceFirst('#', '0xFF'))),
                                      shape: BoxShape.circle,
                                      border: c == selectedColor ? Border.all(color: Colors.white, width: 2) : null,
                                      boxShadow: c == selectedColor ? [BoxShadow(color: Color(int.parse(c.replaceFirst('#', '0xFF'))).withValues(alpha: 0.5), blurRadius: 4)] : null,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () {
              Navigator.pop(ctx);
              // Reset dropdown to previous value
              setState(() {});
            }, child: const Text('Cancel')),
            FilledButton(onPressed: () async {
              final catName = nameController.text.trim();
              if (catName.isEmpty) return;

              // Check for duplicates
              if (existing.any((c) => c.name.toLowerCase() == catName.toLowerCase())) {
                KitabToast.error(context, 'Category "$catName" already exists');
                return;
              }

              final catId = _uuid.v4();
              final now = DateTime.now();
              await ref.read(categoryRepositoryProvider).save(domain.Category(
                id: catId,
                userId: ref.read(currentUserIdProvider),
                name: catName,
                icon: selectedEmoji,
                color: selectedColor,
                sortOrder: existing.length,
                createdAt: now,
                updatedAt: now,
              ));

              if (mounted) {
                setState(() => _selectedCategoryId = catId);
                Navigator.pop(ctx);
              }
            }, child: const Text('Create')),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) { KitabToast.error(context, 'Activity name is required'); return; }
    if (_selectedCategoryId == null) { KitabToast.error(context, 'Please select a category'); return; }

    final existing = widget.existingActivity;
    final now = DateTime.now();

    // Detect if schedule or goals changed (for existing activities)
    final scheduleChanged = _isEditing && _didScheduleChange(existing!);
    final goalsChanged = _isEditing && _didGoalsChange(existing!);

    // If schedule changed, ask user how to apply
    String? migrationChoice;
    if (scheduleChanged && mounted) {
      migrationChoice = await _showMigrationDialog();
      if (migrationChoice == null) return; // User cancelled
    }

    setState(() => _saving = true);
    try {
      Map<String, dynamic>? scheduleJson;
      if (_hasSchedule) {
        if (migrationChoice == 'future_only' && existing?.schedule != null) {
          // Append new version, close old one
          final oldVersions = (existing!.schedule!['versions'] as List<dynamic>?) ?? [];
          final closedVersions = oldVersions.map((v) {
            final m = Map<String, dynamic>.from(v as Map);
            if (m['effective_to'] == null) {
              m['effective_to'] = _schedule.startDate.subtract(const Duration(days: 1)).toIso8601String();
            }
            return m;
          }).toList();
          closedVersions.add({
            'effective_from': _schedule.startDate.toIso8601String(),
            'effective_to': null,
            'config': _schedule.toJson(),
          });
          scheduleJson = {'versions': closedVersions};
        } else {
          // Single version (new activity or retroactive)
          scheduleJson = {'versions': [{'effective_from': _schedule.startDate.toIso8601String(), 'effective_to': null, 'config': _schedule.toJson()}]};
        }
      }

      Map<String, dynamic>? goalsJson;
      if (_hasGoals && _goals.isNotEmpty) {
        if (!_goals.any((g) => g.isPrimary)) _goals.first.isPrimary = true;
        if (goalsChanged && migrationChoice == 'future_only' && existing != null && existing.goals != null) {
          // Append new goal version
          final oldVersions = (existing.goals!['versions'] as List<dynamic>?) ?? [];
          final closedVersions = oldVersions.map((v) {
            final m = Map<String, dynamic>.from(v as Map);
            if (m['effective_to'] == null) {
              m['effective_to'] = now.toIso8601String();
            }
            return m;
          }).toList();
          closedVersions.add({
            'effective_from': now.toIso8601String(),
            'effective_to': null,
            'goals': _goals.map((g) => g.toJson()).toList(),
          });
          goalsJson = {'versions': closedVersions};
        } else {
          goalsJson = {'versions': [{'effective_from': now.toIso8601String(), 'effective_to': null, 'goals': _goals.map((g) => g.toJson()).toList()}]};
        }
      }

      final activity = Activity(
        id: existing?.id ?? _uuid.v4(),
        userId: ref.read(currentUserIdProvider),
        categoryId: _selectedCategoryId!,
        name: name,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        isArchived: existing?.isArchived ?? false,
        isPrivate: _isPrivate,
        schedule: scheduleJson,
        fields: _fields.map((f) => f.toJson()).toList(),
        goals: goalsJson,
        primaryGoalId: _goals.where((g) => g.isPrimary).map((g) => g.id).firstOrNull,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );

      await ref.read(activityRepositoryProvider).save(activity);

      // Run retroactive migration if chosen
      if (migrationChoice == 'retroactive' && scheduleJson != null) {
        const engine = ScheduleMigrationEngine();
        final result = await engine.migrateRetroactive(
          userId: ref.read(currentUserIdProvider),
          activityId: activity.id,
          newScheduleJson: scheduleJson,
          entryRepo: ref.read(entryRepositoryProvider),
          statusRepo: ref.read(periodStatusRepositoryProvider),
        );

        if (mounted) {
          KitabToast.success(context, 'Migration complete: $result');
        }
      } else if (migrationChoice == 'remove_history') {
        // Delete all old statuses and unlink entries
        final userId = ref.read(currentUserIdProvider);
        await ref.read(entryRepositoryProvider).unlinkAllForActivity(userId, activity.id);
        await ref.read(periodStatusRepositoryProvider).deleteAllForActivity(userId, activity.id);
        await ref.read(periodStatusRepositoryProvider).deleteAllGoalStatusesForActivity(userId, activity.id);
      }

      refreshAllEntryProviders(ref);
      _hasChanges = false;
      if (mounted) {
        Navigator.pop(context);
        KitabToast.success(context, _isEditing ? 'Activity updated' : 'Activity created');
      }
    } catch (e) {
      if (mounted) KitabToast.error(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Detect if the schedule configuration changed.
  bool _didScheduleChange(Activity existing) {
    final oldHasSchedule = existing.schedule != null;
    if (oldHasSchedule != _hasSchedule) return true;
    if (!_hasSchedule) return false;
    // Compare the JSON — rough but effective
    final oldConfig = existing.schedule.toString();
    final newConfig = {'versions': [{'effective_from': _schedule.startDate.toIso8601String(), 'effective_to': null, 'config': _schedule.toJson()}]}.toString();
    return oldConfig != newConfig;
  }

  /// Detect if goals changed.
  bool _didGoalsChange(Activity existing) {
    final oldHasGoals = existing.goals != null;
    if (oldHasGoals != _hasGoals) return true;
    if (!_hasGoals) return false;
    final oldGoals = existing.goals.toString();
    final newGoals = _goals.map((g) => g.toJson()).toList().toString();
    return oldGoals != newGoals;
  }

  /// Show dialog asking how to apply schedule changes.
  Future<String?> _showMigrationDialog() async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apply Schedule Changes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("You've changed the schedule or goals for this activity.",
                style: KitabTypography.body),
            const SizedBox(height: KitabSpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.arrow_forward, color: KitabColors.primary),
              title: const Text('From start date onwards'),
              subtitle: const Text('Past history stays unchanged. Recommended.'),
              dense: true,
              onTap: () => Navigator.pop(ctx, 'future_only'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history, color: KitabColors.warning),
              title: const Text('Retroactively'),
              subtitle: const Text('Recomputes all periods. Entries re-linked automatically.'),
              dense: true,
              onTap: () => Navigator.pop(ctx, 'retroactive'),
            ),
            if (!_hasSchedule)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_outline, color: KitabColors.error),
                title: const Text('Remove previous history'),
                subtitle: const Text('Clear old periods and unlink entries.'),
                dense: true,
                onTap: () => Navigator.pop(ctx, 'remove_history'),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete Activity?'),
      content: const Text('Existing entries will remain in the Book.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: KitabColors.error),
          onPressed: () async { await ref.read(activityRepositoryProvider).delete(widget.existingActivity!.id); if (mounted) { Navigator.pop(ctx); Navigator.pop(context); } },
          child: const Text('Delete')),
      ],
    ));
  }
}
