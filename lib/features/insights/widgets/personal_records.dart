// ═══════════════════════════════════════════════════════════════════
// PERSONAL_RECORDS.DART — All-Time Personal Records
// Gold accent, NEW badge for recently broken records.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../../../core/theme/kitab_theme.dart';

class PersonalRecord {
  final String label;
  final String value;
  final String? unit;
  final DateTime achievedAt;
  final bool isNew;

  const PersonalRecord({required this.label, required this.value, this.unit, required this.achievedAt, this.isNew = false});
}

class PersonalRecordsSection extends StatelessWidget {
  final List<PersonalRecord> records;

  const PersonalRecordsSection({super.key, this.records = const []});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text('Personal Records', style: KitabTypography.h3),
          ],
        ),
        const SizedBox(height: KitabSpacing.md),

        if (records.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(KitabSpacing.xl),
            decoration: BoxDecoration(border: Border.all(color: KitabColors.gray200), borderRadius: KitabRadii.borderMd),
            child: Text('Keep tracking to set personal records!', style: KitabTypography.body.copyWith(color: KitabColors.gray400), textAlign: TextAlign.center),
          )
        else
          ...records.map((r) => _RecordTile(record: r)),
      ],
    );
  }
}

class _RecordTile extends StatelessWidget {
  final PersonalRecord record;
  const _RecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: KitabSpacing.sm),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KitabColors.accent.withValues(alpha: 0.05),
        borderRadius: KitabRadii.borderSm,
        border: Border.all(color: KitabColors.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Text('🥇', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(record.label, style: KitabTypography.body.copyWith(fontWeight: FontWeight.w500)),
                    if (record.isNew) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: KitabColors.accent, borderRadius: BorderRadius.circular(4)),
                        child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                Text('${record.value}${record.unit != null ? ' ${record.unit}' : ''}', style: KitabTypography.mono.copyWith(color: KitabColors.accent)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
