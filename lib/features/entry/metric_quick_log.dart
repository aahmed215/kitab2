// ═══════════════════════════════════════════════════════════════════
// METRIC_QUICK_LOG.DART — Quick Metric Log Bottom Sheet
// Activity search → numeric stepper with +/- → Save.
// Auto-detects first numeric field from template.
// See SPEC.md §7.5 for specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/engines/engines.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/location_service.dart';
import '../../core/utils/provider_refresh.dart';
import '../../core/providers/database_providers.dart';
import '../../core/theme/kitab_theme.dart';
import '../../data/models/activity.dart';
import '../../data/models/entry.dart';
import 'widgets/quick_log_header.dart';
import 'widgets/more_details_section.dart';

const _uuid = Uuid();
const _linkageEngine = LinkageEngine();

Future<bool?> showMetricQuickLog(BuildContext context) {
  final maxWidth = MediaQuery.of(context).size.width > 600 ? 560.0 : double.infinity;
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.85,
      maxWidth: maxWidth,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: const _MetricQuickLogSheet(),
    ),
  );
}

class _MetricQuickLogSheet extends ConsumerStatefulWidget {
  const _MetricQuickLogSheet();

  @override
  ConsumerState<_MetricQuickLogSheet> createState() => _MetricQuickLogSheetState();
}

class _MetricQuickLogSheetState extends ConsumerState<_MetricQuickLogSheet> {
  Activity? _selectedActivity;
  final _valueController = TextEditingController(text: '0');
  final _unitController = TextEditingController();
  final _notesController = TextEditingController();
  final _labelController = TextEditingController(text: 'Value');
  final Map<String, TextEditingController> _fieldControllers = {};
  final _headerKey = GlobalKey<QuickLogHeaderState>();
  final _detailsKey = GlobalKey<MoreDetailsSectionState>();

  String? _fieldId;
  bool _saving = false;
  bool _editingLabel = false;
  bool _hasChanges = false;
  DateTime _loggedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _valueController.addListener(_markChanged);
    _unitController.addListener(_markChanged);
    _notesController.addListener(_markChanged);
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _valueController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    _labelController.dispose();
    for (final c in _fieldControllers.values) c.dispose();
    super.dispose();
  }

  void _confirmDiscard() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard entry?'),
        content: const Text('You have unsaved changes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep Editing')),
          FilledButton(
            onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  void _onActivityChanged(Activity? activity) {
    _hasChanges = true;
    setState(() {
      _selectedActivity = activity;
      _fieldControllers.clear();

      if (activity != null && activity.fields.isNotEmpty) {
        // Find first numeric-compatible field
        final numericField = activity.fields.firstWhere(
          (f) {
            final type = f['type'] as String? ?? '';
            return type == 'number' || type == 'range' || type == 'duration' || type == 'preset';
          },
          orElse: () => activity.fields.first,
        );
        _labelController.text = numericField['label'] as String? ?? 'Value';
        _fieldId = numericField['id'] as String?;
        _unitController.text = numericField['unit'] as String? ?? '';

        // Build controllers for remaining fields (for "More details")
        for (final field in activity.fields) {
          final id = field['id'] as String? ?? '';
          if (id != _fieldId) {
            _fieldControllers[id] = TextEditingController();
          }
        }
      } else {
        _labelController.text = 'Value';
        _fieldId = null;
        _unitController.clear();
      }
    });
  }

  void _increment() {
    final current = double.tryParse(_valueController.text) ?? 0;
    _valueController.text = _formatNumber(current + 1);
  }

  void _decrement() {
    final current = double.tryParse(_valueController.text) ?? 0;
    _valueController.text = _formatNumber(current - 1);
  }

  String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _hasChanges) _confirmDiscard();
      },
      child: SingleChildScrollView(
      padding: EdgeInsets.only(
        left: KitabSpacing.lg,
        right: KitabSpacing.lg,
        top: KitabSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + KitabSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Common header ───
          QuickLogHeader(
            key: _headerKey,
            title: 'Record a Metric',
            onActivityChanged: _onActivityChanged,
          ),

          const SizedBox(height: KitabSpacing.xl),

          // ─── Field label (editable) ───
          GestureDetector(
            onTap: () => setState(() => _editingLabel = true),
            child: _editingLabel
                ? TextField(
                    controller: _labelController,
                    decoration: const InputDecoration(isDense: true, hintText: 'Field name'),
                    autofocus: true,
                    onSubmitted: (_) => setState(() => _editingLabel = false),
                  )
                : Row(
                    children: [
                      Text(_labelController.text,
                          style: KitabTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit, size: 12, color: KitabColors.gray400),
                    ],
                  ),
          ),
          const SizedBox(height: KitabSpacing.sm),

          // ─── Value stepper ───
          Row(
            children: [
              // Minus (allows negatives)
              IconButton.filled(
                onPressed: _decrement,
                icon: const Icon(Icons.remove),
                style: IconButton.styleFrom(
                  backgroundColor: KitabColors.gray100,
                  foregroundColor: KitabColors.gray700,
                ),
              ),
              const SizedBox(width: KitabSpacing.md),

              // Value
              Expanded(
                child: TextField(
                  controller: _valueController,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  textAlign: TextAlign.center,
                  style: KitabTypography.mono.copyWith(fontSize: 20),
                ),
              ),
              const SizedBox(width: KitabSpacing.md),

              // Plus
              IconButton.filled(
                onPressed: _increment,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: KitabColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

          // Unit
          const SizedBox(height: KitabSpacing.sm),
          TextField(
            controller: _unitController,
            decoration: const InputDecoration(
              labelText: 'Unit',
              hintText: 'e.g., km, glasses, pages',
              isDense: true,
            ),
          ),

          // ─── More details (above buttons) ───
          MoreDetailsSection(
            key: _detailsKey,
            activity: _selectedActivity,
            loggedAt: _loggedAt,
            onLoggedAtChanged: (dt) => setState(() => _loggedAt = dt),
            notesController: _notesController,
            fieldControllers: _fieldControllers,
            onFieldChanged: () {},
          ),

          const SizedBox(height: KitabSpacing.lg),

          // ─── Save (always at the end) ───
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      final now = DateTime.now();
      final activity = _selectedActivity;
      final activityName = _headerKey.currentState?.activityName ?? '';
      final name = activity?.name ?? (activityName.isEmpty ? 'Untitled' : activityName);
      final value = double.tryParse(_valueController.text) ?? 0;

      final linkage = _linkageEngine.autoLink(
        loggedAt: _loggedAt,
        scheduleJson: activity?.schedule,
      );

      // Build field values
      final fieldValues = <String, dynamic>{};
      if (_fieldId != null) {
        fieldValues[_fieldId!] = value;
      } else {
        // Ad-hoc metric: store with the editable label
        fieldValues['metric_value'] = value;
        fieldValues['metric_label'] = _labelController.text;
      }
      final unit = _unitController.text.trim();
      if (unit.isNotEmpty) fieldValues['unit'] = unit;

      // Template field values
      for (final e in _fieldControllers.entries) {
        final text = e.value.text.trim();
        if (text.isNotEmpty) {
          final asNum = num.tryParse(text);
          fieldValues[e.key] = asNum ?? text;
        }
      }

      // Ad-hoc and preset field values from More Details
      final detailValues = _detailsKey.currentState?.collectFieldValues() ?? {};
      fieldValues.addAll(detailValues);

      // Activity location from current GPS
      final location = ref.read(userLocationProvider).valueOrNull;
      if (location != null) {
        fieldValues['activity_location_lat'] = location.latitude;
        fieldValues['activity_location_lng'] = location.longitude;
      }

      // Expected start/end from schedule time window
      if (activity?.schedule != null) {
        final expected = PeriodEngine.resolveExpectedTimes(
          scheduleJson: activity!.schedule,
          date: DateTime.now(),
        );
        if (expected.start != null) {
          fieldValues['expected_start'] = expected.start!.toIso8601String();
        }
        if (expected.end != null) {
          fieldValues['expected_end'] = expected.end!.toIso8601String();
        }
      }

      final entry = Entry(
        id: _uuid.v4(),
        userId: ref.read(currentUserIdProvider),
        name: name,
        activityId: activity?.id,
        periodStart: linkage.linkedPeriod?.start,
        periodEnd: linkage.linkedPeriod?.end,
        linkType: linkage.linkType,
        fieldValues: fieldValues,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        loggedAt: _loggedAt,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(entryRepositoryProvider).save(entry);
      refreshAllEntryProviders(ref);
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
