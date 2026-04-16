// ═══════════════════════════════════════════════════════════════════
// GOAL_CONFIG_SECTION.DART — Activity Goals Configuration
// Three goal types:
//   Completion — "Did I do it X times per period?" (requires schedule)
//   Target — "Did field X meet target Y?"
//   Combined — "Did multiple conditions together pass?"
// See SPEC §5.5 for full specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/kitab_theme.dart';
import '../../../../core/widgets/map_location_picker.dart';
import 'field_config_section.dart';

const _uuid = Uuid();

// ═══════════════════════════════════════════════════════════════════
// FIELD TYPE → AVAILABLE CALCULATIONS
// ═══════════════════════════════════════════════════════════════════

List<({String value, String label})> calculationsForFieldType(FieldType type) {
  switch (type) {
    case FieldType.number:
    case FieldType.range:
    case FieldType.starRating:
    case FieldType.mood:
    case FieldType.duration:
      return [
        (value: 'sum', label: 'Sum'),
        (value: 'average', label: 'Average'),
        (value: 'min', label: 'Lowest'),
        (value: 'max', label: 'Highest'),
        (value: 'count', label: 'Count'),
        (value: 'mode', label: 'Most frequent'),
      ];
    case FieldType.startTime:
    case FieldType.endTime:
      return [
        (value: 'average', label: 'Average'),
        (value: 'min', label: 'Earliest'),
        (value: 'max', label: 'Latest'),
        (value: 'count', label: 'Count'),
        (value: 'mode', label: 'Most frequent'),
      ];
    case FieldType.text:
    case FieldType.yesNo:
    case FieldType.singleChoice:
      return [
        (value: 'count', label: 'Count'),
        (value: 'mode', label: 'Most frequent'),
      ];
    case FieldType.multipleChoice:
    case FieldType.list:
      return [
        (value: 'count', label: 'Count'),
        (value: 'mode', label: 'Most frequent'),
      ];
    case FieldType.location:
      return [
        (value: 'count', label: 'Count'),
      ];
  }
}

// ═══════════════════════════════════════════════════════════════════
// FIELD TYPE → AVAILABLE COMPARISONS
// ═══════════════════════════════════════════════════════════════════

List<({String value, String label})> comparisonsForFieldType(FieldType type, {bool isOrdinal = false}) {
  switch (type) {
    case FieldType.number:
    case FieldType.range:
    case FieldType.starRating:
    case FieldType.mood:
    case FieldType.duration:
    case FieldType.startTime:
    case FieldType.endTime:
      return _numericComparisons;
    case FieldType.text:
      return [(value: 'contains', label: 'Contains'), (value: 'not_contains', label: 'Does not contain')];
    case FieldType.yesNo:
      return [(value: '=', label: 'Equals')];
    case FieldType.singleChoice:
      if (isOrdinal) return _numericComparisons;
      return [(value: '=', label: 'Equals')];
    case FieldType.multipleChoice:
      return [(value: 'contains', label: 'Contains'), (value: 'not_contains', label: 'Does not contain')];
    case FieldType.location:
      return [(value: 'at_location', label: 'At location'), (value: 'not_at_location', label: 'Not at location')];
    case FieldType.list:
      return [(value: 'contains', label: 'Contains item'), (value: 'not_contains', label: 'Does not contain item')];
  }
}

const _numericComparisons = [
  (value: '>=', label: 'At least'),
  (value: '<=', label: 'At most'),
  (value: '>', label: 'More than'),
  (value: '<', label: 'Less than'),
  (value: '=', label: 'Exactly'),
  (value: 'between', label: 'Between'),
  (value: 'not_between', label: 'Not between'),
];

// ═══════════════════════════════════════════════════════════════════
// CONDITION MODEL (used in Target and Combined goals)
// ═══════════════════════════════════════════════════════════════════

class GoalCondition {
  String? fieldId;
  String? fieldLabel;
  FieldType? fieldType;
  String comparison;
  // Target
  bool useCalculatedTarget;
  double? targetValue;
  double? targetTo; // for between
  String? targetText;
  bool? targetBool;
  // Calculated target
  String calcTargetScope; // 'last_n_entries', 'last_n_days', etc.
  int? calcTargetScopeCount;
  String calcTargetAggregation;
  // Time-relative target
  bool useRelativeTime;
  String? relativeTimeAnchor; // 'window_start', 'window_end'
  int relativeTimeOffset;
  // Location target
  double? locationLat;
  double? locationLng;
  double? locationRadius;
  String? locationName;

  GoalCondition({
    this.fieldId,
    this.fieldLabel,
    this.fieldType,
    this.comparison = '>=',
    this.useCalculatedTarget = false,
    this.targetValue,
    this.targetTo,
    this.targetText,
    this.targetBool,
    this.calcTargetScope = 'last_n_entries',
    this.calcTargetScopeCount,
    this.calcTargetAggregation = 'average',
    this.useRelativeTime = false,
    this.relativeTimeAnchor,
    this.relativeTimeOffset = 0,
    this.locationLat,
    this.locationLng,
    this.locationRadius,
    this.locationName,
  });

  Map<String, dynamic> toJson() => {
    if (fieldId != null) 'field_id': fieldId,
    if (fieldLabel != null) 'field_label': fieldLabel,
    if (fieldType != null) 'field_type': fieldType!.typeKey,
    'comparison': comparison,
    'use_calculated_target': useCalculatedTarget,
    if (targetValue != null) 'target_value': targetValue,
    if (targetTo != null) 'target_to': targetTo,
    if (targetText != null) 'target_text': targetText,
    if (targetBool != null) 'target_bool': targetBool,
    if (useCalculatedTarget) ...{
      'calc_target_scope': calcTargetScope,
      if (calcTargetScopeCount != null) 'calc_target_scope_count': calcTargetScopeCount,
      'calc_target_aggregation': calcTargetAggregation,
    },
    if (useRelativeTime) ...{
      'use_relative_time': true,
      if (relativeTimeAnchor != null) 'relative_time_anchor': relativeTimeAnchor,
      'relative_time_offset': relativeTimeOffset,
    },
    if (locationLat != null) 'location_lat': locationLat,
    if (locationLng != null) 'location_lng': locationLng,
    if (locationRadius != null) 'location_radius': locationRadius,
    if (locationName != null) 'location_name': locationName,
  };

  factory GoalCondition.fromJson(Map<String, dynamic> json) => GoalCondition(
    fieldId: json['field_id'] as String?,
    fieldLabel: json['field_label'] as String?,
    comparison: json['comparison'] as String? ?? '>=',
    useCalculatedTarget: json['use_calculated_target'] as bool? ?? false,
    targetValue: (json['target_value'] as num?)?.toDouble(),
    targetTo: (json['target_to'] as num?)?.toDouble(),
    targetText: json['target_text'] as String?,
    targetBool: json['target_bool'] as bool?,
    calcTargetScope: json['calc_target_scope'] as String? ?? 'last_n_entries',
    calcTargetScopeCount: json['calc_target_scope_count'] as int?,
    calcTargetAggregation: json['calc_target_aggregation'] as String? ?? 'average',
    useRelativeTime: json['use_relative_time'] as bool? ?? false,
    relativeTimeAnchor: json['relative_time_anchor'] as String?,
    relativeTimeOffset: json['relative_time_offset'] as int? ?? 0,
    locationLat: (json['location_lat'] as num?)?.toDouble(),
    locationLng: (json['location_lng'] as num?)?.toDouble(),
    locationRadius: (json['location_radius'] as num?)?.toDouble(),
    locationName: json['location_name'] as String?,
  );
}

// ═══════════════════════════════════════════════════════════════════
// GOAL CONFIG MODEL
// ═══════════════════════════════════════════════════════════════════

class GoalConfig {
  final String id;
  String name;
  String goalType; // 'completion', 'target', 'combined'

  // Completion fields
  String completionComparison;
  int completionCount;

  // Target fields
  String? fieldId;
  String? fieldLabel;
  FieldType? fieldType;
  String entriesScope; // 'most_recent', 'most_recent_period', 'last_n_entries', 'last_n_days', etc.
  int? entriesScopeCount;
  String? entriesScopeUnit; // 'entries', 'days', 'weeks', 'months', 'years'
  String calculation; // 'sum', 'average', etc.
  GoalCondition condition; // the single condition for Target type

  // Combined fields
  String combineLogic; // 'all' or 'any'
  List<GoalCondition> conditions; // 2+ conditions for Combined type

  // Success rate (for Target and Combined when scope ≠ most_recent)
  bool hasSuccessRate;
  String successRateType; // 'percentage' or 'count'
  int successRateValue; // the percentage or count
  int? successRateOf; // "of last X entries" (only for count type)

  bool isPrimary;
  bool isAutoCreated; // true if auto-created when schedule toggled on

  GoalConfig({
    String? id,
    this.name = '',
    this.goalType = 'completion',
    this.completionComparison = '=',
    this.completionCount = 1,
    this.fieldId,
    this.fieldLabel,
    this.fieldType,
    this.entriesScope = 'most_recent_period',
    this.entriesScopeCount,
    this.entriesScopeUnit,
    this.calculation = 'sum',
    GoalCondition? condition,
    this.combineLogic = 'any',
    List<GoalCondition>? conditions,
    this.hasSuccessRate = false,
    this.successRateType = 'percentage',
    this.successRateValue = 80,
    this.successRateOf,
    this.isPrimary = false,
    this.isAutoCreated = false,
  })  : id = id ?? _uuid.v4(),
        condition = condition ?? GoalCondition(),
        conditions = conditions ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'goal_type': goalType,
    'is_primary': isPrimary,
    if (goalType == 'completion') ...{
      'completion_comparison': completionComparison,
      'completion_count': completionCount,
    },
    if (goalType == 'target') ...{
      'entries_scope': entriesScope,
      if (entriesScopeCount != null) 'entries_scope_count': entriesScopeCount,
      if (entriesScopeUnit != null) 'entries_scope_unit': entriesScopeUnit,
      'calculation': calculation,
      'condition': condition.toJson(),
    },
    if (goalType == 'combined') ...{
      'combine_logic': combineLogic,
      'entries_scope': entriesScope,
      if (entriesScopeCount != null) 'entries_scope_count': entriesScopeCount,
      if (entriesScopeUnit != null) 'entries_scope_unit': entriesScopeUnit,
      'conditions': conditions.map((c) => c.toJson()).toList(),
    },
    if (hasSuccessRate) ...{
      'success_rate_type': successRateType,
      'success_rate_value': successRateValue,
      if (successRateOf != null) 'success_rate_of': successRateOf,
    },
  };

  factory GoalConfig.fromJson(Map<String, dynamic> json) => GoalConfig(
    id: json['id'] as String?,
    name: json['name'] as String? ?? '',
    goalType: json['goal_type'] as String? ?? 'completion',
    isPrimary: json['is_primary'] as bool? ?? false,
    completionComparison: json['completion_comparison'] as String? ?? '=',
    completionCount: json['completion_count'] as int? ?? 1,
    entriesScope: json['entries_scope'] as String? ?? 'most_recent_period',
    entriesScopeCount: json['entries_scope_count'] as int?,
    entriesScopeUnit: json['entries_scope_unit'] as String?,
    calculation: json['calculation'] as String? ?? 'sum',
    condition: json['condition'] != null
        ? GoalCondition.fromJson(Map<String, dynamic>.from(json['condition'] as Map))
        : null,
    combineLogic: json['combine_logic'] as String? ?? 'any',
    conditions: (json['conditions'] as List<dynamic>?)
        ?.map((c) => GoalCondition.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList(),
    hasSuccessRate: json['success_rate_type'] != null,
    successRateType: json['success_rate_type'] as String? ?? 'percentage',
    successRateValue: json['success_rate_value'] as int? ?? 80,
    successRateOf: json['success_rate_of'] as int?,
  );
}

// ═══════════════════════════════════════════════════════════════════
// GOAL CONFIG SECTION WIDGET
// ═══════════════════════════════════════════════════════════════════

class GoalConfigSection extends StatefulWidget {
  final List<GoalConfig> goals;
  final List<FieldConfig> fields;
  final bool hasSchedule;
  final String frequency;
  final bool hasTimeWindow;
  final String? windowStart;
  final String? windowEnd;
  final ValueChanged<List<GoalConfig>> onChanged;

  const GoalConfigSection({
    super.key,
    required this.goals,
    required this.fields,
    required this.hasSchedule,
    required this.frequency,
    this.hasTimeWindow = false,
    this.windowStart,
    this.windowEnd,
    required this.onChanged,
  });

  @override
  State<GoalConfigSection> createState() => _GoalConfigSectionState();
}

class _GoalConfigSectionState extends State<GoalConfigSection> {
  String get _periodLabel => switch (widget.frequency) {
    'daily' => 'day', 'weekly' => 'week', 'monthly' => 'month', 'yearly' => 'year', _ => 'period',
  };

  void _addGoal() {
    final goal = GoalConfig(
      isPrimary: widget.goals.isEmpty,
      goalType: widget.hasSchedule ? 'completion' : 'target',
    );
    widget.onChanged([...widget.goals, goal]);
  }

  void _removeGoal(int index) {
    final updated = [...widget.goals]..removeAt(index);
    if (updated.isNotEmpty && !updated.any((g) => g.isPrimary)) {
      updated.first.isPrimary = true;
    }
    widget.onChanged(updated);
  }

  void _setPrimary(int index) {
    for (var i = 0; i < widget.goals.length; i++) {
      widget.goals[i].isPrimary = i == index;
    }
    widget.onChanged(List.from(widget.goals));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Goal cards
        ...widget.goals.asMap().entries.map((entry) {
          final i = entry.key;
          final goal = entry.value;
          return _GoalCard(
            goal: goal,
            index: i,
            fields: widget.fields,
            hasSchedule: widget.hasSchedule,
            periodLabel: _periodLabel,
            isOnlyGoal: widget.goals.length == 1,
            hasTimeWindow: widget.hasTimeWindow,
            windowStart: widget.windowStart,
            windowEnd: widget.windowEnd,
            onChanged: () => widget.onChanged(List.from(widget.goals)),
            onRemove: () => _removeGoal(i),
            onSetPrimary: () => _setPrimary(i),
          );
        }),

        // Add goal button
        const SizedBox(height: KitabSpacing.sm),
        OutlinedButton.icon(
          onPressed: _addGoal,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Goal'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// GOAL CARD
// ═══════════════════════════════════════════════════════════════════

class _GoalCard extends StatefulWidget {
  final GoalConfig goal;
  final int index;
  final List<FieldConfig> fields;
  final bool hasSchedule;
  final String periodLabel;
  final bool isOnlyGoal;
  final bool hasTimeWindow;
  final String? windowStart;
  final String? windowEnd;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final VoidCallback onSetPrimary;

  const _GoalCard({
    required this.goal,
    required this.index,
    required this.fields,
    required this.hasSchedule,
    required this.periodLabel,
    required this.isOnlyGoal,
    this.hasTimeWindow = false,
    this.windowStart,
    this.windowEnd,
    required this.onChanged,
    required this.onRemove,
    required this.onSetPrimary,
  });

  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard> {
  bool _editingName = false;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;

    return Card(
      margin: const EdgeInsets.only(bottom: KitabSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(KitabSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header: Name + Primary + Remove ───
            Row(
              children: [
                if (_editingName)
                  Expanded(child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(isDense: true, hintText: 'Goal name'),
                    autofocus: true,
                    onSubmitted: (v) {
                      goal.name = v.trim();
                      setState(() => _editingName = false);
                      widget.onChanged();
                    },
                  ))
                else ...[
                  Flexible(child: Text(
                    goal.name.isNotEmpty ? goal.name : 'Goal ${widget.index + 1}',
                    style: KitabTypography.h3,
                    overflow: TextOverflow.ellipsis,
                  )),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16, color: KitabColors.gray400),
                    onPressed: () => setState(() => _editingName = true),
                  ),
                ],
                if (goal.isPrimary)
                  Chip(
                    label: const Text('Primary'),
                    labelStyle: KitabTypography.caption.copyWith(color: KitabColors.accent),
                    side: BorderSide(color: KitabColors.accent.withValues(alpha: 0.3)),
                    visualDensity: VisualDensity.compact,
                  ),
                const Spacer(),
                if (!goal.isPrimary && !widget.isOnlyGoal)
                  TextButton(onPressed: widget.onSetPrimary, child: const Text('Make Primary')),
                IconButton(icon: const Icon(Icons.close, size: 18, color: KitabColors.error), onPressed: widget.onRemove),
              ],
            ),
            const Divider(),

            // ─── Goal Type Selector ───
            Row(
              children: [
                if (widget.hasSchedule)
                  Expanded(child: RadioListTile<String>(
                    title: const Text('Completion'),
                    value: 'completion', groupValue: goal.goalType,
                    onChanged: (v) { goal.goalType = v!; widget.onChanged(); },
                    dense: true, contentPadding: EdgeInsets.zero,
                  )),
                Expanded(child: RadioListTile<String>(
                  title: const Text('Target'),
                  value: 'target', groupValue: goal.goalType,
                  onChanged: (v) { goal.goalType = v!; widget.onChanged(); },
                  dense: true, contentPadding: EdgeInsets.zero,
                )),
                Expanded(child: RadioListTile<String>(
                  title: const Text('Combined'),
                  value: 'combined', groupValue: goal.goalType,
                  onChanged: (v) {
                    goal.goalType = v!;
                    if (goal.conditions.length < 2) {
                      while (goal.conditions.length < 2) goal.conditions.add(GoalCondition());
                    }
                    widget.onChanged();
                  },
                  dense: true, contentPadding: EdgeInsets.zero,
                )),
              ],
            ),
            const SizedBox(height: KitabSpacing.sm),

            // ─── Goal Type Body ───
            if (goal.goalType == 'completion') _buildCompletion(),
            if (goal.goalType == 'target') _buildTarget(),
            if (goal.goalType == 'combined') _buildCombined(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // COMPLETION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildCompletion() {
    final goal = widget.goal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Do this activity...', style: KitabTypography.body),
        const SizedBox(height: KitabSpacing.sm),
        Row(
          children: [
            Expanded(child: DropdownButtonFormField<String>(
              value: goal.completionComparison,
              decoration: const InputDecoration(isDense: true, labelText: 'Comparison'),
              items: [for (final c in _numericComparisons) DropdownMenuItem(value: c.value, child: Text(c.label))],
              onChanged: (v) { goal.completionComparison = v ?? '='; widget.onChanged(); },
            )),
            const SizedBox(width: KitabSpacing.sm),
            SizedBox(width: 70, child: TextFormField(
              initialValue: '${goal.completionCount}',
              decoration: const InputDecoration(isDense: true, labelText: 'Count'),
              keyboardType: TextInputType.number,
              onChanged: (v) { goal.completionCount = int.tryParse(v) ?? 1; widget.onChanged(); },
            )),
            if (goal.completionComparison == 'between' || goal.completionComparison == 'not_between') ...[
              const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('to')),
              SizedBox(width: 70, child: TextFormField(
                initialValue: '',
                decoration: const InputDecoration(isDense: true, labelText: 'Max'),
                keyboardType: TextInputType.number,
                onChanged: (v) { widget.onChanged(); },
              )),
            ],
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('times per ${widget.periodLabel}',
              style: KitabTypography.caption.copyWith(color: KitabColors.gray500)),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TARGET
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTarget() {
    final goal = widget.goal;
    if (widget.fields.isEmpty) {
      return Text('Add fields above to create target goals.',
          style: KitabTypography.bodySmall.copyWith(color: KitabColors.warning));
    }

    // Ensure field is selected
    final selectedField = widget.fields.where((f) => f.id == goal.fieldId).firstOrNull ?? widget.fields.first;
    if (goal.fieldId == null) {
      goal.fieldId = selectedField.id;
      goal.fieldLabel = selectedField.label;
      goal.fieldType = selectedField.type;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field
        DropdownButtonFormField<String>(
          value: goal.fieldId,
          decoration: const InputDecoration(labelText: 'Field', isDense: true),
          items: widget.fields.map((f) => DropdownMenuItem(
            value: f.id,
            child: Text('${f.label}${f.unit != null ? ' (${f.unit})' : ''}'),
          )).toList(),
          onChanged: (v) {
            final f = widget.fields.firstWhere((f) => f.id == v);
            goal.fieldId = v;
            goal.fieldLabel = f.label;
            goal.fieldType = f.type;
            goal.condition.fieldId = v;
            goal.condition.fieldLabel = f.label;
            goal.condition.fieldType = f.type;
            // Auto-activate relative time when selecting a time field with a time window
            final isTimeField = f.type == FieldType.startTime || f.type == FieldType.endTime;
            if (isTimeField && widget.hasTimeWindow) {
              goal.condition.useRelativeTime = true;
              goal.condition.relativeTimeAnchor ??= 'window_start';
              goal.condition.comparison = '<=';
            } else {
              goal.condition.useRelativeTime = false;
            }
            // Reset comparison for new field type
            final comps = comparisonsForFieldType(f.type, isOrdinal: f.isOrdinal);
            if (!isTimeField || !widget.hasTimeWindow) {
              goal.condition.comparison = comps.first.value;
            }
            widget.onChanged();
          },
        ),
        const SizedBox(height: KitabSpacing.sm),

        // Entries to check
        _buildEntriesScope(goal),
        const SizedBox(height: KitabSpacing.sm),

        // Calculation (only if not most_recent)
        if (goal.entriesScope != 'most_recent') ...[
          DropdownButtonFormField<String>(
            value: goal.calculation,
            decoration: const InputDecoration(labelText: 'How to calculate', isDense: true),
            items: calculationsForFieldType(selectedField.type)
                .map((c) => DropdownMenuItem(value: c.value, child: Text(c.label)))
                .toList(),
            onChanged: (v) { goal.calculation = v ?? 'sum'; widget.onChanged(); },
          ),
          const SizedBox(height: KitabSpacing.sm),
        ],

        // Condition (comparison + target)
        _buildConditionRow(goal.condition, selectedField),

        // Success rate
        if (goal.entriesScope != 'most_recent')
          _buildSuccessRate(goal),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // COMBINED
  // ═══════════════════════════════════════════════════════════════

  Widget _buildCombined() {
    final goal = widget.goal;
    if (widget.fields.isEmpty) {
      return Text('Add fields above to create combined goals.',
          style: KitabTypography.bodySmall.copyWith(color: KitabColors.warning));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logic selector
        Row(
          children: [
            const Text('Goal is met when '),
            DropdownButton<String>(
              value: goal.combineLogic,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('all conditions are met')),
                DropdownMenuItem(value: 'any', child: Text('any condition is met')),
              ],
              onChanged: (v) { goal.combineLogic = v ?? 'any'; widget.onChanged(); },
            ),
          ],
        ),
        const SizedBox(height: KitabSpacing.sm),

        // Shared entries scope
        _buildEntriesScope(goal),
        const SizedBox(height: KitabSpacing.md),

        // Condition cards
        ...goal.conditions.asMap().entries.map((entry) {
          final i = entry.key;
          final cond = entry.value;

          // Ensure condition has a field
          if (cond.fieldId == null && widget.fields.isNotEmpty) {
            cond.fieldId = widget.fields.first.id;
            cond.fieldLabel = widget.fields.first.label;
            cond.fieldType = widget.fields.first.type;
          }

          final condField = widget.fields.where((f) => f.id == cond.fieldId).firstOrNull ?? widget.fields.first;

          return Container(
            margin: const EdgeInsets.only(bottom: KitabSpacing.sm),
            padding: const EdgeInsets.all(KitabSpacing.sm),
            decoration: BoxDecoration(
              border: Border.all(color: KitabColors.gray200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Condition ${i + 1}', style: KitabTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    if (goal.conditions.length > 2)
                      IconButton(
                        icon: const Icon(Icons.close, size: 16, color: KitabColors.error),
                        onPressed: () { goal.conditions.removeAt(i); widget.onChanged(); },
                      ),
                  ],
                ),
                // Field selector for this condition
                DropdownButtonFormField<String>(
                  value: cond.fieldId,
                  decoration: const InputDecoration(labelText: 'Field', isDense: true),
                  items: widget.fields.map((f) => DropdownMenuItem(
                    value: f.id, child: Text(f.label),
                  )).toList(),
                  onChanged: (v) {
                    final f = widget.fields.firstWhere((f) => f.id == v);
                    cond.fieldId = v;
                    cond.fieldLabel = f.label;
                    cond.fieldType = f.type;
                    // Auto-activate relative time for time fields with a time window
                    final isTimeField = f.type == FieldType.startTime || f.type == FieldType.endTime;
                    if (isTimeField && widget.hasTimeWindow) {
                      cond.useRelativeTime = true;
                      cond.relativeTimeAnchor ??= 'window_start';
                      cond.comparison = '<=';
                    } else {
                      cond.useRelativeTime = false;
                      final comps = comparisonsForFieldType(f.type, isOrdinal: f.isOrdinal);
                      cond.comparison = comps.first.value;
                    }
                    widget.onChanged();
                  },
                ),
                const SizedBox(height: KitabSpacing.xs),
                _buildConditionRow(cond, condField),
              ],
            ),
          );
        }),

        OutlinedButton.icon(
          onPressed: () { goal.conditions.add(GoalCondition()); widget.onChanged(); },
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Condition'),
        ),

        // Success rate
        if (goal.entriesScope != 'most_recent')
          _buildSuccessRate(goal),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════════

  /// Entries scope dropdown (shared by Target and Combined)
  Widget _buildEntriesScope(GoalConfig goal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: goal.entriesScope,
          decoration: const InputDecoration(labelText: 'Entries to check', isDense: true),
          items: [
            const DropdownMenuItem(value: 'most_recent', child: Text('Most recent entry')),
            if (widget.hasSchedule) const DropdownMenuItem(value: 'most_recent_period', child: Text('Most recent period')),
            const DropdownMenuItem(value: 'last_n_entries', child: Text('Last ___ entries')),
            const DropdownMenuItem(value: 'last_n_time', child: Text('Last ___ days/weeks/months')),
            const DropdownMenuItem(value: 'all_time', child: Text('All entries ever')),
          ],
          onChanged: (v) { goal.entriesScope = v ?? 'most_recent_period'; widget.onChanged(); },
        ),

        if (goal.entriesScope == 'last_n_entries') ...[
          const SizedBox(height: KitabSpacing.xs),
          TextFormField(
            initialValue: goal.entriesScopeCount?.toString() ?? '',
            decoration: const InputDecoration(labelText: 'How many entries?', isDense: true),
            keyboardType: TextInputType.number,
            onChanged: (v) { goal.entriesScopeCount = int.tryParse(v); widget.onChanged(); },
          ),
        ],

        if (goal.entriesScope == 'last_n_time') ...[
          const SizedBox(height: KitabSpacing.xs),
          Row(
            children: [
              Expanded(child: TextFormField(
                initialValue: goal.entriesScopeCount?.toString() ?? '',
                decoration: const InputDecoration(labelText: 'How many?', isDense: true),
                keyboardType: TextInputType.number,
                onChanged: (v) { goal.entriesScopeCount = int.tryParse(v); widget.onChanged(); },
              )),
              const SizedBox(width: KitabSpacing.sm),
              Expanded(child: DropdownButtonFormField<String>(
                value: goal.entriesScopeUnit ?? 'days',
                decoration: const InputDecoration(isDense: true),
                items: const [
                  DropdownMenuItem(value: 'days', child: Text('Days')),
                  DropdownMenuItem(value: 'weeks', child: Text('Weeks')),
                  DropdownMenuItem(value: 'months', child: Text('Months')),
                  DropdownMenuItem(value: 'years', child: Text('Years')),
                ],
                onChanged: (v) { goal.entriesScopeUnit = v; widget.onChanged(); },
              )),
            ],
          ),
        ],
      ],
    );
  }

  /// Comparison + Target row for a single condition
  Widget _buildConditionRow(GoalCondition cond, FieldConfig field) {
    final comparisons = comparisonsForFieldType(field.type, isOrdinal: field.isOrdinal);
    if (!comparisons.any((c) => c.value == cond.comparison)) {
      cond.comparison = comparisons.first.value;
    }

    // Auto-activate relative time for time fields when a time window exists
    final isTimeFieldWithWindow = (field.type == FieldType.startTime || field.type == FieldType.endTime)
        && widget.hasTimeWindow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // When it's a time field with a time window, show relative mode as the default
        if (isTimeFieldWithWindow && cond.useRelativeTime)
          _buildTimeRelativeTarget(cond, field, comparisons)
        else ...[
          Row(
            children: [
              // Comparison
              Expanded(child: DropdownButtonFormField<String>(
                value: cond.comparison,
                decoration: const InputDecoration(labelText: 'Comparison', isDense: true),
                items: comparisons.map((c) => DropdownMenuItem(value: c.value, child: Text(c.label))).toList(),
                onChanged: (v) { cond.comparison = v ?? '>='; widget.onChanged(); },
              )),
              const SizedBox(width: KitabSpacing.sm),

              // Target value (type-appropriate)
              if (!cond.useCalculatedTarget)
                Expanded(child: _buildTargetInput(cond, field)),
            ],
          ),

          // Calculated target toggle
          const SizedBox(height: KitabSpacing.xs),
          if (field.type != FieldType.yesNo && field.type != FieldType.location)
            SwitchListTile(
              title: const Text('Compare against calculated value'),
              value: cond.useCalculatedTarget,
              onChanged: (v) { cond.useCalculatedTarget = v; widget.onChanged(); },
              dense: true, contentPadding: EdgeInsets.zero,
            ),

          if (cond.useCalculatedTarget) _buildCalculatedTarget(cond, field),
        ],

        // Switch link between absolute and relative modes for time fields
        if (isTimeFieldWithWindow)
          Padding(
            padding: const EdgeInsets.only(top: KitabSpacing.xs),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: Icon(
                  cond.useRelativeTime ? Icons.access_time : Icons.timer,
                  size: 16,
                ),
                label: Text(
                  cond.useRelativeTime
                      ? 'Use absolute time target instead'
                      : 'Set target relative to time window',
                ),
                onPressed: () {
                  cond.useRelativeTime = !cond.useRelativeTime;
                  if (cond.useRelativeTime) {
                    cond.relativeTimeAnchor ??= 'window_start';
                  }
                  widget.onChanged();
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  textStyle: KitabTypography.caption,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Type-appropriate target input
  Widget _buildTargetInput(GoalCondition cond, FieldConfig field) {
    if (field.type == FieldType.yesNo) {
      return DropdownButtonFormField<bool>(
        value: cond.targetBool ?? true,
        decoration: const InputDecoration(labelText: 'Value', isDense: true),
        items: const [DropdownMenuItem(value: true, child: Text('Yes')), DropdownMenuItem(value: false, child: Text('No'))],
        onChanged: (v) { cond.targetBool = v; widget.onChanged(); },
      );
    } else if (field.type == FieldType.text || field.type == FieldType.list) {
      return TextFormField(
        initialValue: cond.targetText ?? '',
        decoration: const InputDecoration(labelText: 'Text', isDense: true),
        onChanged: (v) { cond.targetText = v; widget.onChanged(); },
      );
    } else if (field.type == FieldType.singleChoice || field.type == FieldType.multipleChoice) {
      return DropdownButtonFormField<String>(
        value: cond.targetText,
        decoration: const InputDecoration(labelText: 'Option', isDense: true),
        items: field.options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: (v) { cond.targetText = v; widget.onChanged(); },
      );
    } else if (field.type == FieldType.mood) {
      return DropdownButtonFormField<double>(
        value: cond.targetValue,
        decoration: const InputDecoration(labelText: 'Mood', isDense: true),
        items: const [
          DropdownMenuItem(value: 1, child: Text('😢 Very Bad')),
          DropdownMenuItem(value: 2, child: Text('😟 Bad')),
          DropdownMenuItem(value: 3, child: Text('😐 Neutral')),
          DropdownMenuItem(value: 4, child: Text('😊 Good')),
          DropdownMenuItem(value: 5, child: Text('😄 Great')),
        ],
        onChanged: (v) { cond.targetValue = v; widget.onChanged(); },
      );
    } else if (field.type == FieldType.location) {
      return _LocationTargetPicker(cond: cond, onChanged: widget.onChanged);
    } else {
      return TextFormField(
        initialValue: cond.targetValue?.toString() ?? '',
        decoration: InputDecoration(labelText: 'Target', isDense: true, suffixText: field.unit),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (v) { cond.targetValue = double.tryParse(v); widget.onChanged(); },
      );
    }
  }

  /// Calculated target (compare against historical data)
  Widget _buildCalculatedTarget(GoalCondition cond, FieldConfig field) {
    return Container(
      padding: const EdgeInsets.all(KitabSpacing.sm),
      margin: const EdgeInsets.only(top: KitabSpacing.xs),
      decoration: BoxDecoration(
        color: KitabColors.info.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Compare against:', style: KitabTypography.caption.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: KitabSpacing.xs),
          Row(
            children: [
              Expanded(child: DropdownButtonFormField<String>(
                value: cond.calcTargetAggregation,
                decoration: const InputDecoration(labelText: 'Calculate', isDense: true),
                items: calculationsForFieldType(field.type)
                    .map((c) => DropdownMenuItem(value: c.value, child: Text(c.label)))
                    .toList(),
                onChanged: (v) { cond.calcTargetAggregation = v ?? 'average'; widget.onChanged(); },
              )),
              const SizedBox(width: KitabSpacing.sm),
              Expanded(child: DropdownButtonFormField<String>(
                value: cond.calcTargetScope,
                decoration: const InputDecoration(labelText: 'Of', isDense: true),
                items: const [
                  DropdownMenuItem(value: 'last_n_entries', child: Text('Last ___ entries')),
                  DropdownMenuItem(value: 'last_n_days', child: Text('Last ___ days')),
                  DropdownMenuItem(value: 'last_n_weeks', child: Text('Last ___ weeks')),
                  DropdownMenuItem(value: 'last_n_months', child: Text('Last ___ months')),
                  DropdownMenuItem(value: 'previous', child: Text('Previous entry')),
                  DropdownMenuItem(value: 'all_time', child: Text('All entries')),
                ],
                onChanged: (v) { cond.calcTargetScope = v ?? 'last_n_entries'; widget.onChanged(); },
              )),
            ],
          ),
          if (cond.calcTargetScope.startsWith('last_n_')) ...[
            const SizedBox(height: KitabSpacing.xs),
            TextFormField(
              initialValue: cond.calcTargetScopeCount?.toString() ?? '7',
              decoration: const InputDecoration(labelText: 'How many?', isDense: true),
              keyboardType: TextInputType.number,
              onChanged: (v) { cond.calcTargetScopeCount = int.tryParse(v); widget.onChanged(); },
            ),
          ],
        ],
      ),
    );
  }

  /// Time-relative target — shown as the primary UI when relative mode is active.
  /// Includes its own comparison dropdown so the user sees everything in one place.
  Widget _buildTimeRelativeTarget(GoalCondition cond, FieldConfig field, List<({String value, String label})> comparisons) {
    return Container(
      padding: const EdgeInsets.all(KitabSpacing.md),
      decoration: BoxDecoration(
        color: KitabColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KitabColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer, size: 16, color: KitabColors.primary),
              const SizedBox(width: 6),
              Text('Relative to time window',
                  style: KitabTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600, color: KitabColors.primary)),
            ],
          ),
          const SizedBox(height: KitabSpacing.sm),

          // Anchor: window start or end
          DropdownButtonFormField<String>(
            value: cond.relativeTimeAnchor ?? 'window_start',
            decoration: const InputDecoration(labelText: 'Relative to', isDense: true),
            items: [
              DropdownMenuItem(
                value: 'window_start',
                child: Text('Window start${widget.windowStart != null ? ' (${widget.windowStart})' : ''}'),
              ),
              DropdownMenuItem(
                value: 'window_end',
                child: Text('Window end${widget.windowEnd != null ? ' (${widget.windowEnd})' : ''}'),
              ),
            ],
            onChanged: (v) { cond.relativeTimeAnchor = v; widget.onChanged(); },
          ),
          const SizedBox(height: KitabSpacing.sm),

          // Comparison + offset in one row
          Row(
            children: [
              Expanded(child: DropdownButtonFormField<String>(
                value: cond.comparison,
                decoration: const InputDecoration(labelText: 'Comparison', isDense: true),
                items: [
                  const DropdownMenuItem(value: '<=', child: Text('Within')),
                  const DropdownMenuItem(value: '>=', child: Text('At least')),
                  const DropdownMenuItem(value: '=', child: Text('Exactly')),
                ],
                onChanged: (v) { cond.comparison = v ?? '<='; widget.onChanged(); },
              )),
              const SizedBox(width: KitabSpacing.sm),
              SizedBox(width: 80, child: TextFormField(
                initialValue: cond.relativeTimeOffset != 0 ? '${cond.relativeTimeOffset}' : '',
                decoration: const InputDecoration(isDense: true, labelText: 'Minutes', hintText: '30'),
                keyboardType: TextInputType.number,
                onChanged: (v) { cond.relativeTimeOffset = int.tryParse(v) ?? 0; widget.onChanged(); },
              )),
              const Padding(
                padding: EdgeInsets.only(left: 6, top: 12),
                child: Text('min'),
              ),
            ],
          ),
          const SizedBox(height: KitabSpacing.xs),
          Text(
            _buildRelativeHint(cond),
            style: KitabTypography.caption.copyWith(color: KitabColors.gray500),
          ),
        ],
      ),
    );
  }

  /// Builds a human-readable hint for the time-relative target.
  String _buildRelativeHint(GoalCondition cond) {
    final anchor = cond.relativeTimeAnchor == 'window_end' ? 'window end' : 'window start';
    final mins = cond.relativeTimeOffset > 0 ? '${cond.relativeTimeOffset}' : '___';
    final anchorTime = cond.relativeTimeAnchor == 'window_end'
        ? (widget.windowEnd ?? '?')
        : (widget.windowStart ?? '?');

    switch (cond.comparison) {
      case '<=':
        return 'e.g., Start within $mins min of $anchor ($anchorTime)';
      case '>=':
        return 'e.g., Start at least $mins min from $anchor ($anchorTime)';
      case '=':
        return 'e.g., Start exactly $mins min from $anchor ($anchorTime)';
      default:
        return 'Set how close to $anchor the time should be';
    }
  }

  /// Success rate section
  Widget _buildSuccessRate(GoalConfig goal) {
    return ExpansionTile(
      title: const Text('Success rate'),
      subtitle: goal.hasSuccessRate
          ? Text(
              goal.successRateType == 'percentage'
                  ? 'At least ${goal.successRateValue}% of all entries'
                  : 'At least ${goal.successRateValue} of last ${goal.successRateOf ?? '?'} entries',
              style: KitabTypography.caption.copyWith(color: KitabColors.primary))
          : const Text('Optional — what percentage must pass?'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: KitabSpacing.md),
      children: [
        SwitchListTile(
          title: const Text('Enable success rate'),
          value: goal.hasSuccessRate,
          onChanged: (v) { goal.hasSuccessRate = v; widget.onChanged(); },
          dense: true, contentPadding: EdgeInsets.zero,
        ),
        if (goal.hasSuccessRate) ...[
          const SizedBox(height: KitabSpacing.xs),
          Row(
            children: [
              const Text('At least '),
              SizedBox(width: 64, child: TextFormField(
                initialValue: '${goal.successRateValue}',
                decoration: const InputDecoration(isDense: true),
                keyboardType: TextInputType.number,
                onChanged: (v) { goal.successRateValue = int.tryParse(v) ?? 80; widget.onChanged(); },
              )),
              const SizedBox(width: 6),
              DropdownButton<String>(
                value: goal.successRateType,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'percentage', child: Text('%')),
                  DropdownMenuItem(value: 'count', child: Text('entries')),
                ],
                onChanged: (v) { goal.successRateType = v ?? 'percentage'; widget.onChanged(); },
              ),
              if (goal.successRateType == 'percentage')
                const Flexible(child: Text(' of all entries')),
            ],
          ),
          if (goal.successRateType == 'count') ...[
            const SizedBox(height: KitabSpacing.xs),
            Row(
              children: [
                const Text('of last '),
                SizedBox(width: 64, child: TextFormField(
                  initialValue: goal.successRateOf?.toString() ?? '10',
                  decoration: const InputDecoration(isDense: true),
                  keyboardType: TextInputType.number,
                  onChanged: (v) { goal.successRateOf = int.tryParse(v); widget.onChanged(); },
                )),
                const SizedBox(width: 4),
                const Text('entries'),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// LOCATION TARGET PICKER (reused from before)
// ═══════════════════════════════════════════════════════════════════

class _LocationTargetPicker extends StatelessWidget {
  final GoalCondition cond;
  final VoidCallback onChanged;

  const _LocationTargetPicker({required this.cond, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final hasLoc = cond.locationLat != null && cond.locationLng != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasLoc) ...[
          MapPreview(
            latitude: cond.locationLat!, longitude: cond.locationLng!,
            displayName: cond.locationName, height: 100,
            onTap: () => _pick(context),
          ),
          Row(
            children: [
              const Text('Within '),
              SizedBox(width: 70, child: TextFormField(
                initialValue: cond.locationRadius?.toStringAsFixed(0) ?? '500',
                decoration: const InputDecoration(isDense: true, suffixText: 'm'),
                keyboardType: TextInputType.number,
                onChanged: (v) { cond.locationRadius = double.tryParse(v); onChanged(); },
              )),
            ],
          ),
        ] else
          OutlinedButton.icon(
            icon: const Icon(Icons.add_location, size: 16),
            label: const Text('Select Location'),
            onPressed: () => _pick(context),
          ),
      ],
    );
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showMapLocationPicker(context: context,
      initialLat: cond.locationLat, initialLng: cond.locationLng);
    if (picked != null) {
      cond.locationLat = picked.latitude;
      cond.locationLng = picked.longitude;
      cond.locationName = picked.displayName;
      cond.locationRadius ??= 500;
      onChanged();
    }
  }
}
