// ═══════════════════════════════════════════════════════════════════
// FIELD_CONFIG_SECTION.DART — Activity Fields Configuration
// Add, configure, reorder, and remove fields (metrics).
// Supports all 13 field types from SPEC §5.4.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/kitab_theme.dart';
import '../../../../core/widgets/kitab_toast.dart';

const _uuid = Uuid();

/// All supported field types with their display names.
enum FieldType {
  // Preset (fixed labels)
  startTime('Start Time', 'preset', Icons.schedule),
  endTime('End Time', 'preset', Icons.schedule),
  duration('Duration', 'preset', Icons.timer),

  // Custom
  number('Number', 'number', Icons.pin),
  text('Text', 'text', Icons.text_fields),
  starRating('Star Rating', 'rating', Icons.star),
  yesNo('Yes / No', 'boolean', Icons.check_circle_outline),
  singleChoice('Single Choice', 'enum', Icons.radio_button_checked),
  multipleChoice('Multiple Choice', 'multi_select', Icons.checklist),
  range('Range', 'range', Icons.linear_scale),
  location('Location', 'location', Icons.location_on),
  list('List', 'list', Icons.list),
  mood('Mood', 'mood', Icons.sentiment_satisfied);

  final String label;
  final String typeKey;
  final IconData icon;
  const FieldType(this.label, this.typeKey, this.icon);
}

/// A configured field in the activity template.
class FieldConfig {
  final String id;
  final FieldType type;
  String label;
  String? unit;
  List<String> options; // For single/multiple choice
  double? min, max, step; // For range
  bool isOrdinal; // For single choice

  FieldConfig({
    String? id,
    required this.type,
    String? label,
    this.unit,
    this.options = const [],
    this.min,
    this.max,
    this.step,
    this.isOrdinal = false,
  })  : id = id ?? _uuid.v4(),
        label = label ?? type.label;

  /// Whether this is a preset field with a fixed label.
  /// Whether this is a time-related preset with a fixed label.
  /// Star Rating and Mood are NOT preset — they allow custom labels
  /// and multiples (e.g., "Sleep Quality" rating + "Workout Quality" rating).
  bool get isPreset => type == FieldType.startTime ||
      type == FieldType.endTime ||
      type == FieldType.duration;

  /// Whether this field supports numeric comparisons in goals.
  bool get isNumeric => type == FieldType.number ||
      type == FieldType.range ||
      type == FieldType.starRating ||
      type == FieldType.mood ||
      type == FieldType.duration;

  /// Convert to JSON for storage.
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.typeKey,
    'label': label,
    if (unit != null) 'unit': unit,
    if (options.isNotEmpty) 'options': options,
    if (min != null) 'min': min,
    if (max != null) 'max': max,
    if (step != null) 'step': step,
    if (isOrdinal) 'is_ordinal': true,
  };

  /// Parse from stored JSON.
  factory FieldConfig.fromJson(Map<String, dynamic> json) {
    final typeKey = json['type'] as String? ?? 'number';
    final type = FieldType.values.firstWhere(
      (t) => t.typeKey == typeKey,
      orElse: () => FieldType.number,
    );
    return FieldConfig(
      id: json['id'] as String?,
      type: type,
      label: json['label'] as String?,
      unit: json['unit'] as String?,
      options: (json['options'] as List<dynamic>?)?.cast<String>() ?? [],
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      step: (json['step'] as num?)?.toDouble(),
      isOrdinal: json['is_ordinal'] as bool? ?? false,
    );
  }
}

/// The Fields configuration section of the activity form.
class FieldConfigSection extends StatefulWidget {
  final List<FieldConfig> fields;
  final ValueChanged<List<FieldConfig>> onChanged;

  const FieldConfigSection({
    super.key,
    required this.fields,
    required this.onChanged,
  });

  @override
  State<FieldConfigSection> createState() => _FieldConfigSectionState();
}

class _FieldConfigSectionState extends State<FieldConfigSection> {
  void _addField(FieldType type) {
    if (widget.fields.length >= 20) {
      KitabToast.error(context, 'Maximum 20 fields per activity');
      return;
    }

    // Prevent duplicate time preset fields only (Start Time, End Time, Duration)
    // Star Rating and Mood can have multiples with different labels
    if (type == FieldType.startTime || type == FieldType.endTime ||
        type == FieldType.duration) {
      if (widget.fields.any((f) => f.type == type)) {
        KitabToast.show(context, '${type.label} is already added');
        return;
      }
    }

    final field = FieldConfig(type: type);

    // Show config dialog for custom fields (including Yes/No for label)
    if (!field.isPreset) {
      _showFieldDialog(field, isNew: true);
    } else {
      final updated = [...widget.fields, field];
      widget.onChanged(updated);
    }
  }

  void _removeField(int index) {
    final updated = [...widget.fields]..removeAt(index);
    widget.onChanged(updated);
  }

  void _reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final updated = [...widget.fields];
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fields', style: KitabTypography.h3),
        const SizedBox(height: KitabSpacing.xs),
        Text('Add the data you want to capture for each entry.',
            style: KitabTypography.bodySmall.copyWith(color: KitabColors.gray500)),
        const SizedBox(height: KitabSpacing.md),

        // ─── Preset field buttons ───
        Text('Preset:', style: KitabTypography.caption.copyWith(color: KitabColors.gray500)),
        const SizedBox(height: KitabSpacing.xs),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [FieldType.startTime, FieldType.endTime, FieldType.duration]
              .map((t) => _FieldChip(
                    type: t,
                    isAdded: widget.fields.any((f) => f.type == t),
                    onTap: () => _addField(t),
                  ))
              .toList(),
        ),
        const SizedBox(height: KitabSpacing.sm),

        // ─── Custom field buttons ───
        Text('Custom:', style: KitabTypography.caption.copyWith(color: KitabColors.gray500)),
        const SizedBox(height: KitabSpacing.xs),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            FieldType.number, FieldType.text, FieldType.starRating,
            FieldType.mood, FieldType.yesNo, FieldType.singleChoice,
            FieldType.multipleChoice, FieldType.range, FieldType.location,
            FieldType.list,
          ]
              .map((t) => _FieldChip(
                    type: t,
                    isAdded: false, // All custom fields allow multiples
                    onTap: () => _addField(t),
                  ))
              .toList(),
        ),
        const SizedBox(height: KitabSpacing.lg),

        // ─── Added fields list ───
        if (widget.fields.isNotEmpty) ...[
          Text('Added (${widget.fields.length}/20):',
              style: KitabTypography.caption.copyWith(color: KitabColors.gray500)),
          const SizedBox(height: KitabSpacing.xs),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.fields.length,
            onReorder: _reorder,
            itemBuilder: (context, index) {
              final field = widget.fields[index];
              return ListTile(
                key: ValueKey(field.id),
                leading: Icon(field.type.icon, size: 20, color: KitabColors.primary),
                title: Text(field.label, style: KitabTypography.body),
                subtitle: Text(
                  [
                    field.type.label,
                    if (field.unit != null) '· ${field.unit}',
                    if (field.options.isNotEmpty) '· ${field.options.length} options',
                    if (field.min != null) '· ${field.min}–${field.max}',
                  ].join(' '),
                  style: KitabTypography.caption.copyWith(color: KitabColors.gray400),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!field.isPreset)
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16, color: KitabColors.gray400),
                        onPressed: () => _showFieldDialog(field, isNew: false),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: KitabColors.error),
                      onPressed: () => _removeField(index),
                    ),
                    const Icon(Icons.drag_handle, size: 18, color: KitabColors.gray300),
                  ],
                ),
                dense: true,
              );
            },
          ),
        ],

        // Note about Notes field
        Padding(
          padding: const EdgeInsets.only(top: KitabSpacing.sm),
          child: Text('A Notes field is always available on every entry.',
              style: KitabTypography.caption.copyWith(color: KitabColors.gray400, fontStyle: FontStyle.italic)),
        ),
      ],
    );
  }

  /// Reserved field names that cannot be used for template fields (case-insensitive).
  static const _reservedFieldNames = [
    'activity location',
    'expected start',
    'expected end',
    'logged time',
  ];

  /// Check if a name is reserved (case-insensitive).
  bool _isReservedFieldName(String name) {
    return _reservedFieldNames.contains(name.trim().toLowerCase());
  }

  /// Dialog to configure a custom field (label, unit, options, etc.)
  /// Context-appropriate hint text for each field type.
  String _hintForType(FieldType type) {
    return switch (type) {
      FieldType.number => 'e.g., Distance, Weight, Reps, Calories',
      FieldType.text => 'e.g., Workout Type, Book Title, Recipe Name',
      FieldType.starRating => 'e.g., Sleep Quality, Workout Quality, Satisfaction',
      FieldType.mood => 'e.g., Morning Mood, Post-Workout Mood, Evening Mood',
      FieldType.yesNo => 'e.g., Completed?, On Time?, Fasted?',
      FieldType.singleChoice => 'e.g., Intensity, Weather, Difficulty',
      FieldType.multipleChoice => 'e.g., Muscles Worked, Tags, Symptoms',
      FieldType.range => 'e.g., Pain Level, Energy, Difficulty',
      FieldType.location => 'e.g., Gym, Meeting Place, Route Start',
      FieldType.list => 'e.g., Tasks Done, Ingredients, Exercises',
      _ => 'e.g., My Field',
    };
  }

  /// Dialog to configure a custom field (label, unit, options, etc.)
  void _showFieldDialog(FieldConfig field, {required bool isNew}) {
    final labelController = TextEditingController(text: field.isPreset ? field.label : (isNew ? '' : field.label));
    final unitController = TextEditingController(text: field.unit ?? '');
    final optionController = TextEditingController();
    final options = List<String>.from(field.options);
    final minController = TextEditingController(text: field.min?.toString() ?? '');
    final maxController = TextEditingController(text: field.max?.toString() ?? '');
    final stepController = TextEditingController(text: field.step?.toString() ?? '1');
    var isOrdinal = field.isOrdinal;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isNew ? 'Add ${field.type.label}' : 'Edit ${field.type.label}'),
          content: SizedBox(
            width: 340,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Label (not for preset fields)
                  if (!field.isPreset)
                    TextField(
                      controller: labelController,
                      decoration: InputDecoration(
                        labelText: 'Field Label *',
                        hintText: _hintForType(field.type),
                        errorText: labelController.text.trim().toLowerCase() == 'note' ||
                                labelController.text.trim().toLowerCase() == 'notes'
                            ? '"Notes" is reserved'
                            : _isReservedFieldName(labelController.text)
                                ? '"${labelController.text.trim()}" is a reserved field name'
                                : null,
                      ),
                      autofocus: isNew,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setDialogState(() {}),
                    ),

                  // Unit (for Number and Range)
                  if (field.type == FieldType.number || field.type == FieldType.range) ...[
                    const SizedBox(height: KitabSpacing.md),
                    TextField(
                      controller: unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit (optional)',
                        hintText: 'e.g., km, lbs, pages, minutes',
                      ),
                    ),
                  ],

                  // Min/Max/Step (for Range)
                  if (field.type == FieldType.range) ...[
                    const SizedBox(height: KitabSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minController,
                            decoration: const InputDecoration(labelText: 'Min'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: KitabSpacing.sm),
                        Expanded(
                          child: TextField(
                            controller: maxController,
                            decoration: const InputDecoration(labelText: 'Max'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: KitabSpacing.sm),
                        Expanded(
                          child: TextField(
                            controller: stepController,
                            decoration: const InputDecoration(labelText: 'Step'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Options (for Single/Multiple Choice)
                  if (field.type == FieldType.singleChoice ||
                      field.type == FieldType.multipleChoice) ...[
                    const SizedBox(height: KitabSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: optionController,
                            decoration: const InputDecoration(
                              labelText: 'Add option',
                              hintText: 'Type and press +',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: KitabColors.primary),
                          onPressed: () {
                            final opt = optionController.text.trim();
                            if (opt.isNotEmpty && !options.contains(opt)) {
                              setDialogState(() => options.add(opt));
                              optionController.clear();
                            }
                          },
                        ),
                      ],
                    ),
                    if (options.isNotEmpty) ...[
                      const SizedBox(height: KitabSpacing.sm),
                      ...options.asMap().entries.map((e) => ListTile(
                            dense: true,
                            title: Text(e.value),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () => setDialogState(() => options.removeAt(e.key)),
                            ),
                          )),
                    ],

                    // Ordinal toggle (single choice only)
                    if (field.type == FieldType.singleChoice) ...[
                      const SizedBox(height: KitabSpacing.sm),
                      SwitchListTile(
                        title: const Text('Ordered (ordinal)'),
                        subtitle: const Text('Enable >, <, ≥, ≤ comparisons in goals'),
                        value: isOrdinal,
                        onChanged: (v) => setDialogState(() => isOrdinal = v),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final label = field.isPreset
                    ? field.label
                    : labelController.text.trim();
                if (label.isEmpty) return;
                if (label.toLowerCase() == 'note' || label.toLowerCase() == 'notes') return;
                if (_isReservedFieldName(label)) {
                  KitabToast.error(context, '"$label" is a reserved field name');
                  return;
                }

                // Validate: Single/Multiple Choice needs at least 2 options
                if ((field.type == FieldType.singleChoice || field.type == FieldType.multipleChoice)
                    && options.length < 2) {
                  KitabToast.error(context, 'Add at least 2 options');
                  return;
                }

                // Validate: Range needs min and max
                if (field.type == FieldType.range) {
                  final min = double.tryParse(minController.text);
                  final max = double.tryParse(maxController.text);
                  if (min == null || max == null) {
                    KitabToast.error(context, 'Min and Max are required for Range');
                    return;
                  }
                  if (min >= max) {
                    KitabToast.error(context, 'Max must be greater than Min');
                    return;
                  }
                }

                field.label = label;
                field.unit = unitController.text.trim().isEmpty ? null : unitController.text.trim();
                field.options = options;
                field.min = double.tryParse(minController.text);
                field.max = double.tryParse(maxController.text);
                field.step = double.tryParse(stepController.text);
                field.isOrdinal = isOrdinal;

                if (isNew) {
                  widget.onChanged([...widget.fields, field]);
                } else {
                  widget.onChanged(List.from(widget.fields));
                }

                Navigator.pop(ctx);
              },
              child: Text(isNew ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A chip button for adding a field type.
class _FieldChip extends StatelessWidget {
  final FieldType type;
  final bool isAdded;
  final VoidCallback onTap;

  const _FieldChip({required this.type, required this.isAdded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(type.icon, size: 16,
          color: isAdded ? KitabColors.gray400 : KitabColors.primary),
      label: Text(type.label,
          style: TextStyle(
            color: isAdded ? KitabColors.gray400 : null,
            decoration: isAdded ? TextDecoration.lineThrough : null,
          )),
      onPressed: isAdded ? null : onTap,
    );
  }
}
