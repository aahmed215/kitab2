// ═══════════════════════════════════════════════════════════════════
// MORE_DETAILS_SECTION.DART — Expandable details for quick log sheets
// Sections (top to bottom):
//   1. Logged at (editable)
//   2. Time & Duration (toggle, 3 preset fields)
//   3. Template Fields (from linked activity template)
//   4. Notes (always present)
//   5. Additional Fields (user-added ad-hoc fields)
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/kitab_theme.dart';
import '../../../core/widgets/datetime_tz_picker.dart';
import '../../../core/widgets/map_location_picker.dart';
import '../../../data/models/activity.dart';
import 'field_input_builder.dart';

const _uuid = Uuid();

/// Available ad-hoc field types (excludes SingleChoice, MultipleChoice, Range
/// which require preconfiguration, and preset types which are in Time & Duration).
enum AdHocFieldType {
  number('Number', 'number', Icons.pin),
  text('Text', 'text', Icons.text_fields),
  starRating('Star Rating', 'rating', Icons.star),
  mood('Mood', 'mood', Icons.sentiment_satisfied),
  yesNo('Yes / No', 'boolean', Icons.check_circle_outline),
  location('Location', 'location', Icons.location_on),
  list('List', 'list', Icons.list);

  final String label;
  final String typeKey;
  final IconData icon;
  const AdHocFieldType(this.label, this.typeKey, this.icon);
}

/// An ad-hoc field added by the user at log time.
class AdHocField {
  final String id;
  String label;
  final String typeKey;
  String? unit;
  final TextEditingController controller;

  AdHocField({
    String? id,
    required this.label,
    required this.typeKey,
    this.unit,
  })  : id = id ?? _uuid.v4(),
        controller = TextEditingController();
}

/// Expandable "More details" section for quick log sheets.
class MoreDetailsSection extends StatefulWidget {
  final Activity? activity;
  final DateTime loggedAt;
  final ValueChanged<DateTime> onLoggedAtChanged;
  final TextEditingController notesController;
  final Map<String, TextEditingController> fieldControllers;
  final VoidCallback onFieldChanged;

  /// Whether Time & Duration toggle should be ON by default.
  final bool timeDurationDefault;

  /// Pre-filled values for preset fields (from timer).
  final String? initialStartTime;
  final String? initialEndTime;
  final int? initialDurationMinutes;

  /// Whether duration is live-updating (timer running).
  final bool durationIsLive;

  const MoreDetailsSection({
    super.key,
    this.activity,
    required this.loggedAt,
    required this.onLoggedAtChanged,
    required this.notesController,
    required this.fieldControllers,
    required this.onFieldChanged,
    this.timeDurationDefault = false,
    this.initialStartTime,
    this.initialEndTime,
    this.initialDurationMinutes,
    this.durationIsLive = false,
  });

  @override
  State<MoreDetailsSection> createState() => MoreDetailsSectionState();
}

class MoreDetailsSectionState extends State<MoreDetailsSection> {
  bool _expanded = false;
  late bool _showTimeDuration;
  final List<AdHocField> _adHocFields = [];

  // Preset field controllers
  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;
  late final TextEditingController _durationController;

  // Full datetime+tz values for Start/End
  DateTimeTz? _startDateTimeTz;
  DateTimeTz? _endDateTimeTz;

  @override
  void initState() {
    super.initState();

    // Check if template has any preset fields
    final hasPresetFields = _templateHasPresetFields();
    _showTimeDuration = widget.timeDurationDefault || hasPresetFields;

    _startTimeController = TextEditingController(text: widget.initialStartTime ?? '');
    _endTimeController = TextEditingController(text: widget.initialEndTime ?? '');
    _durationController = TextEditingController(
      text: widget.initialDurationMinutes != null ? '${widget.initialDurationMinutes}' : '',
    );
  }

  bool _templateHasPresetFields() {
    if (widget.activity == null) return false;
    return widget.activity!.fields.any((f) {
      final type = f['type'] as String? ?? '';
      return type == 'preset';
    });
  }

  /// Get all template fields excluding presets (they're in Time & Duration section).
  List<Map<String, dynamic>> get _nonPresetTemplateFields {
    if (widget.activity == null) return [];
    return widget.activity!.fields.where((f) {
      final type = f['type'] as String? ?? '';
      return type != 'preset';
    }).toList();
  }

  int get _fieldCount {
    int count = _nonPresetTemplateFields.length;
    if (_showTimeDuration) count += 3;
    count += _adHocFields.length;
    return count;
  }

  @override
  void didUpdateWidget(MoreDetailsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update preset values when timer provides new data
    if (widget.initialStartTime != null && widget.initialStartTime != oldWidget.initialStartTime) {
      _startTimeController.text = widget.initialStartTime!;
    }
    if (widget.initialEndTime != null && widget.initialEndTime != oldWidget.initialEndTime) {
      _endTimeController.text = widget.initialEndTime!;
    }
    if (widget.initialDurationMinutes != null && widget.durationIsLive) {
      _durationController.text = '${widget.initialDurationMinutes}';
    }
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    _durationController.dispose();
    for (final f in _adHocFields) f.controller.dispose();
    super.dispose();
  }

  /// Recalculate duration from start and end datetimes.
  void _recalculateDuration() {
    if (_startDateTimeTz == null || _endDateTimeTz == null) return;
    final diff = _endDateTimeTz!.dateTime.difference(_startDateTimeTz!.dateTime);
    if (diff.isNegative) return;
    _durationController.text = '${diff.inMinutes}';
  }

  /// Collect all field values from this section (called by parent on save).
  Map<String, dynamic> collectFieldValues() {
    final values = <String, dynamic>{};

    // Preset fields
    if (_showTimeDuration) {
      if (_startTimeController.text.isNotEmpty) values['start_time'] = _startTimeController.text;
      if (_endTimeController.text.isNotEmpty) values['end_time'] = _endTimeController.text;
      if (_durationController.text.isNotEmpty) {
        values['duration_minutes'] = int.tryParse(_durationController.text) ?? 0;
      }
    }

    // Ad-hoc fields
    for (final f in _adHocFields) {
      final text = f.controller.text.trim();
      if (text.isNotEmpty) {
        final asNum = num.tryParse(text);
        values['adhoc_${f.id}'] = {
          'label': f.label,
          'type': f.typeKey,
          'value': asNum ?? text,
          if (f.unit != null && f.unit!.isNotEmpty) 'unit': f.unit,
        };
      }
    }

    return values;
  }

  /// Auto-fill end time and finalize duration (called when timer stops).
  void finalizeTimer(String endTime, int durationMinutes) {
    setState(() {
      _endTimeController.text = endTime;
      _durationController.text = '$durationMinutes';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Toggle ───
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: KitabSpacing.sm),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 20, color: KitabColors.gray500,
                ),
                const SizedBox(width: 4),
                Text(
                  _expanded ? 'Less details' : 'More details',
                  style: KitabTypography.bodySmall.copyWith(color: KitabColors.gray500),
                ),
                if (!_expanded && _fieldCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: KitabColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_fieldCount field${_fieldCount == 1 ? '' : 's'}',
                      style: KitabTypography.caption.copyWith(
                        color: KitabColors.primary, fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        if (_expanded) ...[
          // ─── 1. Logged at ───
          DateTimeTzTile(
            label: 'Logged at',
            value: DateTimeTz(dateTime: widget.loggedAt),
            onChanged: (v) => widget.onLoggedAtChanged(v.dateTime),
          ),

          const SizedBox(height: KitabSpacing.sm),

          // ─── 2. Time & Duration ───
          SwitchListTile(
            title: Text('Time & Duration', style: KitabTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
            value: _showTimeDuration,
            onChanged: (v) => setState(() => _showTimeDuration = v),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          if (_showTimeDuration) ...[
            // Start Time — full date + time + timezone
            DateTimeTzTile(
              label: 'Start Time',
              value: _startDateTimeTz,
              icon: Icons.login,
              onChanged: (v) {
                setState(() {
                  _startDateTimeTz = v;
                  _startTimeController.text = v.formatted;
                  _recalculateDuration();
                });
                widget.onFieldChanged();
              },
            ),
            // End Time — full date + time + timezone
            DateTimeTzTile(
              label: 'End Time',
              value: _endDateTimeTz,
              icon: Icons.logout,
              onChanged: (v) {
                setState(() {
                  _endDateTimeTz = v;
                  _endTimeController.text = v.formatted;
                  _recalculateDuration();
                });
                widget.onFieldChanged();
              },
            ),
            // Duration (read-only, auto-calculated)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Duration'),
              subtitle: Text(
                _durationController.text.isEmpty ? '—' : '${_durationController.text} min',
                style: KitabTypography.bodySmall.copyWith(
                  color: KitabColors.gray600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              leading: const Icon(Icons.timer, size: 18, color: KitabColors.gray400),
            ),
          ],

          // ─── 3. Template Fields (non-preset) ───
          if (_nonPresetTemplateFields.isNotEmpty) ...[
            const Divider(),
            Text('Template Fields', style: KitabTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600, color: KitabColors.gray600,
            )),
            const SizedBox(height: KitabSpacing.xs),
            ..._nonPresetTemplateFields.map((field) {
              final fieldId = field['id'] as String? ?? '';
              final label = field['label'] as String? ?? 'Field';
              final type = field['type'] as String? ?? 'text';
              final unit = field['unit'] as String?;
              final controller = widget.fieldControllers.putIfAbsent(
                fieldId, () => TextEditingController(),
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: KitabSpacing.sm),
                child: FieldInputBuilder.build(
                  context: context,
                  fieldId: fieldId,
                  label: label,
                  type: type,
                  unit: unit,
                  config: field,
                  controller: controller,
                  onChanged: (_) => widget.onFieldChanged(),
                ),
              );
            }),
          ],

          // ─── 4. Notes ───
          const SizedBox(height: KitabSpacing.xs),
          TextField(
            controller: widget.notesController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Optional...',
              isDense: true,
            ),
            maxLines: 2,
          ),

          // ─── 5. Additional Fields (ad-hoc) ───
          if (_adHocFields.isNotEmpty) ...[
            const SizedBox(height: KitabSpacing.md),
            Text('Additional Fields', style: KitabTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600, color: KitabColors.gray600,
            )),
            const SizedBox(height: KitabSpacing.xs),
            ..._adHocFields.asMap().entries.map((entry) {
              final i = entry.key;
              final field = entry.value;
              return _AdHocFieldTile(
                field: field,
                onRemove: () {
                  setState(() {
                    field.controller.dispose();
                    _adHocFields.removeAt(i);
                  });
                },
                onChanged: widget.onFieldChanged,
              );
            }),
          ],

          const SizedBox(height: KitabSpacing.sm),

          // Add Field button
          OutlinedButton.icon(
            onPressed: _showAddFieldMenu,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Field'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: KitabSpacing.sm),
        ],
      ],
    );
  }

  void _showAddFieldMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(KitabSpacing.md),
              child: Text('Add Field', style: KitabTypography.h3),
            ),
            ...AdHocFieldType.values.map((type) => ListTile(
              leading: Icon(type.icon, color: KitabColors.primary),
              title: Text(type.label),
              onTap: () {
                Navigator.pop(ctx);
                _addAdHocField(type);
              },
            )),
            const SizedBox(height: KitabSpacing.md),
          ],
        ),
      ),
    );
  }

  void _addAdHocField(AdHocFieldType type) {
    setState(() {
      _adHocFields.add(AdHocField(
        label: type.label,
        typeKey: type.typeKey,
      ));
    });
  }
}

// ─── Ad-hoc field tile with editable label, type-specific input, and remove ───
class _AdHocFieldTile extends StatefulWidget {
  final AdHocField field;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _AdHocFieldTile({
    required this.field,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_AdHocFieldTile> createState() => _AdHocFieldTileState();
}

class _AdHocFieldTileState extends State<_AdHocFieldTile> {
  bool _editingLabel = false;
  late final TextEditingController _labelController;
  late final TextEditingController _unitController;
  late final TextEditingController _listItemController;

  // For list type: items added so far
  List<String> _listItems = [];

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.field.label);
    _unitController = TextEditingController(text: widget.field.unit ?? '');
    _listItemController = TextEditingController();

    // Parse existing list items from controller
    if (widget.field.typeKey == 'list' && widget.field.controller.text.isNotEmpty) {
      _listItems = widget.field.controller.text.split('||');
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _unitController.dispose();
    _listItemController.dispose();
    super.dispose();
  }

  void _syncListToController() {
    widget.field.controller.text = _listItems.join('||');
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.field;

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
          // ─── Label row (editable) + remove button ───
          Row(
            children: [
              if (_editingLabel)
                Expanded(child: TextField(
                  controller: _labelController,
                  decoration: const InputDecoration(isDense: true, hintText: 'Field name'),
                  autofocus: true,
                  onSubmitted: (v) {
                    f.label = v.trim().isEmpty ? f.label : v.trim();
                    setState(() => _editingLabel = false);
                  },
                ))
              else ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _editingLabel = true),
                    child: Row(
                      children: [
                        Text(f.label, style: KitabTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit, size: 12, color: KitabColors.gray400),
                      ],
                    ),
                  ),
                ),
              ],
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: KitabColors.error),
                onPressed: widget.onRemove,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: KitabSpacing.xs),

          // ─── Type-specific input ───
          _buildInput(context),
        ],
      ),
    );
  }

  Widget _buildInput(BuildContext context) {
    final f = widget.field;

    switch (f.typeKey) {
      // ─── Number ───
      case 'number':
        return Column(
          children: [
            TextField(
              controller: f.controller,
              decoration: InputDecoration(isDense: true, hintText: '0', suffixText: f.unit),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              onChanged: (_) => widget.onChanged(),
            ),
            const SizedBox(height: KitabSpacing.xs),
            TextField(
              controller: _unitController,
              decoration: const InputDecoration(
                labelText: 'Unit',
                hintText: 'e.g., km, kcal, reps',
                isDense: true,
              ),
              onChanged: (v) { f.unit = v.trim(); widget.onChanged(); },
            ),
          ],
        );

      // ─── Text ───
      case 'text':
        return TextField(
          controller: f.controller,
          decoration: const InputDecoration(isDense: true, hintText: 'Enter text...'),
          onChanged: (_) => widget.onChanged(),
        );

      // ─── Star Rating (tap cycles: full → half → clear) ───
      case 'rating':
        final ratingValue = double.tryParse(f.controller.text) ?? 0;
        return Row(
          children: List.generate(5, (i) {
            final starIndex = i + 1;
            // Determine star state
            IconData icon;
            if (ratingValue >= starIndex) {
              icon = Icons.star;
            } else if (ratingValue >= starIndex - 0.5) {
              icon = Icons.star_half;
            } else {
              icon = Icons.star_border;
            }
            return GestureDetector(
              onTap: () {
                setState(() {
                  final current = double.tryParse(f.controller.text) ?? 0;
                  if (current == starIndex.toDouble()) {
                    // Full → half
                    f.controller.text = '${starIndex - 0.5}';
                  } else if (current == starIndex - 0.5) {
                    // Half → clear (set to previous star or 0)
                    f.controller.text = '${starIndex - 1}';
                  } else {
                    // Empty or other → full
                    f.controller.text = '$starIndex';
                  }
                });
                widget.onChanged();
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(icon, color: KitabColors.accent, size: 32),
              ),
            );
          }),
        );

      // ─── Mood ───
      case 'mood':
        final moodValue = int.tryParse(f.controller.text) ?? 0;
        const moods = [
          (value: 1, emoji: '😢', label: 'Very Bad'),
          (value: 2, emoji: '😟', label: 'Bad'),
          (value: 3, emoji: '😐', label: 'Neutral'),
          (value: 4, emoji: '😊', label: 'Good'),
          (value: 5, emoji: '😄', label: 'Great'),
        ];
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: moods.map((m) {
            final isSelected = moodValue == m.value;
            return GestureDetector(
              onTap: () {
                setState(() {
                  f.controller.text = '${m.value}';
                });
                widget.onChanged();
              },
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? KitabColors.primary.withValues(alpha: 0.1) : null,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected ? Border.all(color: KitabColors.primary, width: 2) : null,
                    ),
                    child: Text(m.emoji, style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(height: 2),
                  Text(m.label, style: KitabTypography.caption.copyWith(
                    color: isSelected ? KitabColors.primary : KitabColors.gray400,
                    fontSize: 10,
                  )),
                ],
              ),
            );
          }).toList(),
        );

      // ─── Yes / No ───
      case 'boolean':
        final value = f.controller.text;
        return Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  setState(() => f.controller.text = 'true');
                  widget.onChanged();
                },
                icon: const Icon(Icons.check, size: 20),
                label: const Text('Yes'),
                style: FilledButton.styleFrom(
                  backgroundColor: value == 'true' ? KitabColors.success : KitabColors.gray200,
                  foregroundColor: value == 'true' ? Colors.white : KitabColors.gray600,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: KitabSpacing.sm),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  setState(() => f.controller.text = 'false');
                  widget.onChanged();
                },
                icon: const Icon(Icons.close, size: 20),
                label: const Text('No'),
                style: FilledButton.styleFrom(
                  backgroundColor: value == 'false' ? KitabColors.error : KitabColors.gray200,
                  foregroundColor: value == 'false' ? Colors.white : KitabColors.gray600,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        );

      // ─── Location ───
      case 'location':
        final hasLoc = f.controller.text.isNotEmpty && f.controller.text.contains('|');
        String? displayName;
        if (hasLoc) {
          final parts = f.controller.text.split('|');
          displayName = parts.length > 1 ? parts[1] : null;
        }

        return hasLoc
            ? Row(
                children: [
                  const Icon(Icons.location_on, size: 18, color: KitabColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      displayName ?? 'Location set',
                      style: KitabTypography.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _pickLocation(context),
                    child: const Text('Change'),
                  ),
                ],
              )
            : OutlinedButton.icon(
                icon: const Icon(Icons.add_location, size: 18),
                label: const Text('Set Location'),
                onPressed: () => _pickLocation(context),
              );

      // ─── List (tag-style) ───
      case 'list':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Existing items as chips
            if (_listItems.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _listItems.asMap().entries.map((entry) {
                  return Chip(
                    label: Text(entry.value, style: KitabTypography.caption),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () {
                      setState(() => _listItems.removeAt(entry.key));
                      _syncListToController();
                    },
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            const SizedBox(height: KitabSpacing.xs),
            // Add item input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _listItemController,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Add item...',
                    ),
                    onSubmitted: (v) => _addListItem(),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.add_circle, size: 22, color: KitabColors.primary),
                  onPressed: _addListItem,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        );

      // ─── Fallback ───
      default:
        return TextField(
          controller: f.controller,
          decoration: const InputDecoration(isDense: true),
          onChanged: (_) => widget.onChanged(),
        );
    }
  }

  void _addListItem() {
    final text = _listItemController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _listItems.add(text);
      _listItemController.clear();
    });
    _syncListToController();
  }

  Future<void> _pickLocation(BuildContext context) async {
    // Import dynamically to avoid coupling
    final picked = await showMapLocationPicker(context: context);
    if (picked != null) {
      setState(() {
        widget.field.controller.text = '${picked.latitude},${picked.longitude}|${picked.displayName}';
      });
      widget.onChanged();
    }
  }
}
