// ═══════════════════════════════════════════════════════════════════
// SCHEDULE_MIGRATION_ENGINE.DART — Retroactive Schedule Reprocessing
// Handles the full retroactive rewrite when a user changes an
// activity's schedule and chooses to apply it retroactively.
//
// Steps:
//   1. Save old missed statuses for carry-forward
//   2. Unlink all entries from old periods
//   3. Delete all period/goal statuses
//   4. Generate new periods from new schedule
//   5. Re-link entries to new periods
//   6. Carry forward missed/excused statuses
// ═══════════════════════════════════════════════════════════════════

import 'package:uuid/uuid.dart';
import '../../data/models/entry.dart';
import '../../data/models/period_status.dart';
import '../../data/repositories/entry_repository.dart';
import '../../data/repositories/period_status_repository.dart';
import 'period_engine.dart';

const _uuid = Uuid();

/// Result of a schedule migration.
class MigrationResult {
  final int periodsCreated;
  final int entriesLinked;
  final int entriesOrphaned;
  final int periodsMissed;
  final int periodsPending;

  const MigrationResult({
    this.periodsCreated = 0,
    this.entriesLinked = 0,
    this.entriesOrphaned = 0,
    this.periodsMissed = 0,
    this.periodsPending = 0,
  });

  @override
  String toString() =>
      '$periodsCreated periods, $entriesLinked linked, $entriesOrphaned orphaned, '
      '$periodsMissed missed, $periodsPending pending';
}

/// Handles retroactive schedule migration for an activity.
class ScheduleMigrationEngine {
  final PeriodEngine _periodEngine;

  const ScheduleMigrationEngine({
    PeriodEngine periodEngine = const PeriodEngine(),
  }) : _periodEngine = periodEngine;

  /// Run a full retroactive migration.
  ///
  /// Rules:
  ///   - Link existing entries to new periods (automatic — we can compute this)
  ///   - Preserve explicit user-recorded statuses (missed/excused) when the
  ///     new period fully contains the old status's date range
  ///   - NEVER infer statuses from conditions, schedule overlap, etc.
  ///     An active condition during a period does NOT imply the user
  ///     wanted that period excused — they have to explicitly mark it.
  ///
  /// [recalculateExpectedTimes] — when true, iterates through all re-linked
  /// entries and recalculates their expected_start / expected_end based on
  /// the new schedule's time window config and the entry's location.
  Future<MigrationResult> migrateRetroactive({
    required String userId,
    required String activityId,
    required Map<String, dynamic> newScheduleJson,
    required EntryRepository entryRepo,
    required PeriodStatusRepository statusRepo,
    bool recalculateExpectedTimes = false,
    @Deprecated('No longer used — conditions are not consulted during migration')
    dynamic conditionRepo,
    @Deprecated('No longer used — periods are full calendar days')
    Map<String, DateTime> Function(DateTime)? prayerTimeResolver,
  }) async {
    // ─── 1. Fetch existing data before deletion ───
    final oldStatuses = await statusRepo.getActivityStatusHistory(userId, activityId);
    // Preserve any EXPLICIT user-recorded status (missed or excused) from
    // the old schedule. We'll try to carry these forward when the new
    // schedule still covers that period range.
    final preservableStatuses = oldStatuses.where((s) =>
      s.status == 'missed' || s.status == 'excused',
    ).toList();
    final allEntries = await entryRepo.getByActivityAndDateRange(
      userId, activityId, DateTime(2020), DateTime.now().add(const Duration(days: 1)),
    );

    // ─── 2. Unlink all entries from old periods ───
    await entryRepo.unlinkAllForActivity(userId, activityId);

    // ─── 3. Delete all period/goal statuses ───
    await statusRepo.deleteAllForActivity(userId, activityId);
    await statusRepo.deleteAllGoalStatusesForActivity(userId, activityId);

    // ─── 4. Generate new periods ───
    final now = DateTime.now();
    final newPeriods = _periodEngine.computePeriods(
      scheduleJson: newScheduleJson,
      queryStart: DateTime(2020),
      queryEnd: now,
    );

    // Deduplicate and filter to past/current only
    final seen = <String>{};
    final uniquePeriods = newPeriods.where((p) {
      if (p.start.isAfter(now)) return false;
      final key = '${p.start.millisecondsSinceEpoch}_${p.end.millisecondsSinceEpoch}';
      return seen.add(key);
    }).toList();

    int entriesLinked = 0;
    int entriesOrphaned = 0;
    int periodsMissed = 0;
    int periodsPending = 0;

    // Track which entries have been linked (by ID) to prevent double-linking.
    // The in-memory allEntries list isn't mutated by entryRepo.save().
    final linkedEntryIds = <String>{};

    // ─── 5. Process each new period ───
    for (final period in uniquePeriods) {
      // 5a. Find entries that belong to this period
      final matchingEntry = _findBestEntry(allEntries, period, linkedEntryIds);

      if (matchingEntry != null) {
        // Link the entry to this period.
        final linked = matchingEntry.copyWith(
          periodStart: period.start,
          periodEnd: period.end,
          linkType: 'auto',
        );
        await entryRepo.save(linked);
        linkedEntryIds.add(matchingEntry.id);
        entriesLinked++;
        continue;
      }

      // 5b. Preserve an explicit user-recorded status (missed/excused) if
      // the new period is fully contained in an old status's date range.
      // This keeps the user's prior actions intact across schedule changes.
      final preserved = _findContainedStatus(period, preservableStatuses);
      if (preserved != null) {
        await statusRepo.saveActivityStatus(ActivityPeriodStatus(
          id: _uuid.v4(),
          userId: userId,
          activityId: activityId,
          periodStart: period.start,
          periodEnd: period.end,
          status: preserved.status,
          conditionId: preserved.conditionId,
          resolvedAt: preserved.resolvedAt,
          createdAt: now,
          updatedAt: now,
        ));
        if (preserved.status == 'missed') periodsMissed++;
        continue;
      }

      // 5c. Otherwise → pending (no status record; absence = pending)
      periodsPending++;
    }

    // Count orphaned entries (not linked to any new period)
    final relinkedEntries = await entryRepo.getByActivityAndDateRange(
      userId, activityId, DateTime(2020), DateTime.now().add(const Duration(days: 1)),
    );
    entriesOrphaned = relinkedEntries.where((e) => e.periodStart == null).length;

    // ─── 6. Recalculate expected times if requested ───
    if (recalculateExpectedTimes) {
      // TODO: Implement per-entry expected time recalculation.
      // For each re-linked entry:
      //   - If entry has activity_location_lat/lng in fieldValues:
      //       Build a prayer resolver from that location, call
      //       PeriodEngine.resolveExpectedTimes() with the new schedule's
      //       time window config, the entry's date, and the resolver.
      //       Update fieldValues with new expected_start / expected_end.
      //   - If entry does NOT have activity_location:
      //       Set expected_start and expected_end to null in fieldValues.
      //   - Save each modified entry via entryRepo.save().
    }

    return MigrationResult(
      periodsCreated: uniquePeriods.length,
      entriesLinked: entriesLinked,
      entriesOrphaned: entriesOrphaned,
      periodsMissed: periodsMissed,
      periodsPending: periodsPending,
    );
  }

  /// Find the best entry to link to a period.
  ///
  /// Since periods are now full calendar days (midnight to midnight),
  /// matching is simple: check if the entry's reference time falls on
  /// the same calendar day as the period's start date.
  /// Returns the earliest matching entry, or null.
  Entry? _findBestEntry(
      List<Entry> entries, ComputedPeriod period, Set<String> alreadyLinked) {
    final periodDay = DateTime(period.start.year, period.start.month, period.start.day);
    final matching = <Entry>[];

    for (final entry in entries) {
      if (alreadyLinked.contains(entry.id)) continue;

      // Reference time: start_time field if available, otherwise loggedAt
      DateTime refTime = entry.loggedAt;
      final startTimeValue = entry.fieldValues['start_time'];
      if (startTimeValue is String) {
        final parsed = DateTime.tryParse(startTimeValue);
        if (parsed != null) refTime = parsed.toLocal();
      }

      final entryDay = DateTime(refTime.year, refTime.month, refTime.day);
      if (entryDay == periodDay) {
        matching.add(entry);
      }
    }

    if (matching.isEmpty) return null;

    // Return the earliest
    matching.sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    return matching.first;
  }

  /// Find an old status record whose date range fully contains [newPeriod].
  /// Used to carry forward missed/excused statuses across schedule migrations.
  ActivityPeriodStatus? _findContainedStatus(
      ComputedPeriod newPeriod, List<ActivityPeriodStatus> oldStatuses) {
    for (final old in oldStatuses) {
      if (!newPeriod.start.isBefore(old.periodStart) &&
          !newPeriod.end.isAfter(old.periodEnd)) {
        return old;
      }
    }
    return null;
  }
}
