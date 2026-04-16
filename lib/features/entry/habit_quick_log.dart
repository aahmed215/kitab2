// ═══════════════════════════════════════════════════════════════════
// HABIT_QUICK_LOG.DART — Quick Habit Log Bottom Sheet
// Activity search → ✓ Done / ✕ Missed → auto-close.
// ✓ creates an entry. ✕ marks the period as missed.
// See SPEC.md §7.4 for specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/engines/engines.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/location_service.dart';
import '../../core/utils/provider_refresh.dart';
import '../../core/providers/database_providers.dart';
import '../../core/theme/kitab_theme.dart';
import '../../data/models/activity.dart';
import '../../data/models/entry.dart';
import '../../data/models/period_status.dart';
import 'widgets/quick_log_header.dart';
import 'widgets/more_details_section.dart';

const _uuid = Uuid();
const _linkageEngine = LinkageEngine();

Future<bool?> showHabitQuickLog(BuildContext context) {
  final maxWidth = MediaQuery.of(context).size.width > 600 ? 560.0 : double.infinity;
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.85,
      maxWidth: maxWidth,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.55,
      child: const _HabitQuickLogSheet(),
    ),
  );
}

class _HabitQuickLogSheet extends ConsumerStatefulWidget {
  const _HabitQuickLogSheet();

  @override
  ConsumerState<_HabitQuickLogSheet> createState() => _HabitQuickLogSheetState();
}

class _HabitQuickLogSheetState extends ConsumerState<_HabitQuickLogSheet> {
  Activity? _selectedActivity;
  bool _saving = false;
  bool _editingHabitLabel = false;
  bool _hasChanges = false;
  DateTime _loggedAt = DateTime.now();
  final _notesController = TextEditingController();
  final _habitLabelController = TextEditingController(text: 'Habit');
  final Map<String, TextEditingController> _fieldControllers = {};
  final _headerKey = GlobalKey<QuickLogHeaderState>();
  final _detailsKey = GlobalKey<MoreDetailsSectionState>();

  @override
  void initState() {
    super.initState();
    _notesController.addListener(() { if (!_hasChanges) setState(() => _hasChanges = true); });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _habitLabelController.dispose();
    for (final c in _fieldControllers.values) c.dispose();
    super.dispose();
  }

  void _confirmDiscard() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard entry?'),
        content: const Text('You have unsaved changes.'),
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

  void _onActivityChanged(Activity? activity) {
    _hasChanges = true;
    setState(() {
      _selectedActivity = activity;
      _fieldControllers.clear();
      if (activity != null) {
        for (final field in activity.fields) {
          final id = field['id'] as String? ?? '';
          _fieldControllers[id] = TextEditingController();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _hasChanges) _confirmDiscard();
      },
      child: SingleChildScrollView(
      padding: EdgeInsets.only(
        left: KitabSpacing.lg,
        right: KitabSpacing.lg,
        top: KitabSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + KitabSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Common header ───
          QuickLogHeader(
            key: _headerKey,
            title: 'Record a Habit',
            onActivityChanged: _onActivityChanged,
          ),

          const SizedBox(height: KitabSpacing.xl),

          // ─── Editable habit label ───
          GestureDetector(
            onTap: () => setState(() => _editingHabitLabel = true),
            child: _editingHabitLabel
                ? TextField(
                    controller: _habitLabelController,
                    decoration: const InputDecoration(isDense: true, hintText: 'Field name'),
                    autofocus: true,
                    onSubmitted: (_) => setState(() => _editingHabitLabel = false),
                  )
                : Row(
                    children: [
                      Text(_habitLabelController.text,
                          style: KitabTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit, size: 12, color: KitabColors.gray400),
                    ],
                  ),
          ),
          const SizedBox(height: KitabSpacing.sm),

          // ─── Quick action: ✓ Done / ✕ Missed ───
          Row(
            children: [
              // ✓ Done
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving ? null : () => _log(true),
                  icon: const Icon(Icons.check, size: 22),
                  label: const Text('Done'),
                  style: FilledButton.styleFrom(
                    backgroundColor: KitabColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: KitabSpacing.md),
              // ✕ Missed
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : () => _log(false),
                  icon: const Icon(Icons.close, size: 22),
                  label: const Text('Missed'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: KitabColors.error,
                    side: const BorderSide(color: KitabColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),

          // ─── Streak line ───
          if (_selectedActivity != null && _selectedActivity!.schedule != null)
            _StreakLine(activityId: _selectedActivity!.id),

          // ─── More details ───
          MoreDetailsSection(
            key: _detailsKey,
            activity: _selectedActivity,
            loggedAt: _loggedAt,
            onLoggedAtChanged: (dt) => setState(() => _loggedAt = dt),
            notesController: _notesController,
            fieldControllers: _fieldControllers,
            onFieldChanged: () {},
          ),
        ],
      ),
    ),
    );
  }

  Future<void> _log(bool completed) async {
    setState(() => _saving = true);

    try {
      final now = DateTime.now();
      final activity = _selectedActivity;
      final activityName = _headerKey.currentState?.activityName ?? '';
      final name = activity?.name ?? (activityName.isEmpty ? 'Untitled' : activityName);

      // Auto-link to period
      final linkage = _linkageEngine.autoLink(
        loggedAt: _loggedAt,
        scheduleJson: activity?.schedule,
      );

      // Collect field values from template fields + ad-hoc fields
      final fieldValues = <String, dynamic>{};
      for (final e in _fieldControllers.entries) {
        final text = e.value.text.trim();
        if (text.isNotEmpty) {
          final asNum = num.tryParse(text);
          fieldValues[e.key] = asNum ?? text;
        }
      }
      // Add ad-hoc and preset field values from More Details
      final detailValues = _detailsKey.currentState?.collectFieldValues() ?? {};
      fieldValues.addAll(detailValues);

      // Activity location from current GPS
      final location = ref.read(userLocationProvider).valueOrNull;
      if (location != null) {
        fieldValues['activity_location_lat'] = location.latitude;
        fieldValues['activity_location_lng'] = location.longitude;
      }

      // Expected start/end from schedule time window
      if (activity?.schedule != null) {
        final expected = PeriodEngine.resolveExpectedTimes(
          scheduleJson: activity!.schedule,
          date: DateTime.now(),
        );
        if (expected.start != null) {
          fieldValues['expected_start'] = expected.start!.toIso8601String();
        }
        if (expected.end != null) {
          fieldValues['expected_end'] = expected.end!.toIso8601String();
        }
      }

      if (completed) {
        final entry = Entry(
          id: _uuid.v4(),
          userId: ref.read(currentUserIdProvider),
          name: name,
          activityId: activity?.id,
          periodStart: linkage.linkedPeriod?.start,
          periodEnd: linkage.linkedPeriod?.end,
          linkType: linkage.linkType,
          fieldValues: fieldValues,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          loggedAt: _loggedAt,
          createdAt: now,
          updatedAt: now,
        );
        await ref.read(entryRepositoryProvider).save(entry);
      } else {
        // Mark period as missed if linked to a scheduled activity
        if (activity != null && linkage.linkedPeriod != null) {
          final status = ActivityPeriodStatus(
            id: _uuid.v4(),
            userId: ref.read(currentUserIdProvider),
            activityId: activity.id,
            periodStart: linkage.linkedPeriod!.start,
            periodEnd: linkage.linkedPeriod!.end,
            status: 'missed',
            createdAt: now,
            updatedAt: now,
          );
          await ref.read(periodStatusRepositoryProvider).saveActivityStatus(status);
        }
      }

      refreshAllEntryProviders(ref);
      if (mounted) Navigator.pop(context, completed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

/// Shows streak badge for a scheduled activity.
class _StreakLine extends ConsumerWidget {
  final String activityId;
  const _StreakLine({required this.activityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(periodStatusRepositoryProvider)
          .getActivityStatusHistory(ref.read(currentUserIdProvider), activityId),
      builder: (context, snapshot) {
        final statuses = snapshot.data ?? [];
        if (statuses.isEmpty) return const SizedBox.shrink();

        final result = const StreakEngine().calculateActivityStreak(
          statuses.map((s) => s.status).toList(),
        );
        if (result.current == 0 && result.best == 0) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: KitabSpacing.sm),
          child: Row(
            children: [
              Text(result.isFrozen ? '🧊 ' : '🔥 ', style: const TextStyle(fontSize: 14)),
              Text('${result.current}d streak',
                  style: KitabTypography.caption.copyWith(
                    color: KitabColors.accent, fontWeight: FontWeight.w500)),
            ],
          ),
        );
      },
    );
  }
}
