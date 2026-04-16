// ═══════════════════════════════════════════════════════════════════
// RAMADAN_COMPARISON.DART — Ramadan Period Comparison Widget
// Pre-Ramadan vs During vs Post-Ramadan analytics comparison.
// Also supports year-over-year Ramadan comparison.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../../../core/theme/kitab_theme.dart';

class RamadanComparisonCard extends StatelessWidget {
  final Map<String, double> preRamadan;
  final Map<String, double> duringRamadan;
  final Map<String, double> postRamadan;

  const RamadanComparisonCard({
    super.key,
    this.preRamadan = const {},
    this.duringRamadan = const {},
    this.postRamadan = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ramadan Comparison', style: KitabTypography.h3),
        const SizedBox(height: KitabSpacing.sm),
        Text('Compare your habits across Ramadan periods', style: KitabTypography.bodySmall.copyWith(color: KitabColors.gray500)),
        const SizedBox(height: KitabSpacing.lg),

        Row(
          children: [
            _PeriodColumn(label: 'Pre', emoji: '📅', stats: preRamadan, color: KitabColors.gray500),
            const SizedBox(width: KitabSpacing.sm),
            _PeriodColumn(label: 'Ramadan', emoji: '🌙', stats: duringRamadan, color: KitabColors.primary),
            const SizedBox(width: KitabSpacing.sm),
            _PeriodColumn(label: 'Post', emoji: '📅', stats: postRamadan, color: KitabColors.gray500),
          ],
        ),

        if (preRamadan.isEmpty && duringRamadan.isEmpty && postRamadan.isEmpty)
          Padding(
            padding: const EdgeInsets.all(KitabSpacing.xl),
            child: Center(
              child: Text(
                'Ramadan comparison will appear once you have\ndata spanning a Ramadan period.',
                style: KitabTypography.body.copyWith(color: KitabColors.gray400),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class _PeriodColumn extends StatelessWidget {
  final String label;
  final String emoji;
  final Map<String, double> stats;
  final Color color;

  const _PeriodColumn({required this.label, required this.emoji, required this.stats, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: KitabRadii.borderSm),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(label, style: KitabTypography.caption.copyWith(fontWeight: FontWeight.w600, color: color)),
            const SizedBox(height: 8),
            Text('${(stats['completion_rate'] ?? 0).round()}%', style: KitabTypography.h3.copyWith(color: color)),
            Text('completion', style: KitabTypography.caption.copyWith(color: KitabColors.gray400)),
          ],
        ),
      ),
    );
  }
}
