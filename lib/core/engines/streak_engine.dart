// ═══════════════════════════════════════════════════════════════════
// STREAK_ENGINE.DART — Streak Calculation Engine
// Computes current streak, best streak, and frozen streak state.
//
// Three streak types:
//  1. Per-activity streak (did I do this activity each period?)
//  2. Per-goal streak (did I meet this specific goal each period?)
//  3. All-goals day streak (did I meet ALL goals across ALL
//     activities today?)
//
// Rules:
//  - Completed/Met → streak +1
//  - Excused → streak preserved (no change, frozen 🧊)
//  - Missed/Not Met → streak reset to 0
//  - Pending → no effect (period isn't over yet)
//
// See SPEC.md §13 for full specification.
// ═══════════════════════════════════════════════════════════════════

/// Result of a streak calculation.
class StreakResult {
  /// Current consecutive streak count.
  final int current;

  /// Best (longest) streak ever achieved.
  final int best;

  /// Whether the streak is currently "frozen" (last period was excused).
  /// Displays 🧊 instead of 🔥.
  final bool isFrozen;

  /// Whether the current period is still pending (not yet resolved).
  /// Displays 🧊 (frozen/pending state) — user still has time.
  final bool isPending;

  const StreakResult({
    required this.current,
    required this.best,
    this.isFrozen = false,
    this.isPending = false,
  });

  /// Display emoji: 🔥 for active streak, 🧊 for frozen/pending.
  String get emoji => (isFrozen || isPending) ? '🧊' : '🔥';

  @override
  String toString() =>
      'Streak(current: $current, best: $best, frozen: $isFrozen)';
}

/// The Streak Engine: computes streaks from period status history.
class StreakEngine {
  const StreakEngine();

  /// Calculate streak from a list of period statuses, most recent first.
  ///
  /// [statuses] — list of status strings, ordered most-recent first.
  ///   Valid values: 'completed', 'met', 'missed', 'not_met', 'excused', 'pending'
  ///
  /// The engine walks backward from the most recent period:
  ///  - 'completed' / 'met' → increments current streak
  ///  - 'excused' → preserves streak (no change), marks frozen
  ///  - 'missed' / 'not_met' → stops counting (resets for best calculation)
  ///  - 'pending' → skip (period isn't over yet)
  StreakResult calculate(List<String> statuses) {
    if (statuses.isEmpty) {
      return const StreakResult(current: 0, best: 0);
    }

    int current = 0;
    int best = 0;
    int running = 0;
    bool isFrozen = false;
    bool isPending = false;
    bool foundFirstResolved = false;

    for (final status in statuses) {
      if (status == 'pending') {
        // Current period not yet resolved
        if (!foundFirstResolved) isPending = true;
        continue;
      }

      foundFirstResolved = true;

      if (status == 'completed' || status == 'met') {
        running++;
        if (!foundFirstResolved || running > 0) {
          // Still counting current streak
        }
      } else if (status == 'excused') {
        // Preserve — don't increment, don't reset
        if (running == 0 && current == 0) {
          isFrozen = true;
        }
      } else {
        // 'missed' or 'not_met' — streak breaks here
        if (running > best) best = running;
        if (current == 0 && !isFrozen) {
          // This is where we stop counting current
          current = running;
        }
        running = 0;
      }
    }

    // Finalize
    if (running > best) best = running;
    if (current == 0) current = running;

    return StreakResult(
      current: current,
      best: best,
      isFrozen: isFrozen,
      isPending: isPending,
    );
  }

  /// Simplified streak calculation for the per-activity streak.
  /// Takes a list of ActivityPeriodStatus-like data (status strings),
  /// ordered most-recent first.
  StreakResult calculateActivityStreak(List<String> periodStatuses) {
    return calculate(periodStatuses);
  }

  /// Calculate per-goal streak from GoalPeriodStatus-like data.
  /// Takes status strings: 'met', 'not_met', 'excused'.
  StreakResult calculateGoalStreak(List<String> goalStatuses) {
    return calculate(goalStatuses);
  }

  /// Calculate the all-goals day streak.
  ///
  /// [dailyResults] — for each day (most recent first), whether ALL
  ///   goals across ALL activities were met that day.
  ///   Each entry is true (all met), false (any not met), or null (excused day).
  StreakResult calculateAllGoalsDayStreak(List<bool?> dailyResults) {
    final statuses = dailyResults.map((r) {
      if (r == null) return 'excused';
      return r ? 'met' : 'not_met';
    }).toList();
    return calculate(statuses);
  }
}
