// ═══════════════════════════════════════════════════════════════════
// LINKAGE_ENGINE.DART — Two-Layer Entry Linkage Engine
// Determines which period an entry belongs to.
//
// Layer 1: Template link (entry.activity_id) — which activity
// Layer 2: Period link (entry.period_start/end) — which period
//
// When an entry is linked to a period, the period boundaries
// are FROZEN onto the entry record (stored as UTC). This
// survives timezone changes, schedule edits, and travel.
//
// See SPEC.md §8 for full specification.
// ═══════════════════════════════════════════════════════════════════

import 'period_engine.dart';

/// Result of a linkage operation.
class LinkageResult {
  /// The period this entry was linked to (null if no match found).
  final ComputedPeriod? linkedPeriod;

  /// How the link was established.
  final String? linkType; // 'explicit', 'auto', null

  /// Whether a pending period was detected (needs attention).
  final bool hasPendingPeriod;

  const LinkageResult({
    this.linkedPeriod,
    this.linkType,
    this.hasPendingPeriod = false,
  });
}

/// The Linkage Engine: connects entries to their schedule periods.
class LinkageEngine {
  final PeriodEngine _periodEngine;

  const LinkageEngine({PeriodEngine periodEngine = const PeriodEngine()})
      : _periodEngine = periodEngine;

  /// Auto-link an entry to the most appropriate period.
  ///
  /// [loggedAt] — when the activity was performed.
  /// [scheduleJson] — the activity's schedule JSONB.
  /// [weekStartDay] — user's week start day setting.
  /// [prayerTimeResolver] — for dynamic time windows.
  ///
  /// Returns the matching period (if any) for the entry's timestamp.
  LinkageResult autoLink({
    required DateTime loggedAt,
    required Map<String, dynamic>? scheduleJson,
    int weekStartDay = 0,
    Map<String, DateTime> Function(DateTime)? prayerTimeResolver,
  }) {
    if (scheduleJson == null) {
      return const LinkageResult(linkType: null, hasPendingPeriod: false);
    }

    // Find the period that contains the logged timestamp.
    // prayerTimeResolver is ignored — periods are always full calendar days.
    final period = _periodEngine.findPeriodForTimestamp(
      scheduleJson: scheduleJson,
      timestamp: loggedAt,
      weekStartDay: weekStartDay,
    );

    if (period != null) {
      return LinkageResult(
        linkedPeriod: period,
        linkType: 'auto',
      );
    }

    // No matching period — entry is orphaned (exists but not linked)
    return const LinkageResult(linkType: null, hasPendingPeriod: false);
  }

  /// Explicitly link an entry to a specific period (user chose which period).
  LinkageResult explicitLink({
    required ComputedPeriod period,
  }) {
    return LinkageResult(
      linkedPeriod: period,
      linkType: 'explicit',
    );
  }

  /// Find all periods in a date range that have no linked entries.
  /// These are "pending" periods that need attention.
  ///
  /// [scheduleJson] — the activity's schedule.
  /// [queryStart] / [queryEnd] — range to check.
  /// [linkedPeriods] — set of (periodStart, periodEnd) tuples already linked.
  List<ComputedPeriod> findPendingPeriods({
    required Map<String, dynamic>? scheduleJson,
    required DateTime queryStart,
    required DateTime queryEnd,
    required Set<(DateTime, DateTime)> linkedPeriods,
    int weekStartDay = 0,
    Map<String, DateTime> Function(DateTime)? prayerTimeResolver,
  }) {
    // prayerTimeResolver is ignored — periods are always full calendar days.
    final allPeriods = _periodEngine.computePeriods(
      scheduleJson: scheduleJson,
      queryStart: queryStart,
      queryEnd: queryEnd,
      weekStartDay: weekStartDay,
    );

    // Filter out periods that already have linked entries
    return allPeriods
        .where((p) => !linkedPeriods.contains((p.start, p.end)))
        .where((p) => p.end.isBefore(DateTime.now())) // Only past periods
        .toList();
  }

  /// Determine which periods need status evaluation after an entry change.
  /// Returns all periods in the entry's vicinity that might be affected.
  List<ComputedPeriod> getAffectedPeriods({
    required DateTime loggedAt,
    required Map<String, dynamic>? scheduleJson,
    int weekStartDay = 0,
    Map<String, DateTime> Function(DateTime)? prayerTimeResolver,
  }) {
    // Check ±1 day to handle midnight crossovers
    final start = loggedAt.subtract(const Duration(days: 1));
    final end = loggedAt.add(const Duration(days: 2));

    // prayerTimeResolver is ignored — periods are always full calendar days.
    return _periodEngine.computePeriods(
      scheduleJson: scheduleJson,
      queryStart: start,
      queryEnd: end,
      weekStartDay: weekStartDay,
    );
  }
}
