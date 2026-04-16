// ═══════════════════════════════════════════════════════════════════
// ROUTINE_EXECUTION_SCREEN.DART — Step-by-Step Routine Runner
// Shows activities in sequence. Each activity gets an inline form.
// Skip / Complete / Excuse per activity. Reorder mid-routine.
// See SPEC.md §6.4 for specification.
// ═══════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/database_providers.dart';
import '../../core/utils/provider_refresh.dart';
import '../../core/theme/kitab_theme.dart';
import '../../data/models/activity.dart';
import '../../data/models/entry.dart';
import '../../core/widgets/kitab_toast.dart';
import '../../data/models/routine.dart';

const _uuid = Uuid();

class RoutineExecutionScreen extends ConsumerStatefulWidget {
  final Routine routine;

  const RoutineExecutionScreen({super.key, required this.routine});

  @override
  ConsumerState<RoutineExecutionScreen> createState() =>
      _RoutineExecutionScreenState();
}

class _RoutineExecutionScreenState
    extends ConsumerState<RoutineExecutionScreen> {
  late List<_RoutineStep> _steps;
  int _currentStepIndex = 0;
  DateTime _startTime = DateTime.now();
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _steps = widget.routine.activitySequence.map((seq) {
      return _RoutineStep(
        activityId: seq['activity_id'] as String? ?? '',
        status: _StepStatus.pending,
      );
    }).toList();

    _startTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsed = DateTime.now().difference(_startTime));
      }
    });

    _loadActivities();
  }

  Future<void> _loadActivities() async {
    final activityRepo = ref.read(activityRepositoryProvider);
    for (final step in _steps) {
      final activity = await activityRepo.getById(step.activityId);
      if (mounted) {
        setState(() => step.activity = activity);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completedCount =
        _steps.where((s) => s.status == _StepStatus.completed).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routine.name, style: KitabTypography.h2),
        actions: [
          // Elapsed time
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                _formatDuration(_elapsed),
                style: KitabTypography.mono,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: _steps.isEmpty ? 0 : completedCount / _steps.length,
            backgroundColor: KitabColors.gray100,
            color: KitabColors.primary,
          ),

          // Progress text
          Padding(
            padding: const EdgeInsets.all(KitabSpacing.md),
            child: Text(
              '$completedCount / ${_steps.length} activities completed',
              style: KitabTypography.bodySmall
                  .copyWith(color: KitabColors.gray500),
            ),
          ),

          // Steps list
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: KitabSpacing.lg),
              itemCount: _steps.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _steps.removeAt(oldIndex);
                  _steps.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final step = _steps[index];
                final isCurrent = index == _currentStepIndex;

                return _StepCard(
                  key: ValueKey(step.activityId),
                  step: step,
                  isCurrent: isCurrent,
                  onComplete: () => _completeStep(index),
                  onSkip: () => _skipStep(index),
                  onExcuse: () => _excuseStep(index),
                );
              },
            ),
          ),

          // Bottom action bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(KitabSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: _allDone
                    ? FilledButton(
                        onPressed: _saving ? null : _finishRoutine,
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Finish Routine'),
                      )
                    : OutlinedButton(
                        onPressed: () => _confirmExit(),
                        child: const Text('Exit Routine'),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _allDone =>
      _steps.every((s) => s.status != _StepStatus.pending);

  void _completeStep(int index) async {
    final step = _steps[index];
    final userId = ref.read(currentUserIdProvider);
    final now = DateTime.now();

    // Create an entry for this activity
    final entry = Entry(
      id: _uuid.v4(),
      userId: userId,
      name: step.activity?.name ?? 'Activity',
      activityId: step.activityId,
      loggedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    await ref.read(entryRepositoryProvider).save(entry);
    refreshAllEntryProviders(ref);

    setState(() {
      step.status = _StepStatus.completed;
      // Move to next pending step
      _advanceToNextPending();
    });
  }

  void _skipStep(int index) {
    setState(() {
      _steps[index].status = _StepStatus.skipped;
      _advanceToNextPending();
    });
  }

  void _excuseStep(int index) {
    setState(() {
      _steps[index].status = _StepStatus.excused;
      _advanceToNextPending();
    });
  }

  void _advanceToNextPending() {
    for (var i = 0; i < _steps.length; i++) {
      if (_steps[i].status == _StepStatus.pending) {
        _currentStepIndex = i;
        return;
      }
    }
    _currentStepIndex = _steps.length; // All done
  }

  Future<void> _finishRoutine() async {
    setState(() => _saving = true);
    try {
      final userId = ref.read(currentUserIdProvider);
      final now = DateTime.now();
      final completedCount =
          _steps.where((s) => s.status == _StepStatus.completed).length;

      final routineEntry = RoutineEntry(
        id: _uuid.v4(),
        userId: userId,
        routineId: widget.routine.id,
        startedAt: _startTime,
        endedAt: now,
        activeDuration: _elapsed.toString(),
        activitiesCompleted: completedCount,
        activitiesTotal: _steps.length,
        status: completedCount == _steps.length
            ? 'completed'
            : completedCount > 0
                ? 'partial'
                : 'missed',
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(routineRepositoryProvider).saveEntry(routineEntry);

      if (mounted) {
        Navigator.pop(context);
        KitabToast.success(context,
            'Routine complete! $completedCount/${_steps.length} activities done.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Routine?'),
        content: const Text(
            'Your progress will be saved as a partial completion.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _finishRoutine();
            },
            child: const Text('Exit & Save'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$m:$s';
    }
    return '$m:$s';
  }
}

enum _StepStatus { pending, completed, skipped, excused }

class _RoutineStep {
  final String activityId;
  _StepStatus status;
  Activity? activity;

  _RoutineStep({required this.activityId, required this.status});
}

class _StepCard extends StatelessWidget {
  final _RoutineStep step;
  final bool isCurrent;
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  final VoidCallback onExcuse;

  const _StepCard({
    super.key,
    required this.step,
    required this.isCurrent,
    required this.onComplete,
    required this.onSkip,
    required this.onExcuse,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = step.status != _StepStatus.pending;
    final name = step.activity?.name ?? 'Loading...';

    return Card(
      margin: const EdgeInsets.only(bottom: KitabSpacing.sm),
      color: isCurrent
          ? KitabColors.primary.withValues(alpha: 0.05)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Status icon
            Icon(
              isDone
                  ? (step.status == _StepStatus.completed
                      ? Icons.check_circle
                      : step.status == _StepStatus.excused
                          ? Icons.info_outline
                          : Icons.skip_next)
                  : (isCurrent
                      ? Icons.play_circle_outline
                      : Icons.radio_button_unchecked),
              color: isDone
                  ? (step.status == _StepStatus.completed
                      ? KitabColors.success
                      : KitabColors.gray400)
                  : (isCurrent ? KitabColors.primary : KitabColors.gray300),
            ),
            const SizedBox(width: 12),

            // Name
            Expanded(
              child: Text(
                name,
                style: KitabTypography.body.copyWith(
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  color: isDone ? KitabColors.gray400 : null,
                ),
              ),
            ),

            // Actions (only for current/pending)
            if (!isDone) ...[
              IconButton(
                icon: const Icon(Icons.check, color: KitabColors.success),
                onPressed: onComplete,
                tooltip: 'Complete',
              ),
              IconButton(
                icon: const Icon(Icons.skip_next, color: KitabColors.gray400),
                onPressed: onSkip,
                tooltip: 'Skip',
              ),
            ],

            // Drag handle
            const Icon(Icons.drag_handle, color: KitabColors.gray300),
          ],
        ),
      ),
    );
  }
}
