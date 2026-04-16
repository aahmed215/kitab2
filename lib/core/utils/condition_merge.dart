// ═══════════════════════════════════════════════════════════════════
// CONDITION_MERGE.DART — Smart condition creation with merging
// When creating a condition from a preset, checks if an adjacent
// or overlapping condition of the same preset already exists.
// If so, extends it instead of creating a new record.
// ═══════════════════════════════════════════════════════════════════

import 'package:uuid/uuid.dart';
import '../../data/models/condition.dart';
import '../../data/repositories/condition_repository.dart';

const _uuid = Uuid();

/// Create or extend a condition for a given date range.
/// If an existing condition with the same preset overlaps or is adjacent,
/// extends it to cover the new range. Otherwise creates a new one.
/// Returns the condition ID (new or existing).
Future<String> createOrExtendCondition({
  required ConditionRepository repo,
  required String userId,
  required String presetId,
  required String label,
  required String emoji,
  required DateTime startDate,
  DateTime? endDate,
}) async {
  // Get all conditions for this user
  final allConditions = await repo.getByUser(userId);

  // Find conditions with the same preset that overlap or are adjacent
  final samePreset = allConditions.where((c) => c.presetId == presetId).toList();

  for (final existing in samePreset) {
    final existStart = DateTime(existing.startDate.year, existing.startDate.month, existing.startDate.day);
    final existEnd = existing.endDate != null
        ? DateTime(existing.endDate!.year, existing.endDate!.month, existing.endDate!.day)
        : null;
    final newStart = DateTime(startDate.year, startDate.month, startDate.day);
    final newEnd = endDate != null
        ? DateTime(endDate.year, endDate.month, endDate.day)
        : null;

    // Check if adjacent or overlapping
    // Adjacent: existing ends day before new starts, or new ends day before existing starts
    // Overlapping: any date overlap
    final existEndDay = existEnd ?? DateTime(2099, 12, 31); // Active = far future
    final newEndDay = newEnd ?? DateTime(2099, 12, 31);

    final isAdjacent = existEndDay.add(const Duration(days: 1)).isAtSameMomentAs(newStart) ||
        newEndDay.add(const Duration(days: 1)).isAtSameMomentAs(existStart);
    final isOverlapping = !existEndDay.isBefore(newStart) && !newEndDay.isBefore(existStart);

    if (isAdjacent || isOverlapping) {
      // Extend the existing condition to cover both ranges
      final mergedStart = existStart.isBefore(newStart) ? existStart : newStart;

      DateTime? mergedEnd;
      if (existEnd == null || newEnd == null) {
        mergedEnd = null; // One of them is active → merged is active
      } else {
        mergedEnd = existEndDay.isAfter(newEndDay) ? existEnd : endDate;
      }

      await repo.saveCondition(existing.copyWith(
        startDate: mergedStart,
        endDate: mergedEnd,
      ));

      return existing.id;
    }
  }

  // No overlap — create new condition
  final newCondition = Condition(
    id: _uuid.v4(),
    userId: userId,
    presetId: presetId,
    label: label,
    emoji: emoji,
    startDate: startDate,
    endDate: endDate,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  await repo.saveCondition(newCondition);
  return newCondition.id;
}

/// Represents the chain boundaries of a merged condition group.
class ConditionChain {
  /// The earliest startDate across the chain (day-truncated).
  final DateTime chainStart;

  /// The latest endDate across the chain (day-truncated), or null if
  /// the chain's final record is still active.
  final DateTime? chainEnd;

  /// The total records forming the chain (includes the input condition).
  final List<Condition> records;

  const ConditionChain({
    required this.chainStart,
    required this.chainEnd,
    required this.records,
  });
}

/// Find the chain that contains [condition] by walking forward/backward
/// through [allConditions] using the same adjacency rule as the merge:
///   Two records are chained if one's endDate + 1 day ≥ other's startDate,
///   AND they don't have a gap between them.
///
/// An active record (endDate == null) ends the forward walk — nothing can
/// come after an active condition.
ConditionChain findConditionChain(Condition condition, List<Condition> allConditions) {
  final samePreset = allConditions
      .where((other) => other.presetId == condition.presetId && other.deletedAt == null)
      .toList()
    ..sort((a, b) => a.startDate.compareTo(b.startDate));

  final chain = <Condition>[condition];

  // Walk backwards: find earlier records whose endDate is adjacent to
  // the chain's earliest startDate
  while (true) {
    final earliestStart = DateTime(
      chain.first.startDate.year,
      chain.first.startDate.month,
      chain.first.startDate.day,
    );
    Condition? prior;
    for (final other in samePreset) {
      if (chain.any((e) => e.id == other.id)) continue;
      final otherEndRaw = other.endDate ?? other.startDate;
      final otherEnd = DateTime(
        otherEndRaw.year, otherEndRaw.month, otherEndRaw.day,
      );
      final dayAfterOtherEnd = otherEnd.add(const Duration(days: 1));
      // Adjacent: day-after-other-end is on or after chain's earliest start,
      // AND other's end is on or before chain's earliest start
      if (!dayAfterOtherEnd.isBefore(earliestStart) &&
          !otherEnd.isAfter(earliestStart)) {
        if (prior == null ||
            (prior.endDate ?? prior.startDate)
                .isBefore(other.endDate ?? other.startDate)) {
          prior = other;
        }
      }
    }
    if (prior == null) break;
    chain.insert(0, prior);
  }

  // Walk forwards: stop at active record (endDate == null)
  while (chain.last.endDate != null) {
    final latestEnd = DateTime(
      chain.last.endDate!.year,
      chain.last.endDate!.month,
      chain.last.endDate!.day,
    );
    final dayAfterLatestEnd = latestEnd.add(const Duration(days: 1));
    Condition? next;
    for (final other in samePreset) {
      if (chain.any((e) => e.id == other.id)) continue;
      final otherStart = DateTime(
        other.startDate.year, other.startDate.month, other.startDate.day,
      );
      if (!otherStart.isAfter(dayAfterLatestEnd) &&
          !otherStart.isBefore(latestEnd)) {
        if (next == null || other.startDate.isBefore(next.startDate)) {
          next = other;
        }
      }
    }
    if (next == null) break;
    chain.add(next);
  }

  final chainStart = DateTime(
    chain.first.startDate.year,
    chain.first.startDate.month,
    chain.first.startDate.day,
  );
  final DateTime? chainEnd = chain.last.endDate != null
      ? DateTime(
          chain.last.endDate!.year,
          chain.last.endDate!.month,
          chain.last.endDate!.day,
        )
      : null;
  return ConditionChain(
    chainStart: chainStart,
    chainEnd: chainEnd,
    records: chain,
  );
}
