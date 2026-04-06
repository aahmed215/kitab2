// ═══════════════════════════════════════════════════════════════════
// STREAK_BADGE.DART — Streak Display Badge
// Shows 🔥 Xd for active streaks, 🧊 Xd for frozen streaks.
// Uses accent gold color. JetBrains Mono font for numbers.
// See SPEC.md §4.4 Data Display Components.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../theme/kitab_theme.dart';

/// Displays a streak badge with fire (active) or ice (frozen) icon.
/// Example: 🔥 14d or 🧊 14d
class StreakBadge extends StatelessWidget {
  /// The current streak count
  final int count;

  /// Whether the streak is frozen (pending items exist)
  final bool isFrozen;

  const StreakBadge({
    super.key,
    required this.count,
    this.isFrozen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fire or ice emoji
        Text(
          isFrozen ? '🧊' : '🔥',
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(width: 3),
        // Streak count with unit
        Text(
          '${count}d',
          style: KitabTypography.monoSmall.copyWith(
            color: KitabColors.accent,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
