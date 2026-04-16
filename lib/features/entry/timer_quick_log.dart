// ═══════════════════════════════════════════════════════════════════
// TIMER_QUICK_LOG.DART — Quick Timer Log Bottom Sheet
// Timer state lives in the global ActiveTimersNotifier.
// Closing the sheet minimizes the timer to the mini-bar.
// Reopening restores full UI from the global state.
// See SPEC.md §7.3 for specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/engines/engines.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/location_service.dart';
import '../../core/utils/provider_refresh.dart';
import '../../core/providers/database_providers.dart';
import '../../core/providers/timer_provider.dart';
import '../../core/theme/kitab_theme.dart';
import '../../core/widgets/kitab_toast.dart';
import '../../data/models/entry.dart';
import 'widgets/quick_log_header.dart';
import 'widgets/more_details_section.dart';

const _uuid = Uuid();
const _linkageEngine = LinkageEngine();

/// Start a new timer and show its sheet. Returns true if an entry was saved.
Future<bool?> showTimerQuickLog(BuildContext context, {WidgetRef? ref}) async {
  // Start a new timer via the global provider
  if (ref != null) {
    final notifier = ref.read(activeTimersProvider.notifier);
    final timerId = notifier.startTimer();
    if (timerId == null) {
      // Max 3 timers
      if (context.mounted) {
        KitabToast.error(context, 'Maximum 3 timers at a time. Stop a timer to start a new one.');
      }
      return null;
    }
    return _openTimerSheet(context, timerId);
  }
  return null;
}

/// Reopen an existing timer's sheet (from mini-bar tap).
Future<bool?> reopenTimerSheet(BuildContext context, String timerId) {
  return _openTimerSheet(context, timerId);
}

Future<bool?> _openTimerSheet(BuildContext context, String timerId) {
  final maxWidth = MediaQuery.of(context).size.width > 600 ? 560.0 : double.infinity;
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: true, // Allow dismiss to minimize
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.85,
      maxWidth: maxWidth,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.65,
      child: _TimerQuickLogSheet(timerId: timerId),
    ),
  );
}

class _TimerQuickLogSheet extends ConsumerStatefulWidget {
  final String timerId;
  const _TimerQuickLogSheet({required this.timerId});

  @override
  ConsumerState<_TimerQuickLogSheet> createState() => _TimerQuickLogSheetState();
}

class _TimerQuickLogSheetState extends ConsumerState<_TimerQuickLogSheet> {
  bool _isStopped = false;
  bool _saving = false;
  TimerState? _stoppedTimer; // Holds final state after stop

  final _notesController = TextEditingController();
  final Map<String, TextEditingController> _fieldControllers = {};
  final _headerKey = GlobalKey<QuickLogHeaderState>();
  final _detailsKey = GlobalKey<MoreDetailsSectionState>();

  @override
  void dispose() {
    _notesController.dispose();
    for (final c in _fieldControllers.values) c.dispose();
    super.dispose();
  }

  void _onActivityChanged(dynamic activity) {
    if (activity == null) return;
    final notifier = ref.read(activeTimersProvider.notifier);
    notifier.setActivity(widget.timerId, name: activity.name, activityId: activity.id);

    setState(() {
      _fieldControllers.clear();
      for (final field in activity.fields) {
        final id = field['id'] as String? ?? '';
        _fieldControllers[id] = TextEditingController();
      }
    });
  }

  void _togglePause() {
    ref.read(activeTimersProvider.notifier).togglePause(widget.timerId);
  }

  void _stop() {
    final notifier = ref.read(activeTimersProvider.notifier);
    final stoppedTimer = notifier.stop(widget.timerId);

    if (stoppedTimer != null) {
      // Auto-fill Time & Duration in More Details
      final endTime = ref.read(dateFormatterProvider).time(DateTime.now());
      final durationMins = stoppedTimer.activeDuration.inMinutes;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _detailsKey.currentState?.finalizeTimer(endTime, durationMins);
      });

      setState(() {
        _isStopped = true;
        _stoppedTimer = stoppedTimer;
      });
    }
  }

  void _adjustStartTime(DateTime newStart) {
    ref.read(activeTimersProvider.notifier).adjustStartTime(widget.timerId, newStart);
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    // Watch the global timer state for live updates
    final timers = ref.watch(activeTimersProvider);
    final timer = _isStopped
        ? _stoppedTimer
        : timers.where((t) => t.id == widget.timerId).firstOrNull;

    // Timer was discarded externally
    if (timer == null && !_isStopped) {
      return const Center(child: Text('Timer not found'));
    }

    final elapsed = timer?.elapsed ?? Duration.zero;
    final isRunning = timer?.isRunning ?? false;
    final startTime = timer?.startTime ?? DateTime.now();
    final segments = timer?.segments ?? [];

    return PopScope(
      canPop: !_isStopped,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isStopped) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Discard entry?'),
              content: const Text('Your timer data has not been saved.'),
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
            title: 'Start a Timer',
            onActivityChanged: _onActivityChanged,
          ),

          const SizedBox(height: KitabSpacing.lg),

          // ─── Started at (editable while running) ───
          GestureDetector(
            onTap: _isStopped ? null : () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(startTime),
              );
              if (time != null && mounted) {
                final now = DateTime.now();
                _adjustStartTime(DateTime(now.year, now.month, now.day, time.hour, time.minute));
              }
            },
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: KitabColors.gray400),
                const SizedBox(width: 6),
                Text('Started at ', style: KitabTypography.caption.copyWith(color: KitabColors.gray500)),
                Text(
                  '${ref.watch(dateFormatterProvider).time(startTime)} ${startTime.timeZoneName}',
                  style: KitabTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                ),
                if (!_isStopped) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.edit, size: 14, color: KitabColors.gray400),
                ],
              ],
            ),
          ),

          const SizedBox(height: KitabSpacing.md),

          // ─── Timer display ───
          Center(
            child: Text(
              _formatDuration(elapsed),
              style: KitabTypography.mono.copyWith(
                fontSize: 48,
                color: isRunning ? KitabColors.primary : KitabColors.gray500,
                letterSpacing: 2,
              ),
            ),
          ),
          if (segments.isNotEmpty)
            Center(
              child: Text(
                '${segments.length + (isRunning ? 1 : 0)} segment${segments.length + (isRunning ? 1 : 0) != 1 ? 's' : ''}',
                style: KitabTypography.caption.copyWith(color: KitabColors.gray400),
              ),
            ),

          const SizedBox(height: KitabSpacing.lg),

          // ─── Controls (while active) ───
          if (!_isStopped)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pause / Resume
                Column(
                  children: [
                    FloatingActionButton(
                      heroTag: 'timer_pause_${widget.timerId}',
                      onPressed: _togglePause,
                      backgroundColor: isRunning ? KitabColors.warning : KitabColors.success,
                      child: Icon(isRunning ? Icons.pause : Icons.play_arrow, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isRunning ? 'Pause' : 'Resume',
                      style: KitabTypography.caption.copyWith(color: KitabColors.gray500),
                    ),
                  ],
                ),
                const SizedBox(width: KitabSpacing.xl),
                // Stop & Save
                Column(
                  children: [
                    FloatingActionButton(
                      heroTag: 'timer_stop_${widget.timerId}',
                      onPressed: _stop,
                      backgroundColor: KitabColors.error,
                      child: const Icon(Icons.stop, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Stop',
                      style: KitabTypography.caption.copyWith(color: KitabColors.gray500),
                    ),
                  ],
                ),
              ],
            ),

          // ─── Stopped summary ───
          if (_isStopped && _stoppedTimer != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(KitabSpacing.md),
              decoration: BoxDecoration(
                color: KitabColors.success.withValues(alpha: 0.05),
                borderRadius: KitabRadii.borderMd,
                border: Border.all(color: KitabColors.success.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Text('Timer Stopped', style: KitabTypography.body.copyWith(
                    fontWeight: FontWeight.w600, color: KitabColors.success)),
                  const SizedBox(height: 4),
                  Text(
                    'Active: ${_formatDuration(_stoppedTimer!.activeDuration)} · ${_stoppedTimer!.segments.length} segment${_stoppedTimer!.segments.length == 1 ? '' : 's'}',
                    style: KitabTypography.caption.copyWith(color: KitabColors.gray500),
                  ),
                ],
              ),
            ),
          ],

          // ─── More details ───
          MoreDetailsSection(
            key: _detailsKey,
            loggedAt: startTime,
            onLoggedAtChanged: (_) {},
            notesController: _notesController,
            fieldControllers: _fieldControllers,
            onFieldChanged: () {},
            timeDurationDefault: true,
            initialStartTime: ref.watch(dateFormatterProvider).time(startTime),
            initialDurationMinutes: elapsed.inMinutes,
            durationIsLive: !_isStopped,
          ),

          // ─── Save (only when stopped) ───
          if (_isStopped) ...[
            const SizedBox(height: KitabSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Entry'),
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }

  Future<void> _save() async {
    if (_stoppedTimer == null) return;
    setState(() => _saving = true);

    try {
      final now = DateTime.now();
      final timer = _stoppedTimer!;
      final activityName = _headerKey.currentState?.activityName ?? '';
      final name = timer.activityName != 'Untitled'
          ? timer.activityName
          : (activityName.isEmpty ? 'Untitled' : activityName);

      final linkage = timer.activityId != null
          ? _linkageEngine.autoLink(
              loggedAt: timer.startTime,
              scheduleJson: null, // Would need to look up activity schedule
            )
          : const LinkageResult();

      // Collect field values
      final fieldValues = <String, dynamic>{
        'duration_seconds': timer.activeDuration.inSeconds,
      };
      for (final e in _fieldControllers.entries) {
        final text = e.value.text.trim();
        if (text.isNotEmpty) {
          final asNum = num.tryParse(text);
          fieldValues[e.key] = asNum ?? text;
        }
      }
      final detailValues = _detailsKey.currentState?.collectFieldValues() ?? {};
      fieldValues.addAll(detailValues);

      // Activity location from current GPS
      final location = ref.read(userLocationProvider).valueOrNull;
      if (location != null) {
        fieldValues['activity_location_lat'] = location.latitude;
        fieldValues['activity_location_lng'] = location.longitude;
      }

      // Expected start/end from schedule time window (look up activity)
      if (timer.activityId != null) {
        final activities = await ref.read(activityRepositoryProvider)
            .getByUser(ref.read(currentUserIdProvider));
        final timerActivity = activities
            .where((a) => a.id == timer.activityId)
            .firstOrNull;
        if (timerActivity?.schedule != null) {
          final expected = PeriodEngine.resolveExpectedTimes(
            scheduleJson: timerActivity!.schedule,
            date: DateTime.now(),
          );
          if (expected.start != null) {
            fieldValues['expected_start'] = expected.start!.toIso8601String();
          }
          if (expected.end != null) {
            fieldValues['expected_end'] = expected.end!.toIso8601String();
          }
        }
      }

      final entry = Entry(
        id: _uuid.v4(),
        userId: ref.read(currentUserIdProvider),
        name: name,
        activityId: timer.activityId,
        periodStart: linkage.linkedPeriod?.start,
        periodEnd: linkage.linkedPeriod?.end,
        linkType: linkage.linkType,
        fieldValues: fieldValues,
        timerSegments: timer.segments,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        loggedAt: timer.startTime,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(entryRepositoryProvider).save(entry);
      refreshAllEntryProviders(ref);
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
