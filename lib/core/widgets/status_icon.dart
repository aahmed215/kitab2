// ═══════════════════════════════════════════════════════════════════
// STATUS_ICON.DART — Activity Status Icon
// Shows the current status of an activity period.
// ○ In progress, ✓ Completed, ? Pending, ⊘ Excused, — Missed
// See SPEC.md §14.1 Home Screen status icons.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../theme/kitab_theme.dart';

/// The possible statuses for an activity period.
enum ActivityStatus {
  /// Period is active, not yet completed
  inProgress,

  /// Entry linked, goal met
  completed,

  /// Past period, not yet addressed
  pending,

  /// Period excused with a reason
  excused,

  /// Period confirmed missed
  missed,
}

/// A 26x26 rounded square icon showing the activity status.
/// Color-coded per the design system semantic colors.
class StatusIcon extends StatelessWidget {
  final ActivityStatus status;

  const StatusIcon({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(7),
      ),
      alignment: Alignment.center,
      child: Text(
        _symbol,
        style: TextStyle(
          fontSize: status == ActivityStatus.excused ? 14 : 12,
          fontWeight: FontWeight.w700,
          color: _foregroundColor,
        ),
      ),
    );
  }

  /// The symbol displayed inside the icon
  String get _symbol {
    switch (status) {
      case ActivityStatus.inProgress:
        return '○';
      case ActivityStatus.completed:
        return '✓';
      case ActivityStatus.pending:
        return '?';
      case ActivityStatus.excused:
        return '⊘';
      case ActivityStatus.missed:
        return '—';
    }
  }

  /// Background color based on status
  Color get _backgroundColor {
    switch (status) {
      case ActivityStatus.inProgress:
        return KitabColors.gray200;
      case ActivityStatus.completed:
        return KitabColors.success;
      case ActivityStatus.pending:
        return KitabColors.warning;
      case ActivityStatus.excused:
        return KitabColors.info;
      case ActivityStatus.missed:
        return KitabColors.error;
    }
  }

  /// Foreground (text) color based on status
  Color get _foregroundColor {
    switch (status) {
      case ActivityStatus.inProgress:
        return KitabColors.gray500;
      case ActivityStatus.completed:
      case ActivityStatus.pending:
      case ActivityStatus.excused:
      case ActivityStatus.missed:
        return Colors.white;
    }
  }
}
