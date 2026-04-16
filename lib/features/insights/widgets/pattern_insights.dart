// ═══════════════════════════════════════════════════════════════════
// PATTERN_INSIGHTS.DART — Auto-Generated Pattern Analysis
// 6 pattern types, minimum data threshold before showing.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../../../core/theme/kitab_theme.dart';

enum PatternType { bestDay, bestTime, consistency, correlation, trend, anomaly }

class PatternInsight {
  final PatternType type;
  final String title;
  final String description;
  final String emoji;

  const PatternInsight({required this.type, required this.title, required this.description, required this.emoji});
}

class PatternInsightsSection extends StatelessWidget {
  final List<PatternInsight> insights;
  final int minimumEntries;

  const PatternInsightsSection({super.key, this.insights = const [], this.minimumEntries = 14});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('💡', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text('Patterns', style: KitabTypography.h3),
          ],
        ),
        const SizedBox(height: KitabSpacing.md),

        if (insights.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(KitabSpacing.xl),
            decoration: BoxDecoration(border: Border.all(color: KitabColors.gray200), borderRadius: KitabRadii.borderMd),
            child: Column(
              children: [
                Text('📊', style: const TextStyle(fontSize: 32)),
                const SizedBox(height: KitabSpacing.sm),
                Text('Need more data', style: KitabTypography.h3),
                const SizedBox(height: KitabSpacing.xs),
                Text('Track for at least $minimumEntries days to see patterns.', style: KitabTypography.body.copyWith(color: KitabColors.gray400), textAlign: TextAlign.center),
              ],
            ),
          )
        else
          ...insights.map((i) => _PatternCard(insight: i)),
      ],
    );
  }

  /// Generate patterns from entry data. Call this with actual data.
  static List<PatternInsight> analyze({
    required Map<int, int> entriesByWeekday, // 1=Mon..7=Sun → count
    required Map<int, int> entriesByHour,    // 0-23 → count
    required int totalEntries,
  }) {
    final patterns = <PatternInsight>[];
    if (totalEntries < 14) return patterns;

    // 1. Best Day
    if (entriesByWeekday.isNotEmpty) {
      final bestDay = entriesByWeekday.entries.reduce((a, b) => a.value > b.value ? a : b);
      const dayNames = {1: 'Monday', 2: 'Tuesday', 3: 'Wednesday', 4: 'Thursday', 5: 'Friday', 6: 'Saturday', 7: 'Sunday'};
      patterns.add(PatternInsight(
        type: PatternType.bestDay,
        title: 'Most Active Day',
        description: 'You\'re most active on ${dayNames[bestDay.key]}s (${bestDay.value} entries)',
        emoji: '📅',
      ));
    }

    // 2. Best Time
    if (entriesByHour.isNotEmpty) {
      final bestHour = entriesByHour.entries.reduce((a, b) => a.value > b.value ? a : b);
      final period = bestHour.key < 12 ? 'morning' : bestHour.key < 17 ? 'afternoon' : 'evening';
      patterns.add(PatternInsight(
        type: PatternType.bestTime,
        title: 'Peak Activity Time',
        description: 'You tend to log activities in the $period',
        emoji: '⏰',
      ));
    }

    // 3. Consistency
    final avgPerDay = totalEntries / 30;
    if (avgPerDay >= 1) {
      patterns.add(PatternInsight(
        type: PatternType.consistency,
        title: 'Consistent Tracker',
        description: 'You average ${avgPerDay.toStringAsFixed(1)} entries per day — great consistency!',
        emoji: '🎯',
      ));
    }

    return patterns;
  }
}

class _PatternCard extends StatelessWidget {
  final PatternInsight insight;
  const _PatternCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: KitabSpacing.sm),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: KitabColors.info.withValues(alpha: 0.05), borderRadius: KitabRadii.borderMd, border: Border.all(color: KitabColors.info.withValues(alpha: 0.2))),
      child: Row(
        children: [
          Text(insight.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title, style: KitabTypography.body.copyWith(fontWeight: FontWeight.w600)),
                Text(insight.description, style: KitabTypography.bodySmall.copyWith(color: KitabColors.gray500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
