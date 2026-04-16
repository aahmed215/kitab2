// ═══════════════════════════════════════════════════════════════════
// TIMER_MINI_BAR.DART — Mini-player bar for active timers
// Shows timer chips above the bottom nav / at the bottom of viewport.
// Tapping a chip reopens the full timer sheet.
// Up to 3 timers shown side by side.
// See SPEC.md §7.3 (Mini-Timer Widget) for specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/timer_provider.dart';
import '../theme/kitab_theme.dart';

/// Callback when a timer chip is tapped (to reopen the full sheet).
typedef OnTimerTapped = void Function(String timerId);

/// Mini-bar showing active timer chips.
/// Place this in the AppShell above the bottom nav.
class TimerMiniBar extends ConsumerWidget {
  final OnTimerTapped onTimerTapped;

  const TimerMiniBar({super.key, required this.onTimerTapped});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timers = ref.watch(activeTimersProvider);

    if (timers.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: KitabSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          // Timer chips (leave room for FAB on the right)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: timers.map((timer) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _TimerChip(
                    timer: timer,
                    onTap: () => onTimerTapped(timer.id),
                  ),
                )).toList(),
              ),
            ),
          ),
          // Gap for FAB
          const SizedBox(width: 64),
        ],
      ),
    );
  }
}

class _TimerChip extends StatelessWidget {
  final TimerState timer;
  final VoidCallback onTap;

  const _TimerChip({required this.timer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final elapsed = timer.elapsed;
    final m = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final timeStr = elapsed.inHours > 0
        ? '${elapsed.inHours}:$m:$s'
        : '$m:$s';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: timer.isRunning
              ? KitabColors.primary.withValues(alpha: 0.1)
              : KitabColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: timer.isRunning ? KitabColors.primary : KitabColors.warning,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              timer.isRunning ? Icons.timer : Icons.pause_circle_outline,
              size: 16,
              color: timer.isRunning ? KitabColors.primary : KitabColors.warning,
            ),
            const SizedBox(width: 6),
            // Activity name (truncated)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                timer.activityName,
                style: KitabTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: timer.isRunning ? KitabColors.primary : KitabColors.warning,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            // Elapsed time
            Text(
              timeStr,
              style: KitabTypography.mono.copyWith(
                fontSize: 12,
                color: timer.isRunning ? KitabColors.primary : KitabColors.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
