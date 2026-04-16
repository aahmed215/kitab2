// ═══════════════════════════════════════════════════════════════════
// TIME_OF_DAY_BACKGROUND.DART — 5-Phase Visual Adaptation
// Dawn (5-7), Morning (7-12), Afternoon (12-17), Sunset (17-19),
// Night (19-5). Changes background tint of the summary card.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../theme/kitab_theme.dart';

enum TimePhase { dawn, morning, afternoon, sunset, night }

class TimeOfDayTheme {
  const TimeOfDayTheme._();

  static TimePhase get currentPhase {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 7) return TimePhase.dawn;
    if (hour >= 7 && hour < 12) return TimePhase.morning;
    if (hour >= 12 && hour < 17) return TimePhase.afternoon;
    if (hour >= 17 && hour < 19) return TimePhase.sunset;
    return TimePhase.night;
  }

  static Color tintColor(TimePhase phase) {
    return switch (phase) {
      TimePhase.dawn => const Color(0xFFFFF3E0),     // Warm amber
      TimePhase.morning => const Color(0xFFF1F8E9),   // Fresh green
      TimePhase.afternoon => const Color(0xFFFFFDE7),  // Bright yellow
      TimePhase.sunset => const Color(0xFFFBE9E7),     // Warm orange
      TimePhase.night => const Color(0xFFE8EAF6),      // Cool indigo
    };
  }

  static Color tintColorDark(TimePhase phase) {
    return switch (phase) {
      TimePhase.dawn => const Color(0xFF2E2209),
      TimePhase.morning => const Color(0xFF1B2E12),
      TimePhase.afternoon => const Color(0xFF2E2C0A),
      TimePhase.sunset => const Color(0xFF2E1A12),
      TimePhase.night => const Color(0xFF1A1C2E),
    };
  }

  static String emoji(TimePhase phase) {
    return switch (phase) {
      TimePhase.dawn => '🌅',
      TimePhase.morning => '☀️',
      TimePhase.afternoon => '🌤️',
      TimePhase.sunset => '🌇',
      TimePhase.night => '🌙',
    };
  }

  static String label(TimePhase phase) {
    return switch (phase) {
      TimePhase.dawn => 'Dawn',
      TimePhase.morning => 'Morning',
      TimePhase.afternoon => 'Afternoon',
      TimePhase.sunset => 'Sunset',
      TimePhase.night => 'Night',
    };
  }
}

/// Wraps a widget with a time-of-day tinted background.
class TimeOfDayTint extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;

  const TimeOfDayTint({super.key, required this.child, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final phase = TimeOfDayTheme.currentPhase;
    final tint = isDark ? TimeOfDayTheme.tintColorDark(phase) : TimeOfDayTheme.tintColor(phase);

    return Container(
      decoration: BoxDecoration(
        color: tint,
        borderRadius: borderRadius ?? KitabRadii.borderMd,
      ),
      child: child,
    );
  }
}
