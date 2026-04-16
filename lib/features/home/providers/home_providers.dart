// ═══════════════════════════════════════════════════════════════════
// HOME_PROVIDERS.DART — Riverpod Providers for the Home Screen
// Provides today's scheduled activities, progress, streaks,
// and conditions — all reactive.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/engines/engines.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../data/models/activity.dart';
import '../../../data/models/entry.dart';
import '../../../data/models/condition.dart';
import '../../../data/models/routine.dart';

// ─── Constants ───
const _periodEngine = PeriodEngine();
const _goalEngine = GoalEngine();
// _streakEngine removed — per-activity streaks deferred for performance
const _completionEngine = RoutineCompletionEngine();

/// User's first name from the database (for greeting).
final userFirstNameProvider = FutureProvider<String?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == 'local-user') return null;
  try {
    final response = await Supabase.instance.client
        .from('users')
        .select('name')
        .eq('id', userId)
        .maybeSingle();
    return response?['name'] as String?;
  } catch (_) {
    return null;
  }
});

// ═══════════════════════════════════════════════════════════════════
// TODAY'S DATA
// ═══════════════════════════════════════════════════════════════════

/// Today's midnight-to-midnight boundaries (user's local timezone).
final todayRangeProvider = Provider<({DateTime start, DateTime end})>((ref) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(const Duration(days: 1));
  return (start: start, end: end);
});

/// All active activities for the current user.
/// Falls back to a one-shot fetch if the Realtime stream fails.
final activeActivitiesProvider =
    StreamProvider<List<Activity>>((ref) async* {
  final repo = ref.watch(activityRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  try {
    await for (final activities in repo.watchActiveByUser(userId)) {
      yield activities;
    }
  } catch (_) {
    // Realtime subscription failed (e.g., timeout) — do a one-shot fetch
    final all = await repo.getByUser(userId);
    yield all.where((a) => !a.isArchived).toList();
  }
});

/// Today's entries for the current user.
final todayEntriesProvider =
    FutureProvider<List<Entry>>((ref) async {
  final repo = ref.watch(entryRepositoryProvider);
  final today = ref.watch(todayRangeProvider);
  return repo.getByDateRange(ref.watch(currentUserIdProvider), today.start, today.end);
});

/// All conditions for the current user (ended + active, not deleted).
/// Used by chain-finding logic to walk across merged condition records.
final allConditionsProvider = FutureProvider<List<Condition>>((ref) async {
  final repo = ref.watch(conditionRepositoryProvider);
  return repo.getByUser(ref.watch(currentUserIdProvider));
});

/// Active conditions for the current user.
/// Falls back to a one-shot fetch if the Realtime stream fails.
final activeConditionsProvider =
    StreamProvider<List<Condition>>((ref) async* {
  final repo = ref.watch(conditionRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  try {
    await for (final conditions in repo.watchActiveByUser(userId)) {
      yield conditions;
    }
  } catch (_) {
    // Realtime subscription failed — do a one-shot fetch
    final all = await repo.getByUser(userId);
    yield all.where((c) => c.endDate == null && c.deletedAt == null).toList();
  }
});

/// Category ID → name lookup map.
/// Used by the summary bottom sheet to display category names.
final categoryMapProvider = FutureProvider<Map<String, String>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  final categories = await repo.getByUser(ref.watch(currentUserIdProvider));
  return {for (final c in categories) c.id: c.name};
});

/// Full list of the user's categories (for icon + color lookup on cards).
final homeCategoriesProvider = FutureProvider((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getByUser(ref.watch(currentUserIdProvider));
});

// ═══════════════════════════════════════════════════════════════════
// SCHEDULED TODAY — Activities with periods that overlap today
// ═══════════════════════════════════════════════════════════════════

/// A scheduled activity with its computed period and current status.
class ScheduledActivityState {
  final Activity activity;
  final ComputedPeriod period;
  final String status; // 'pending', 'completed', 'missed', 'excused'
  final GoalEvaluation? primaryGoalEval;
  final int streakCount;
  final bool streakFrozen;

  const ScheduledActivityState({
    required this.activity,
    required this.period,
    this.status = 'pending',
    this.primaryGoalEval,
    this.streakCount = 0,
    this.streakFrozen = false,
  });
}

/// Today's scheduled activities with status and goal progress.
final scheduledTodayProvider =
    FutureProvider<List<ScheduledActivityState>>((ref) async {
  final activitiesAsync = ref.watch(activeActivitiesProvider);
  final today = ref.watch(todayRangeProvider);
  final entryRepo = ref.watch(entryRepositoryProvider);
  final statusRepo = ref.watch(periodStatusRepositoryProvider);

  final activities = activitiesAsync.valueOrNull ?? [];
  final result = <ScheduledActivityState>[];

  // Process all activities in parallel for faster loading
  final userId = ref.watch(currentUserIdProvider);

  // Collect all activity-period pairs
  final activityPeriodPairs = <(Activity, ComputedPeriod)>[];
  for (final activity in activities) {
    if (activity.schedule == null) continue;
    final periods = _periodEngine.computePeriodsForDate(
      scheduleJson: activity.schedule,
      date: today.start,
      weekStartDay: ref.watch(userSettingsProvider).weekStartDay,
    );
    final seen = <String>{};
    for (final p in periods) {
      if (p.end.isBefore(today.start) || p.start.isAfter(today.end)) continue;
      final key = '${p.start.millisecondsSinceEpoch}_${p.end.millisecondsSinceEpoch}';
      if (seen.add(key)) activityPeriodPairs.add((activity, p));
    }
  }

  // Pre-fetch all today's entries for all activities in one batch
  final allTodayEntries = await entryRepo.getByDateRange(userId, today.start, today.end);
  final entriesByActivity = <String, List<Entry>>{};
  for (final e in allTodayEntries) {
    if (e.activityId != null) {
      entriesByActivity.putIfAbsent(e.activityId!, () => []).add(e);
    }
  }

  // Process each activity-period pair (now mostly synchronous since entries are pre-fetched)
  for (final (activity, period) in activityPeriodPairs) {
    final todayEntries = entriesByActivity[activity.id] ?? [];
    final hasEntries = todayEntries.isNotEmpty;

    // Check existing status
    final existingStatus = await statusRepo.getActivityPeriodStatus(
      userId, activity.id, period.start, period.end,
    );

    String status;
    if (existingStatus != null) {
      status = existingStatus.status;
    } else if (hasEntries) {
      status = 'completed';
    } else {
      status = 'pending';
    }

    // Evaluate primary goal
    GoalEvaluation? primaryGoalEval;
    if (activity.goals != null) {
      final goalEntries = todayEntries
          .map((e) => GoalEntry(
                id: e.id,
                loggedAt: e.loggedAt,
                fieldValues: e.fieldValues,
                periodStart: e.periodStart,
                periodEnd: e.periodEnd,
              ))
          .toList();
      final isFinalized = period.end.isBefore(DateTime.now());
      final evals = _goalEngine.evaluateGoals(
        goalsJson: activity.goals,
        period: period,
        periodEntries: goalEntries,
        isFinalized: isFinalized,
      );
      primaryGoalEval = evals.isEmpty ? null : evals.first;
    }

    result.add(ScheduledActivityState(
      activity: activity,
      period: period,
      status: status,
      primaryGoalEval: primaryGoalEval,
      streakCount: 0, // Streaks deferred to avoid N+1 queries
      streakFrozen: false,
    ));
  }

  // Deduplicate: only show one card per activity (keep first/best period)
  final deduped = <String, ScheduledActivityState>{};
  for (final item in result) {
    if (!deduped.containsKey(item.activity.id)) {
      deduped[item.activity.id] = item;
    }
  }

  final finalResult = deduped.values.toList();

  // Sort: in-progress first, then completed (faded)
  finalResult.sort((a, b) {
    const order = {'pending': 0, 'excused': 1, 'missed': 2, 'completed': 3};
    return (order[a.status] ?? 0).compareTo(order[b.status] ?? 0);
  });

  return finalResult;
});

// ═══════════════════════════════════════════════════════════════════
// SCHEDULED TODAY — Routines with periods that overlap today
// ═══════════════════════════════════════════════════════════════════

/// A scheduled routine with its computed completion status for today.
class ScheduledRoutineState {
  final Routine routine;
  final ComputedPeriod period;
  final RoutineCompletionResult completion;
  final String status; // 'pending', 'partial', 'completed'

  const ScheduledRoutineState({
    required this.routine,
    required this.period,
    required this.completion,
    required this.status,
  });
}

/// Today's scheduled routines with computed completion status.
final scheduledRoutinesTodayProvider =
    FutureProvider<List<ScheduledRoutineState>>((ref) async {
  final routineRepo = ref.watch(routineRepositoryProvider);
  final entryRepo = ref.watch(entryRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  final today = ref.watch(todayRangeProvider);

  final routines = await routineRepo.getByUser(userId);
  final result = <ScheduledRoutineState>[];

  for (final routine in routines) {
    if (routine.schedule == null || routine.isArchived) continue;

    final periods = _periodEngine.computePeriodsForDate(
      scheduleJson: routine.schedule,
      date: today.start,
      weekStartDay: ref.watch(userSettingsProvider).weekStartDay,
    );

    for (final period in periods) {
      if (period.end.isBefore(today.start) || period.start.isAfter(today.end)) continue;

      // Get entries for all activities in the sequence
      final activityIds = routine.activitySequence
          .map((s) => s['activity_id'] as String?)
          .whereType<String>()
          .toSet();

      final allEntries = <Entry>[];
      for (final activityId in activityIds) {
        final entries = await entryRepo.getByPeriod(userId, activityId, period.start, period.end);
        allEntries.addAll(entries);
      }

      final completion = _completionEngine.computeCompletion(
        activitySequence: routine.activitySequence,
        entriesForPeriod: allEntries,
      );

      result.add(ScheduledRoutineState(
        routine: routine,
        period: period,
        completion: completion,
        status: completion.status,
      ));
    }
  }

  // Sort: pending first, then partial, then completed
  result.sort((a, b) {
    const order = {'pending': 0, 'partial': 1, 'completed': 2};
    return (order[a.status] ?? 0).compareTo(order[b.status] ?? 0);
  });

  return result;
});

// ═══════════════════════════════════════════════════════════════════
// SUMMARY STATS
// ═══════════════════════════════════════════════════════════════════

/// Today's summary: total scheduled, tracked count, streak.
class HomeSummary {
  final int totalGoals;
  final int metGoals;
  final int allGoalsStreak;
  final bool streakFrozen;

  const HomeSummary({
    this.totalGoals = 0,
    this.metGoals = 0,
    this.allGoalsStreak = 0,
    this.streakFrozen = false,
  });

  double get progressPercent =>
      totalGoals > 0 ? metGoals / totalGoals : 0;
}

final homeSummaryProvider = FutureProvider<HomeSummary>((ref) async {
  final scheduledAsync = ref.watch(scheduledTodayProvider);
  final scheduled = scheduledAsync.valueOrNull ?? [];

  int total = 0;
  int met = 0;

  for (final s in scheduled) {
    if (s.primaryGoalEval != null) {
      total++;
      if (s.primaryGoalEval!.isMet) met++;
    } else if (s.activity.goals != null) {
      // Has goals but no evaluation yet
      total++;
      if (s.status == 'completed') met++;
    }
  }

  // Compute streak using day status rules:
  //   All Done → +1, Excused → skip (continue, no change),
  //   Pending → freeze (stop counting but don't reset),
  //   Missed → reset to 0
  int allGoalsStreak = 0;
  bool streakFrozen = false;

  final entryRepo = ref.watch(entryRepositoryProvider);
  final statusRepo = ref.watch(periodStatusRepositoryProvider);
  final activitiesAsync = ref.watch(activeActivitiesProvider);
  final allActivities = activitiesAsync.valueOrNull ?? [];
  final scheduledActivities = allActivities.where((a) => a.schedule != null).toList();
  final weekStartDay = ref.watch(userSettingsProvider).weekStartDay;

  // Start from today and walk backwards
  for (var daysBack = 0; daysBack <= 365; daysBack++) {
    final checkDate = DateTime.now().subtract(Duration(days: daysBack));
    final dayStart = DateTime(checkDate.year, checkDate.month, checkDate.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    int dayDone = 0;
    int dayExcused = 0;
    int dayMissed = 0;
    int dayPending = 0;
    int dayTotal = 0;

    final dayStatuses = await statusRepo.getActivityStatusesByDateRange(
      ref.watch(currentUserIdProvider), dayStart, dayEnd,
    );

    for (final activity in scheduledActivities) {
      final periods = _periodEngine.computePeriodsForDate(
        scheduleJson: activity.schedule,
        date: dayStart,
        weekStartDay: weekStartDay,
      );
      if (periods.isEmpty) continue;

      final period = periods.first;
      final periodEndDay = DateTime(
        period.end.year, period.end.month, period.end.day,
      );
      final effectiveEndDay = period.end.hour == 0 && period.end.minute == 0
          ? periodEndDay.subtract(const Duration(days: 1))
          : periodEndDay;
      if (effectiveEndDay != dayStart) continue;

      dayTotal++;

      // Check for linked entry
      final entries = await entryRepo.getByActivityAndDateRange(
        ref.watch(currentUserIdProvider), activity.id, dayStart, dayEnd,
      );
      if (entries.isNotEmpty) {
        dayDone++;
        continue;
      }

      // Check stored status
      final matchingStatus = dayStatuses.where((s) =>
        s.activityId == activity.id,
      ).firstOrNull;

      if (matchingStatus == null) {
        dayPending++;
      } else if (matchingStatus.status == 'excused') {
        dayExcused++;
      } else if (matchingStatus.status == 'missed') {
        dayMissed++;
      } else if (matchingStatus.status == 'completed') {
        dayDone++;
      } else {
        dayPending++;
      }
    }

    // No scheduled activities → skip day
    if (dayTotal == 0) continue;

    final dayStatus = _resolveDayStatus(
      done: dayDone, excused: dayExcused, missed: dayMissed, pending: dayPending,
    );

    switch (dayStatus) {
      case DayStatus.allDone:
        allGoalsStreak++;
      case DayStatus.excused:
        // Skip — don't increment, don't break
        continue;
      case DayStatus.pending:
        // Freeze — mark frozen but keep walking back to count previous days
        streakFrozen = true;
        continue;
      case DayStatus.missed:
        // Streak is broken — stop
        break;
      default:
        break;
    }

    // If we hit missed, stop walking back
    if (dayStatus == DayStatus.missed) break;
  }

  return HomeSummary(
    totalGoals: total,
    metGoals: met,
    allGoalsStreak: allGoalsStreak,
    streakFrozen: streakFrozen,
  );
});

// ═══════════════════════════════════════════════════════════════════
// WEEKLY HISTORY — 3-week grid for summary bottom sheet
// ═══════════════════════════════════════════════════════════════════

/// Status for a single day in the weekly history grid.
enum DayStatus {
  allDone,   // 🟢 Every period has a linked entry
  excused,   // 🔵 All resolved, no missed, at least 1 excused
  missed,    // 🔴 All resolved, at least 1 missed
  pending,   // ○ At least 1 period unresolved
  future,    // · Future day (not yet applicable)
  noData,    // No scheduled activities on this day
}

/// A day's computed status for the 3-week grid.
class DayHistoryEntry {
  final DateTime date;
  final DayStatus status;

  const DayHistoryEntry({required this.date, required this.status});
}

/// Computes the 3-week history grid (21 days ending today).
/// Each day gets a status based on whether all scheduled activities were completed.
final weeklyHistoryProvider = FutureProvider<List<DayHistoryEntry>>((ref) async {
  final entryRepo = ref.watch(entryRepositoryProvider);
  final activitiesAsync = ref.watch(activeActivitiesProvider);
  final statusRepo = ref.watch(periodStatusRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  final allActivities = activitiesAsync.valueOrNull ?? [];
  final scheduledActivities = allActivities.where((a) => a.schedule != null).toList();

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekStartDay = ref.watch(userSettingsProvider).weekStartDay;

  // Find the start of this week based on user's weekStartDay setting.
  // weekStartDay: 0=Sun, 1=Mon, ..., 6=Sat
  // Dart weekday: 1=Mon, ..., 7=Sun
  final dartWeekStart = weekStartDay == 0 ? 7 : weekStartDay;
  final todayWeekday = today.weekday;
  final daysFromWeekStart = (todayWeekday - dartWeekStart + 7) % 7;
  final thisWeekStart = today.subtract(Duration(days: daysFromWeekStart));
  final gridStart = thisWeekStart.subtract(const Duration(days: 14));
  final gridEnd = gridStart.add(const Duration(days: 21)); // 3 full weeks

  // Batch-fetch all entries and statuses for the 21-day range
  final allEntries = await entryRepo.getByDateRange(userId, gridStart, gridEnd);
  final allStatuses = await statusRepo.getActivityStatusesByDateRange(
    userId, gridStart, gridEnd,
  );

  final result = <DayHistoryEntry>[];

  for (var i = 0; i < 21; i++) {
    final day = gridStart.add(Duration(days: i));
    final dayEnd = day.add(const Duration(days: 1));

    // Future day
    if (day.isAfter(today)) {
      result.add(DayHistoryEntry(date: day, status: DayStatus.future));
      continue;
    }

    // Resolve each period's status for this day.
    // Possible per-period statuses: done, excused, missed, pending.
    int totalScheduled = 0;
    int doneCount = 0;
    int excusedCount = 0;
    int missedCount = 0;
    int pendingCount = 0;

    for (final activity in scheduledActivities) {
      final periods = _periodEngine.computePeriodsForDate(
        scheduleJson: activity.schedule,
        date: day,
        weekStartDay: weekStartDay,
      );
      if (periods.isEmpty) continue;

      // Only count this activity if its period ENDS on this day.
      final period = periods.first;
      final periodEndDay = DateTime(
        period.end.year, period.end.month, period.end.day,
      );
      final effectiveEndDay = period.end.hour == 0 && period.end.minute == 0
          ? periodEndDay.subtract(const Duration(days: 1))
          : periodEndDay;
      if (effectiveEndDay != day) continue;

      totalScheduled++;

      // Check if an entry is linked to this period
      final dayEntries = allEntries.where((e) =>
        e.activityId == activity.id &&
        !e.loggedAt.isBefore(day) &&
        e.loggedAt.isBefore(dayEnd),
      ).toList();

      if (dayEntries.isNotEmpty) {
        doneCount++;
        continue;
      }

      // Check for a stored status (excused, missed, completed)
      final matchingStatus = allStatuses.where((s) =>
        s.activityId == activity.id &&
        !s.periodStart.isAfter(dayEnd) &&
        !s.periodEnd.isBefore(day),
      ).firstOrNull;

      if (matchingStatus == null) {
        // No entry, no status — pending
        pendingCount++;
      } else if (matchingStatus.status == 'excused') {
        excusedCount++;
      } else if (matchingStatus.status == 'missed') {
        missedCount++;
      } else if (matchingStatus.status == 'completed') {
        doneCount++;
      } else {
        pendingCount++;
      }
    }

    if (totalScheduled == 0) {
      // Period engine found nothing — check DB for statuses/entries
      // (handles schedule version edge cases)
      final dayStatuses = allStatuses.where((s) =>
        !s.periodStart.isAfter(dayEnd) &&
        !s.periodEnd.isBefore(day),
      ).toList();
      final dayEntryCheck = allEntries.where((e) =>
        e.activityId != null &&
        !e.loggedAt.isBefore(day) &&
        e.loggedAt.isBefore(dayEnd),
      ).toList();

      if (dayStatuses.isEmpty && dayEntryCheck.isEmpty) {
        result.add(DayHistoryEntry(date: day, status: DayStatus.noData));
      } else {
        // Recount from DB records
        final dbDone = dayEntryCheck.isNotEmpty ? 1 : 0;
        final dbExcused = dayStatuses.where((s) => s.status == 'excused').length;
        final dbMissed = dayStatuses.where((s) => s.status == 'missed').length;
        final dbPending = dayStatuses.where((s) => s.status == 'pending').length;
        result.add(DayHistoryEntry(date: day, status: _resolveDayStatus(
          done: dbDone, excused: dbExcused, missed: dbMissed, pending: dbPending,
        )));
      }
    } else {
      result.add(DayHistoryEntry(date: day, status: _resolveDayStatus(
        done: doneCount, excused: excusedCount, missed: missedCount, pending: pendingCount,
      )));
    }
  }

  return result;
});

/// Resolve a day's grid status from per-period counts.
///
/// Priority rules:
///   1. Pending — at least 1 period is unresolved
///   2. All Done — every period has a linked entry
///   3. Excused — all resolved, no missed, at least 1 excused
///   4. Missed — all resolved, at least 1 missed
DayStatus _resolveDayStatus({
  required int done,
  required int excused,
  required int missed,
  required int pending,
}) {
  final total = done + excused + missed + pending;
  if (total == 0) return DayStatus.noData;

  // Rule 1: any pending → pending
  if (pending > 0) return DayStatus.pending;

  // Rule 2: all done → allDone
  if (done == total) return DayStatus.allDone;

  // Rule 3: no pending, no missed, at least 1 excused → excused
  if (missed == 0 && excused > 0) return DayStatus.excused;

  // Rule 4: no pending, at least 1 missed → missed
  return DayStatus.missed;
}
