// ═══════════════════════════════════════════════════════════════════
// ROUTINE_DETAIL_SCREEN.DART — Routine Overview & History
// Overview: computed completion stats, sequence, schedule, goal.
// History: period-based statuses computed from activity entries.
// "Start Routine" button launches RoutineExecutionScreen.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/engines/engines.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/theme/kitab_theme.dart';
import '../../../data/models/activity.dart';
import '../../../data/models/entry.dart';
import '../../../data/models/routine.dart';
import '../../routines/routine_execution_screen.dart';
import 'routine_form_screen.dart';

const _periodEngine = PeriodEngine();
const _completionEngine = RoutineCompletionEngine();

class RoutineDetailScreen extends ConsumerWidget {
  final Routine routine;

  const RoutineDetailScreen({super.key, required this.routine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            routine.isPrivate ? '••••••••' : routine.name,
            style: KitabTypography.h2,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => RoutineFormScreen(existingRoutine: routine))),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(routine: routine, userId: userId),
            _HistoryTab(routine: routine, userId: userId),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => RoutineExecutionScreen(routine: routine))),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Routine'),
          backgroundColor: KitabColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// OVERVIEW TAB — computed completion + sequence + schedule + goal
// ═══════════════════════════════════════════════════════════════════

class _OverviewTab extends ConsumerWidget {
  final Routine routine;
  final String userId;

  const _OverviewTab({required this.routine, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Compute today's completion from activity entries
    final todayCompletionFuture = _computeTodayCompletion(ref);

    return FutureBuilder<RoutineCompletionResult?>(
      future: todayCompletionFuture,
      builder: (context, snapshot) {
        final todayResult = snapshot.data;

        return ListView(
          padding: const EdgeInsets.all(KitabSpacing.lg),
          children: [
            // ─── Today's completion ───
            if (routine.schedule != null && todayResult != null) ...[
              _buildTodayProgress(context, todayResult),
              const SizedBox(height: KitabSpacing.lg),
            ],

            // ─── At a glance ───
            Text('At a Glance', style: KitabTypography.h3),
            const SizedBox(height: KitabSpacing.sm),
            Container(
              padding: const EdgeInsets.all(KitabSpacing.md),
              decoration: BoxDecoration(
                color: KitabColors.gray100.withValues(alpha: 0.5),
                borderRadius: KitabRadii.borderMd,
              ),
              child: Column(
                children: [
                  _InfoRow(icon: Icons.layers, label: 'Activities', value: '${routine.activitySequence.length} in sequence'),
                  if (routine.isPrivate)
                    const _InfoRow(icon: Icons.lock_outline, label: 'Privacy', value: 'Private'),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Created',
                    value: ref.watch(dateFormatterProvider).fullDate(routine.createdAt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: KitabSpacing.lg),

            // ─── Description ───
            if (routine.description != null && routine.description!.isNotEmpty) ...[
              Text('Description', style: KitabTypography.h3),
              const SizedBox(height: KitabSpacing.sm),
              Text(routine.description!, style: KitabTypography.body),
              const SizedBox(height: KitabSpacing.lg),
            ],

            // ─── Activity Sequence ───
            Text('Activity Sequence', style: KitabTypography.h3),
            const SizedBox(height: KitabSpacing.sm),
            _ActivitySequenceList(routine: routine, completion: todayResult),
            const SizedBox(height: KitabSpacing.lg),

            // ─── Schedule ───
            Text('Schedule', style: KitabTypography.h3),
            const SizedBox(height: KitabSpacing.sm),
            _buildSchedule(),
            const SizedBox(height: KitabSpacing.lg),

            // ─── Primary Goal ───
            _buildPrimaryGoal(),

            // Space for FAB
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Future<RoutineCompletionResult?> _computeTodayCompletion(WidgetRef ref) async {
    if (routine.schedule == null) return null;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // Compute periods for today
    final periods = _periodEngine.computePeriodsForDate(
      scheduleJson: routine.schedule,
      date: todayStart,
    );
    if (periods.isEmpty) return null;

    final period = periods.first;

    // Get all entries for the period across all activities in the sequence
    final entryRepo = ref.read(entryRepositoryProvider);
    final allEntries = <Entry>[];
    final activityIds = routine.activitySequence
        .map((s) => s['activity_id'] as String?)
        .whereType<String>()
        .toSet();

    for (final activityId in activityIds) {
      final entries = await entryRepo.getByPeriod(userId, activityId, period.start, period.end);
      allEntries.addAll(entries);
    }

    return _completionEngine.computeCompletion(
      activitySequence: routine.activitySequence,
      entriesForPeriod: allEntries,
    );
  }

  Widget _buildTodayProgress(BuildContext context, RoutineCompletionResult result) {
    final (Color color, String label) = switch (result.status) {
      'completed' => (KitabColors.success, 'Completed'),
      'partial' => (KitabColors.warning, 'In Progress'),
      _ => (KitabColors.gray400, 'Pending'),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: KitabRadii.borderMd,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Today's Progress", style: KitabTypography.body.copyWith(fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(label,
                    style: KitabTypography.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: KitabSpacing.sm),
          LinearProgressIndicator(
            value: result.progressPercent,
            backgroundColor: KitabColors.gray100,
            color: color,
          ),
          const SizedBox(height: KitabSpacing.xs),
          Text(
            '${result.slotsFilled} of ${result.slotsTotal} activities done',
            style: KitabTypography.caption.copyWith(color: KitabColors.gray500),
          ),
          if (result.status == 'pending') ...[
            const SizedBox(height: KitabSpacing.xs),
            Text('Ready to start!',
                style: KitabTypography.caption.copyWith(color: KitabColors.primary)),
          ],
        ],
      ),
    );
  }

  Widget _buildSchedule() {
    if (routine.schedule == null) {
      return Container(
        padding: const EdgeInsets.all(KitabSpacing.md),
        decoration: BoxDecoration(
          color: KitabColors.gray100.withValues(alpha: 0.5),
          borderRadius: KitabRadii.borderMd,
        ),
        child: const _InfoRow(
          icon: Icons.all_inclusive,
          label: 'Frequency',
          value: 'No schedule — start whenever',
        ),
      );
    }

    final versions = routine.schedule!['versions'] as List<dynamic>?;
    if (versions == null || versions.isEmpty) {
      return Text('Schedule configured', style: KitabTypography.body.copyWith(color: KitabColors.gray500));
    }

    final config = (versions.last as Map<String, dynamic>)['config'] as Map<String, dynamic>? ?? {};
    final freq = config['frequency'] as String? ?? 'daily';
    final calendar = config['calendar'] as String? ?? 'gregorian';
    final hasWindow = config['has_time_window'] as bool? ?? false;
    final windowStart = config['window_start'] as String?;
    final windowEnd = config['window_end'] as String?;

    return Container(
      padding: const EdgeInsets.all(KitabSpacing.md),
      decoration: BoxDecoration(
        color: KitabColors.gray100.withValues(alpha: 0.5),
        borderRadius: KitabRadii.borderMd,
      ),
      child: Column(
        children: [
          _InfoRow(icon: Icons.repeat, label: 'Frequency', value: freq[0].toUpperCase() + freq.substring(1)),
          if (calendar == 'hijri')
            const _InfoRow(icon: Icons.auto_awesome, label: 'Calendar', value: 'Hijri'),
          if (hasWindow && windowStart != null && windowEnd != null)
            _InfoRow(icon: Icons.schedule, label: 'Time Window', value: '$windowStart → $windowEnd'),
        ],
      ),
    );
  }

  Widget _buildPrimaryGoal() {
    if (routine.goals == null) return const SizedBox.shrink();
    final versions = routine.goals!['versions'] as List<dynamic>?;
    if (versions == null || versions.isEmpty) return const SizedBox.shrink();
    final goals = (versions.last as Map<String, dynamic>)['goals'] as List<dynamic>? ?? [];
    if (goals.isEmpty) return const SizedBox.shrink();

    final primary = goals.firstWhere(
      (g) => (g as Map<String, dynamic>)['is_primary'] == true,
      orElse: () => goals.first,
    ) as Map<String, dynamic>;

    final goalType = primary['goal_type'] as String? ?? 'completion';
    String summary;
    if (goalType == 'completion') {
      final comp = primary['completion_comparison'] as String? ?? '>=';
      final count = primary['completion_count']?.toString() ?? '1';
      final freq = _getFrequency();
      final compLabel = switch (comp) { '>=' => 'at least', '<=' => 'at most', '=' => 'exactly', _ => comp };
      summary = 'Complete $compLabel $count ${int.tryParse(count) == 1 ? 'time' : 'times'} per $freq';
    } else {
      summary = 'Goal configured';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Primary Goal', style: KitabTypography.h3),
        const SizedBox(height: KitabSpacing.sm),
        Container(
          padding: const EdgeInsets.all(KitabSpacing.md),
          decoration: BoxDecoration(
            color: KitabColors.accent.withValues(alpha: 0.05),
            borderRadius: KitabRadii.borderMd,
            border: Border.all(color: KitabColors.accent.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.star, size: 20, color: KitabColors.accent),
              const SizedBox(width: KitabSpacing.sm),
              Expanded(child: Text(summary, style: KitabTypography.body.copyWith(color: KitabColors.gray600))),
            ],
          ),
        ),
      ],
    );
  }

  String _getFrequency() {
    if (routine.schedule == null) return 'period';
    final versions = routine.schedule!['versions'] as List<dynamic>?;
    if (versions == null || versions.isEmpty) return 'period';
    final config = (versions.last as Map<String, dynamic>)['config'] as Map<String, dynamic>?;
    final freq = config?['frequency'] as String? ?? 'daily';
    return switch (freq) { 'daily' => 'day', 'weekly' => 'week', 'monthly' => 'month', 'yearly' => 'year', _ => 'period' };
  }
}

// ═══════════════════════════════════════════════════════════════════
// ACTIVITY SEQUENCE LIST — shows check marks for today's completion
// ═══════════════════════════════════════════════════════════════════

class _ActivitySequenceList extends ConsumerWidget {
  final Routine routine;
  final RoutineCompletionResult? completion;

  const _ActivitySequenceList({required this.routine, this.completion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (routine.activitySequence.isEmpty) {
      return Text('No activities in this routine.',
          style: KitabTypography.body.copyWith(color: KitabColors.gray500));
    }

    return FutureBuilder<List<Activity?>>(
      future: Future.wait(
        routine.activitySequence.map((seq) {
          final id = seq['activity_id'] as String? ?? '';
          return ref.read(activityRepositoryProvider).getById(id);
        }),
      ),
      builder: (context, snapshot) {
        final activities = snapshot.data;

        // Build a running count of how many times we've seen each activity
        // to determine which slots are filled
        final seenCount = <String, int>{};

        return Column(
          children: routine.activitySequence.asMap().entries.map((entry) {
            final index = entry.key;
            final activityId = entry.value['activity_id'] as String? ?? '';
            final activity = activities != null && index < activities.length ? activities[index] : null;
            final name = activity?.name ?? 'Unknown Activity';

            // Determine if this specific slot is filled
            seenCount[activityId] = (seenCount[activityId] ?? 0) + 1;
            final slotNumber = seenCount[activityId]!;
            bool isFilled = false;
            if (completion != null) {
              final info = completion!.perActivity[activityId];
              if (info != null) {
                isFilled = info.available >= slotNumber;
              }
            }

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: isFilled
                    ? KitabColors.success.withValues(alpha: 0.15)
                    : KitabColors.primary.withValues(alpha: 0.1),
                child: isFilled
                    ? const Icon(Icons.check, size: 16, color: KitabColors.success)
                    : Text('${index + 1}', style: KitabTypography.caption.copyWith(
                        color: KitabColors.primary, fontWeight: FontWeight.w600,
                      )),
              ),
              title: Text(
                name,
                style: KitabTypography.body.copyWith(
                  decoration: isFilled ? TextDecoration.lineThrough : null,
                  color: isFilled ? KitabColors.gray400 : null,
                ),
              ),
              dense: true,
            );
          }).toList(),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// HISTORY TAB — period-based statuses computed from activity entries
// ═══════════════════════════════════════════════════════════════════

class _HistoryTab extends ConsumerWidget {
  final Routine routine;
  final String userId;

  const _HistoryTab({required this.routine, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (routine.schedule == null) {
      // No schedule — show session-based history from routine entries
      return _buildSessionHistory(ref);
    }

    // Scheduled — compute period statuses from activity entries
    return _buildPeriodHistory(ref);
  }

  Widget _buildPeriodHistory(WidgetRef ref) {
    return FutureBuilder<List<_PeriodItem>>(
      future: _computePeriodHistory(ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final periods = snapshot.data ?? [];

        if (periods.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(KitabSpacing.lg),
          itemCount: periods.length,
          itemBuilder: (context, index) => _PeriodCard(item: periods[index], fmt: ref.watch(dateFormatterProvider)),
        );
      },
    );
  }

  Future<List<_PeriodItem>> _computePeriodHistory(WidgetRef ref) async {
    if (routine.schedule == null) return [];

    final entryRepo = ref.read(entryRepositoryProvider);
    final now = DateTime.now();

    // Compute periods for the last 30 days
    final items = <_PeriodItem>[];
    final activityIds = routine.activitySequence
        .map((s) => s['activity_id'] as String?)
        .whereType<String>()
        .toSet();

    for (var i = 0; i < 30; i++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final periods = _periodEngine.computePeriodsForDate(
        scheduleJson: routine.schedule,
        date: date,
      );

      for (final period in periods) {
        // Avoid duplicates (multi-day periods)
        if (items.any((item) => item.period.start == period.start && item.period.end == period.end)) {
          continue;
        }

        // Get entries for all activities in this period
        final allEntries = <Entry>[];
        for (final activityId in activityIds) {
          final entries = await entryRepo.getByPeriod(userId, activityId, period.start, period.end);
          allEntries.addAll(entries);
        }

        final result = _completionEngine.computeCompletion(
          activitySequence: routine.activitySequence,
          entriesForPeriod: allEntries,
        );

        // For future periods, mark as pending
        final isFuture = period.start.isAfter(now);
        final status = isFuture ? 'pending' : result.status;

        items.add(_PeriodItem(
          period: period,
          completion: result,
          status: status,
        ));
      }
    }

    // Sort newest first
    items.sort((a, b) => b.period.start.compareTo(a.period.start));
    return items;
  }

  Widget _buildSessionHistory(WidgetRef ref) {
    return FutureBuilder<List<RoutineEntry>>(
      future: ref.read(routineRepositoryProvider).getEntriesByDateRange(
        userId, DateTime(2020), DateTime.now().add(const Duration(days: 1)),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allEntries = snapshot.data ?? [];
        final entries = allEntries.where((e) => e.routineId == routine.id).toList()
          ..sort((a, b) => (b.startedAt ?? b.createdAt).compareTo(a.startedAt ?? a.createdAt));

        if (entries.isEmpty) return _buildEmptyState();

        return ListView.builder(
          padding: const EdgeInsets.all(KitabSpacing.lg),
          itemCount: entries.length,
          itemBuilder: (context, index) => _SessionCard(entry: entries[index], fmt: ref.watch(dateFormatterProvider)),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KitabSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: KitabColors.gray300),
            const SizedBox(height: KitabSpacing.md),
            Text('No history yet', style: KitabTypography.h3),
            const SizedBox(height: KitabSpacing.sm),
            Text(
              'Your routine history will appear here as you log activities.',
              style: KitabTypography.body.copyWith(color: KitabColors.gray500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Period item model ───
class _PeriodItem {
  final ComputedPeriod period;
  final RoutineCompletionResult completion;
  final String status;

  const _PeriodItem({
    required this.period,
    required this.completion,
    required this.status,
  });
}

// ═══════════════════════════════════════════════════════════════════
// PERIOD CARD — computed status for a scheduled routine period
// ═══════════════════════════════════════════════════════════════════

class _PeriodCard extends StatelessWidget {
  final _PeriodItem item;
  final KitabDateFormat fmt;

  const _PeriodCard({required this.item, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color, String label) = switch (item.status) {
      'completed' => (Icons.check_circle, KitabColors.success, 'Completed'),
      'partial' => (Icons.pie_chart, KitabColors.warning, 'Partial'),
      'pending' => (Icons.schedule, KitabColors.gray400, 'Pending'),
      'missed' => (Icons.cancel, KitabColors.error, 'Missed'),
      'excused' => (Icons.remove_circle, KitabColors.gray400, 'Excused'),
      _ => (Icons.circle_outlined, KitabColors.gray400, item.status),
    };

    final dateStr = fmt.shortDateWithDayName(item.period.start);
    final isToday = _isToday(item.period.start);

    return Card(
      margin: const EdgeInsets.only(bottom: KitabSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(KitabSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: KitabSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isToday ? 'Today — $dateStr' : dateStr,
                    style: KitabTypography.body.copyWith(
                      fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.completion.slotsFilled}/${item.completion.slotsTotal} activities done',
                    style: KitabTypography.caption.copyWith(color: KitabColors.gray500),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(label,
                  style: KitabTypography.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

// ═══════════════════════════════════════════════════════════════════
// SESSION CARD — for unscheduled routines (execution-based)
// ═══════════════════════════════════════════════════════════════════

class _SessionCard extends StatelessWidget {
  final RoutineEntry entry;
  final KitabDateFormat fmt;

  const _SessionCard({required this.entry, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color, String label) = switch (entry.status) {
      'completed' => (Icons.check_circle, KitabColors.success, 'Completed'),
      'partial' => (Icons.pie_chart, KitabColors.warning, 'Partial'),
      'missed' => (Icons.cancel, KitabColors.error, 'Missed'),
      'in_progress' => (Icons.play_circle, KitabColors.primary, 'In Progress'),
      _ => (Icons.circle_outlined, KitabColors.gray400, entry.status),
    };

    final dateStr = entry.startedAt != null
        ? fmt.shortDateWithTime(entry.startedAt!)
        : fmt.shortDateWithDayName(entry.createdAt);

    final durationStr = _formatDuration(entry);

    return Card(
      margin: const EdgeInsets.only(bottom: KitabSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(KitabSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: KitabSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateStr, style: KitabTypography.body),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.activitiesCompleted}/${entry.activitiesTotal} activities'
                    '${durationStr != null ? ' · $durationStr' : ''}',
                    style: KitabTypography.caption.copyWith(color: KitabColors.gray500),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(label,
                  style: KitabTypography.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  String? _formatDuration(RoutineEntry entry) {
    if (entry.startedAt == null || entry.endedAt == null) return null;
    final diff = entry.endedAt!.difference(entry.startedAt!);
    if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
    }
    return '${diff.inMinutes}m';
  }
}

// ═══════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: KitabColors.gray400),
          const SizedBox(width: KitabSpacing.sm),
          SizedBox(
            width: 100,
            child: Text(label, style: KitabTypography.caption.copyWith(color: KitabColors.gray500)),
          ),
          Expanded(child: Text(value, style: KitabTypography.body)),
        ],
      ),
    );
  }
}
