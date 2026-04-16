// ═══════════════════════════════════════════════════════════════════
// START_CONDITION_SHEET.DART — Start Condition Bottom Sheet
// Pick a preset (or custom), set start date, activate condition.
// See SPEC.md §5.8 for specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/database_providers.dart';
import '../../core/theme/kitab_theme.dart';
import '../../data/models/condition.dart';


const _uuid = Uuid();

Future<bool?> showStartConditionSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.85,
      maxWidth: MediaQuery.of(context).size.width > 600 ? 560.0 : double.infinity,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.55,
      child: const _StartConditionSheet(),
    ),
  );
}

class _StartConditionSheet extends ConsumerStatefulWidget {
  const _StartConditionSheet();

  @override
  ConsumerState<_StartConditionSheet> createState() =>
      _StartConditionSheetState();
}

class _StartConditionSheetState extends ConsumerState<_StartConditionSheet> {
  ConditionPreset? _selectedPreset;
  DateTime _startDate = DateTime.now();
  bool _saving = false;
  List<ConditionPreset> _presets = [];
  bool _loadingPresets = true;

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    try {
      final userId = ref.read(currentUserIdProvider);
      final presets = await ref.read(conditionRepositoryProvider).getPresetsByUser(userId);
      if (mounted) setState(() { _presets = presets; _loadingPresets = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingPresets = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KitabColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: KitabSpacing.lg),

          Text('Start Condition', style: KitabTypography.h2),
          const SizedBox(height: KitabSpacing.xs),
          Text(
            'Activities will be auto-excused during this condition',
            style: KitabTypography.bodySmall
                .copyWith(color: KitabColors.gray500),
          ),
          const SizedBox(height: KitabSpacing.lg),

          // Preset chips from database
          if (_loadingPresets)
            const Center(child: Padding(
              padding: EdgeInsets.all(KitabSpacing.lg),
              child: CircularProgressIndicator(),
            ))
          else if (_presets.isEmpty)
            Padding(
              padding: const EdgeInsets.all(KitabSpacing.lg),
              child: Text(
                'No condition presets. Add some in Settings → Condition Presets.',
                style: KitabTypography.body.copyWith(color: KitabColors.gray400),
                textAlign: TextAlign.center,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((preset) {
                final isSelected = _selectedPreset?.id == preset.id;
                return ChoiceChip(
                  label: Text('${preset.emoji} ${preset.label}'),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _selectedPreset = preset);
                  },
                );
              }).toList(),
            ),

          const SizedBox(height: KitabSpacing.lg),

          // Start date
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: const Text('Start Date'),
            subtitle: Text(
              '${_startDate.day}/${_startDate.month}/${_startDate.year}',
            ),
            trailing: const Icon(Icons.edit, size: 18, color: KitabColors.gray400),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _startDate,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _startDate = picked);
            },
          ),

          const SizedBox(height: KitabSpacing.lg),

          // Start button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selectedPreset != null && !_saving ? _start : null,
              child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Start Condition'),
            ),
          ),
          const SizedBox(height: KitabSpacing.md),
        ],
      ),
    );
  }

  Future<void> _start() async {
    if (_selectedPreset == null) return;
    setState(() => _saving = true);

    try {
      final conditionRepo = ref.read(conditionRepositoryProvider);
      final userId = ref.read(currentUserIdProvider);
      final now = DateTime.now();
      final preset = _selectedPreset!;

      // Create condition instance from the selected preset
      final condition = Condition(
        id: _uuid.v4(),
        userId: userId,
        presetId: preset.id,
        label: preset.label,
        emoji: preset.emoji,
        startDate: _startDate,
        createdAt: now,
        updatedAt: now,
      );
      await conditionRepo.saveCondition(condition);

      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
