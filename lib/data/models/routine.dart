// ═══════════════════════════════════════════════════════════════════
// ROUTINE.DART — Routine Data Models
// A routine is a sequence of activity templates for habit stacking.
// Maps to `routines` and `routine_entries` tables.
// See SPEC.md §6 for full specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:freezed_annotation/freezed_annotation.dart';

part 'routine.freezed.dart';
part 'routine.g.dart';

/// A routine template — groups activity templates into a sequence.
@freezed
class Routine with _$Routine {
  const factory Routine({
    required String id,
    required String userId,
    String? categoryId,

    /// Routine name — unique per user (case-insensitive)
    required String name,

    String? description,
    @Default(false) bool isArchived,
    @Default(false) bool isPrivate,

    /// Ordered array of activity template IDs
    /// [{ "activity_id": "uuid", "sort_order": 1 }, ...]
    @Default([]) List<Map<String, dynamic>> activitySequence,

    /// Schedule (same versioned structure as activities)
    Map<String, dynamic>? schedule,

    /// Goals (same versioned structure as activities)
    /// Limited to: start time, end time, active duration, activities completed
    Map<String, dynamic>? goals,

    String? primaryGoalId,

    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _Routine;

  factory Routine.fromJson(Map<String, dynamic> json) =>
      _$RoutineFromJson(json);
}

/// A routine session — one execution of a routine.
/// Wraps individual activity entries created during the routine flow.
@freezed
class RoutineEntry with _$RoutineEntry {
  const factory RoutineEntry({
    required String id,
    required String userId,
    required String routineId,

    /// Derived from first activity entry's start time
    DateTime? startedAt,

    /// Derived from last activity entry's end time (null if in progress)
    DateTime? endedAt,

    /// Sum of all completed activity durations (serialized as string)
    String? activeDuration,

    /// Sum of gaps between consecutive activities
    String? idleDuration,

    /// active + idle
    String? totalDuration,

    /// Count of completed activities in this session
    @Default(0) int activitiesCompleted,

    /// Total activities in the routine at time of execution
    @Default(0) int activitiesTotal,

    /// Frozen routine period boundaries
    DateTime? periodStart,
    DateTime? periodEnd,

    /// Routine status: 'in_progress', 'completed', 'partial',
    /// 'missed', 'excused', 'pending'
    @Default('pending') String status,

    /// Linked condition (when status = 'excused')
    String? conditionId,

    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _RoutineEntry;

  factory RoutineEntry.fromJson(Map<String, dynamic> json) =>
      _$RoutineEntryFromJson(json);
}
