// ═══════════════════════════════════════════════════════════════════
// GOAL_ENGINE.DART — Goal Evaluation Engine
// Evaluates whether goals are met for a period by examining entries.
// Supports: frequency, value, custom (aggregated, standing,
// consistency layer, dynamic target).
// See SPEC.md §10 for full specification.
// ═══════════════════════════════════════════════════════════════════

import '../engines/period_engine.dart';

/// Result of evaluating a single goal.
class GoalEvaluation {
  final String goalId;

  /// 'met', 'not_met', 'in_progress', 'excused'
  final String status;

  /// Current value (e.g., 3.2 for "3.2/5 km")
  final double? currentValue;

  /// Target value (e.g., 5.0 for "3.2/5 km")
  final double? targetValue;

  /// Display string (e.g., "3/5 this week", "3.2/5 km")
  final String? progressText;

  const GoalEvaluation({
    required this.goalId,
    required this.status,
    this.currentValue,
    this.targetValue,
    this.progressText,
  });

  bool get isMet => status == 'met';
  bool get isInProgress => status == 'in_progress';
  bool get isNotMet => status == 'not_met';
  bool get isExcused => status == 'excused';
}

/// A simplified entry representation for goal evaluation.
/// Decoupled from Drift/Supabase data classes.
class GoalEntry {
  final String id;
  final DateTime loggedAt;
  final Map<String, dynamic> fieldValues;
  final DateTime? periodStart;
  final DateTime? periodEnd;

  const GoalEntry({
    required this.id,
    required this.loggedAt,
    this.fieldValues = const {},
    this.periodStart,
    this.periodEnd,
  });
}

/// Parsed goal configuration from the JSONB.
class GoalConfig {
  final String id;
  final String mode; // 'frequency', 'value', 'custom'
  final String? fieldId;
  final String scope; // 'period', 'last_n_entries', 'last_n_days', etc.
  final int? scopeCount;
  final String? scopeUnit;
  final String aggregation; // 'sum', 'average', 'min', 'max', 'most_recent', 'count'
  final String comparison; // '=', '>', '<', '>=', '<=', 'between', 'not_between'
  final double? target;
  final double? targetTo; // For between/not_between
  final double? tolerance; // For approximate matching
  final int? consistency; // Last N periods to check
  final bool isPrimary;

  const GoalConfig({
    required this.id,
    required this.mode,
    this.fieldId,
    this.scope = 'period',
    this.scopeCount,
    this.scopeUnit,
    this.aggregation = 'count',
    this.comparison = '>=',
    this.target,
    this.targetTo,
    this.tolerance,
    this.consistency,
    this.isPrimary = false,
  });

  factory GoalConfig.fromJson(Map<String, dynamic> json) {
    return GoalConfig(
      id: json['id'] as String,
      mode: json['mode'] as String? ?? 'frequency',
      fieldId: json['field_id'] as String?,
      scope: json['scope'] as String? ?? 'period',
      scopeCount: json['scope_count'] as int?,
      scopeUnit: json['scope_unit'] as String?,
      aggregation: json['aggregation'] as String? ?? 'count',
      comparison: json['comparison'] as String? ?? '>=',
      target: _toDouble(json['target']),
      targetTo: _toDouble(json['target_to']),
      tolerance: _toDouble(json['tolerance']),
      consistency: json['consistency'] as int?,
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }

  static double? _toDouble(dynamic val) {
    if (val == null) return null;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }
}

/// The Goal Engine: evaluates goals against entry data.
class GoalEngine {
  const GoalEngine();

  /// Evaluate all goals for an activity in a specific period.
  ///
  /// [goalsJson] — the activity's goals JSONB (versioned).
  /// [period] — the period being evaluated.
  /// [periodEntries] — entries linked to this period.
  /// [isFinalized] — whether the period has ended.
  /// [allEntries] — all entries for this activity (for standing/rolling goals).
  List<GoalEvaluation> evaluateGoals({
    required Map<String, dynamic>? goalsJson,
    required ComputedPeriod period,
    required List<GoalEntry> periodEntries,
    required bool isFinalized,
    List<GoalEntry> allEntries = const [],
    List<PeriodGoalResult>? historicalResults,
  }) {
    if (goalsJson == null) return [];

    final goals = _parseGoals(goalsJson, period.start);
    if (goals.isEmpty) return [];

    return goals.map((goal) {
      return _evaluateGoal(
        goal: goal,
        period: period,
        periodEntries: periodEntries,
        isFinalized: isFinalized,
        allEntries: allEntries,
        historicalResults: historicalResults,
      );
    }).toList();
  }

  /// Evaluate a single goal. Public for targeted re-evaluation.
  GoalEvaluation evaluateSingleGoal({
    required GoalConfig goal,
    required ComputedPeriod period,
    required List<GoalEntry> periodEntries,
    required bool isFinalized,
    List<GoalEntry> allEntries = const [],
    List<PeriodGoalResult>? historicalResults,
  }) {
    return _evaluateGoal(
      goal: goal,
      period: period,
      periodEntries: periodEntries,
      isFinalized: isFinalized,
      allEntries: allEntries,
      historicalResults: historicalResults,
    );
  }

  /// Evaluate combined goals with AND/OR logic.
  GoalEvaluation evaluateCombined({
    required List<GoalEvaluation> results,
    required String combineMode, // 'all' (AND) or 'any' (OR)
  }) {
    if (results.isEmpty) {
      return const GoalEvaluation(goalId: 'combined', status: 'in_progress');
    }

    if (combineMode == 'any') {
      // OR: met if any goal is met
      if (results.any((r) => r.isMet)) {
        return const GoalEvaluation(goalId: 'combined', status: 'met');
      }
      if (results.any((r) => r.isInProgress)) {
        return const GoalEvaluation(goalId: 'combined', status: 'in_progress');
      }
      return const GoalEvaluation(goalId: 'combined', status: 'not_met');
    }

    // AND: met only if all goals are met (or excused)
    if (results.every((r) => r.isMet || r.isExcused)) {
      return const GoalEvaluation(goalId: 'combined', status: 'met');
    }
    if (results.any((r) => r.isNotMet)) {
      return const GoalEvaluation(goalId: 'combined', status: 'not_met');
    }
    return const GoalEvaluation(goalId: 'combined', status: 'in_progress');
  }

  // ═══════════════════════════════════════════════════════════════════
  // PRIVATE: Goal Evaluation
  // ═══════════════════════════════════════════════════════════════════

  GoalEvaluation _evaluateGoal({
    required GoalConfig goal,
    required ComputedPeriod period,
    required List<GoalEntry> periodEntries,
    required bool isFinalized,
    List<GoalEntry> allEntries = const [],
    List<PeriodGoalResult>? historicalResults,
  }) {
    // If consistency layer is set, delegate to consistency evaluation
    if (goal.consistency != null && goal.consistency! > 0) {
      return _evaluateWithConsistency(
        goal: goal,
        historicalResults: historicalResults ?? [],
      );
    }

    switch (goal.mode) {
      case 'frequency':
        return _evaluateFrequency(goal, periodEntries, isFinalized);
      case 'value':
        return _evaluateValue(goal, periodEntries, allEntries, isFinalized);
      case 'custom':
        return _evaluateCustom(goal, periodEntries, allEntries, isFinalized);
      default:
        return GoalEvaluation(goalId: goal.id, status: 'in_progress');
    }
  }

  /// Frequency goal: count entries in period vs target.
  GoalEvaluation _evaluateFrequency(
    GoalConfig goal,
    List<GoalEntry> entries,
    bool isFinalized,
  ) {
    final count = entries.length.toDouble();
    final target = goal.target ?? 1;
    final met = _compare(count, goal.comparison, target, goal.targetTo);

    return GoalEvaluation(
      goalId: goal.id,
      status: met ? 'met' : (isFinalized ? 'not_met' : 'in_progress'),
      currentValue: count,
      targetValue: target,
      progressText: '${count.toInt()}/${target.toInt()}',
    );
  }

  /// Value goal: aggregate a field across entries and compare.
  GoalEvaluation _evaluateValue(
    GoalConfig goal,
    List<GoalEntry> periodEntries,
    List<GoalEntry> allEntries,
    bool isFinalized,
  ) {
    final entries = _resolveScope(goal, periodEntries, allEntries);
    final values = _extractFieldValues(entries, goal.fieldId);

    if (values.isEmpty) {
      return GoalEvaluation(
        goalId: goal.id,
        status: isFinalized ? 'not_met' : 'in_progress',
        currentValue: 0,
        targetValue: goal.target,
        progressText: '0/${goal.target ?? 0}',
      );
    }

    final aggregated = _aggregate(values, goal.aggregation);
    final met = _compare(aggregated, goal.comparison, goal.target ?? 0,
        goal.targetTo);

    return GoalEvaluation(
      goalId: goal.id,
      status: met ? 'met' : (isFinalized ? 'not_met' : 'in_progress'),
      currentValue: aggregated,
      targetValue: goal.target,
      progressText: _formatProgress(aggregated, goal.target),
    );
  }

  /// Custom goal: handles all custom scope/aggregation/comparison combos.
  GoalEvaluation _evaluateCustom(
    GoalConfig goal,
    List<GoalEntry> periodEntries,
    List<GoalEntry> allEntries,
    bool isFinalized,
  ) {
    // Same logic as value but with more flexible scoping
    return _evaluateValue(goal, periodEntries, allEntries, isFinalized);
  }

  /// Consistency layer: check if the base goal was met in N of the last M periods.
  GoalEvaluation _evaluateWithConsistency({
    required GoalConfig goal,
    required List<PeriodGoalResult> historicalResults,
  }) {
    final n = goal.consistency!;
    final recent = historicalResults.take(n).toList();
    final metCount = recent.where((r) => r.met).length;
    final target = goal.target ?? 1;
    final met = _compare(metCount.toDouble(), goal.comparison, target,
        goal.targetTo);

    return GoalEvaluation(
      goalId: goal.id,
      status: met ? 'met' : 'not_met',
      currentValue: metCount.toDouble(),
      targetValue: target,
      progressText: '$metCount/${target.toInt()} periods',
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // PRIVATE: Helpers
  // ═══════════════════════════════════════════════════════════════════

  /// Resolve which entries to evaluate based on goal scope.
  List<GoalEntry> _resolveScope(
    GoalConfig goal,
    List<GoalEntry> periodEntries,
    List<GoalEntry> allEntries,
  ) {
    switch (goal.scope) {
      case 'period':
        return periodEntries;

      case 'last_n_entries':
        final n = goal.scopeCount ?? 10;
        final sorted = List<GoalEntry>.from(allEntries)
          ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
        return sorted.take(n).toList();

      case 'last_n_days':
      case 'last_n_weeks':
      case 'last_n_months':
        final cutoff = _scopeCutoff(goal);
        return allEntries
            .where((e) => e.loggedAt.isAfter(cutoff))
            .toList();

      case 'standing':
        // Most recent entry only
        if (allEntries.isEmpty) return [];
        final sorted = List<GoalEntry>.from(allEntries)
          ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
        return [sorted.first];

      default:
        return periodEntries;
    }
  }

  /// Calculate the cutoff date for rolling scopes.
  DateTime _scopeCutoff(GoalConfig goal) {
    final n = goal.scopeCount ?? 7;
    final now = DateTime.now();
    switch (goal.scope) {
      case 'last_n_days':
        return now.subtract(Duration(days: n));
      case 'last_n_weeks':
        return now.subtract(Duration(days: n * 7));
      case 'last_n_months':
        return DateTime(now.year, now.month - n, now.day);
      default:
        return now.subtract(Duration(days: n));
    }
  }

  /// Extract numeric values for a specific field from entries.
  List<double> _extractFieldValues(List<GoalEntry> entries, String? fieldId) {
    if (fieldId == null) return [];
    final values = <double>[];
    for (final entry in entries) {
      final val = entry.fieldValues[fieldId];
      if (val != null) {
        final d = _toDouble(val);
        if (d != null) values.add(d);
      }
    }
    return values;
  }

  /// Aggregate a list of values.
  double _aggregate(List<double> values, String aggregation) {
    if (values.isEmpty) return 0;
    switch (aggregation) {
      case 'sum':
        return values.fold(0.0, (a, b) => a + b);
      case 'average':
        return values.fold(0.0, (a, b) => a + b) / values.length;
      case 'min':
        return values.reduce((a, b) => a < b ? a : b);
      case 'max':
        return values.reduce((a, b) => a > b ? a : b);
      case 'count':
        return values.length.toDouble();
      case 'most_recent':
        return values.last;
      default:
        return values.fold(0.0, (a, b) => a + b);
    }
  }

  /// Compare a value against a target using the specified comparison.
  bool _compare(
      double value, String comparison, double target, double? targetTo) {
    switch (comparison) {
      case '=':
      case '==':
        return value == target;
      case '>':
        return value > target;
      case '<':
        return value < target;
      case '>=':
        return value >= target;
      case '<=':
        return value <= target;
      case 'between':
        return value >= target && value <= (targetTo ?? target);
      case 'not_between':
        return value < target || value > (targetTo ?? target);
      default:
        return value >= target;
    }
  }

  /// Parse goals from versioned JSONB, finding the active version.
  List<GoalConfig> _parseGoals(Map<String, dynamic> json, DateTime date) {
    final versions = json['versions'] as List<dynamic>?;
    if (versions == null || versions.isEmpty) {
      // Non-versioned: parse directly
      final goals = json['goals'] as List<dynamic>?;
      if (goals == null) return [];
      return goals.map((g) =>
          GoalConfig.fromJson(g as Map<String, dynamic>)).toList();
    }

    // Find the version effective on the given date
    for (final v in versions) {
      final vMap = v as Map<String, dynamic>;
      final from = DateTime.parse(vMap['effective_from'] as String);
      final to = vMap['effective_to'] != null
          ? DateTime.parse(vMap['effective_to'] as String)
          : null;

      if (!date.isBefore(from) && (to == null || date.isBefore(to))) {
        final goals = vMap['goals'] as List<dynamic>?;
        if (goals == null) return [];
        return goals.map((g) =>
            GoalConfig.fromJson(g as Map<String, dynamic>)).toList();
      }
    }

    return [];
  }

  String _formatProgress(double current, double? target) {
    if (target == null) return current.toStringAsFixed(1);

    // Use integers if both are whole numbers
    if (current == current.roundToDouble() &&
        target == target.roundToDouble()) {
      return '${current.toInt()}/${target.toInt()}';
    }
    return '${current.toStringAsFixed(1)}/${target.toStringAsFixed(1)}';
  }

  double? _toDouble(dynamic val) {
    if (val == null) return null;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }
}

/// Historical result for consistency layer evaluation.
class PeriodGoalResult {
  final ComputedPeriod period;
  final bool met;

  const PeriodGoalResult({required this.period, required this.met});
}
