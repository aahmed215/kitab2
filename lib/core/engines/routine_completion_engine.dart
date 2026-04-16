// ═══════════════════════════════════════════════════════════════════
// ROUTINE_COMPLETION_ENGINE.DART — Computes routine period status
// from activity entries.
//
// A routine's completion is derived from its activity sequence:
// - Each slot in the sequence needs at least 1 entry for the period.
// - If the same activity appears N times, N entries are needed.
// - Entries logged outside the routine execution also count.
//
// Status: 'completed' (all slots filled), 'partial' (some filled),
//         'pending' (none filled), 'missed'/'excused' (user decision).
// ═══════════════════════════════════════════════════════════════════

import '../../data/models/entry.dart';

/// Result of computing a routine's completion for a single period.
class RoutineCompletionResult {
  /// How many sequence slots are satisfied.
  final int slotsFilled;

  /// Total sequence slots.
  final int slotsTotal;

  /// Computed status: 'completed', 'partial', 'pending'.
  final String status;

  /// Per-activity breakdown: activityId → (required, available).
  final Map<String, ({int required, int available})> perActivity;

  const RoutineCompletionResult({
    required this.slotsFilled,
    required this.slotsTotal,
    required this.status,
    required this.perActivity,
  });

  double get progressPercent => slotsTotal > 0 ? slotsFilled / slotsTotal : 0;
}

/// Stateless engine that computes routine completion from activity entries.
class RoutineCompletionEngine {
  const RoutineCompletionEngine();

  /// Compute the routine's completion status for a period.
  ///
  /// [activitySequence] — the routine's activity_sequence JSONB:
  ///   [{"activity_id": "uuid", "sort_order": 0}, ...]
  ///
  /// [entriesForPeriod] — all entries (across all activities) that
  ///   fall within the period. The engine filters by activity ID.
  RoutineCompletionResult computeCompletion({
    required List<Map<String, dynamic>> activitySequence,
    required List<Entry> entriesForPeriod,
  }) {
    if (activitySequence.isEmpty) {
      return const RoutineCompletionResult(
        slotsFilled: 0,
        slotsTotal: 0,
        status: 'completed',
        perActivity: {},
      );
    }

    // Count how many slots each activity has in the sequence.
    // e.g., Drive appears at slot 2 and slot 8 → required: 2
    final requiredPerActivity = <String, int>{};
    for (final seq in activitySequence) {
      final activityId = seq['activity_id'] as String? ?? '';
      requiredPerActivity[activityId] = (requiredPerActivity[activityId] ?? 0) + 1;
    }

    // Count how many entries exist per activity in this period.
    final availablePerActivity = <String, int>{};
    for (final entry in entriesForPeriod) {
      if (entry.activityId == null) continue;
      if (requiredPerActivity.containsKey(entry.activityId)) {
        availablePerActivity[entry.activityId!] =
            (availablePerActivity[entry.activityId!] ?? 0) + 1;
      }
    }

    // Compute filled slots: for each activity, min(available, required).
    int slotsFilled = 0;
    final perActivity = <String, ({int required, int available})>{};

    for (final entry in requiredPerActivity.entries) {
      final activityId = entry.key;
      final required = entry.value;
      final available = availablePerActivity[activityId] ?? 0;
      final filled = available >= required ? required : available;
      slotsFilled += filled;
      perActivity[activityId] = (required: required, available: available);
    }

    final slotsTotal = activitySequence.length;
    final status = slotsFilled == slotsTotal
        ? 'completed'
        : slotsFilled > 0
            ? 'partial'
            : 'pending';

    return RoutineCompletionResult(
      slotsFilled: slotsFilled,
      slotsTotal: slotsTotal,
      status: status,
      perActivity: perActivity,
    );
  }
}
