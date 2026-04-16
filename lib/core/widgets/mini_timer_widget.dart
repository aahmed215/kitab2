// ═══════════════════════════════════════════════════════════════════
// MINI_TIMER_WIDGET.DART — Floating Timer Above Bottom Nav
// Shows up to 3 active timers. Marquee for long names.
// Active timer is highlighted. Tap to expand.
// ═══════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/kitab_theme.dart';

/// An active timer entry.
class ActiveTimer {
  final String id;
  final String activityName;
  final DateTime startedAt;
  bool isPaused;

  ActiveTimer({required this.id, required this.activityName, required this.startedAt, this.isPaused = false});
}

/// Global state for active timers.
final activeTimersProvider = StateNotifierProvider<ActiveTimersNotifier, List<ActiveTimer>>((ref) {
  return ActiveTimersNotifier();
});

class ActiveTimersNotifier extends StateNotifier<List<ActiveTimer>> {
  ActiveTimersNotifier() : super([]);

  void addTimer(ActiveTimer timer) {
    if (state.length >= 3) return; // Max 3 timers
    state = [...state, timer];
  }

  void removeTimer(String id) {
    state = state.where((t) => t.id != id).toList();
  }

  void togglePause(String id) {
    state = state.map((t) {
      if (t.id == id) t.isPaused = !t.isPaused;
      return t;
    }).toList();
  }
}

/// Floating mini-timer bar shown above the bottom navigation.
class MiniTimerBar extends ConsumerStatefulWidget {
  const MiniTimerBar({super.key});

  @override
  ConsumerState<MiniTimerBar> createState() => _MiniTimerBarState();
}

class _MiniTimerBarState extends ConsumerState<MiniTimerBar> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timers = ref.watch(activeTimersProvider);
    if (timers.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: KitabSpacing.md),
      decoration: BoxDecoration(
        color: KitabColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: KitabShadows.level2,
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.timer, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: timers.length,
              separatorBuilder: (_, __) => const VerticalDivider(color: Colors.white24, indent: 8, endIndent: 8),
              itemBuilder: (context, index) {
                final timer = timers[index];
                final elapsed = timer.isPaused ? Duration.zero : DateTime.now().difference(timer.startedAt);
                return Center(
                  child: Text(
                    '${timer.activityName} ${_fmt(elapsed)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
