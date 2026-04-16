// ═══════════════════════════════════════════════════════════════════
// FAB_SPEED_DIAL.DART — Floating Action Button Arc Speed Dial
// Platform-aware:
//   Web: Single click → 4 options flat (Timer, Habit, Metric, Condition)
//   Native: Tap → Layer 1 (Record Activity, Start Condition)
//           Tap Record Activity → Layer 2 (Timer, Habit, Metric)
//           Long press → Skip to Layer 2
// See SPEC.md §7 for full specification.
// ═══════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../theme/kitab_theme.dart';

/// The speed dial options for quick log types.
enum QuickLogType { timer, habit, metric }

/// Callback types for the FAB.
typedef OnStartCondition = void Function();
typedef OnQuickLog = void Function(QuickLogType type);

/// Arc speed dial FAB — platform-aware.
class FabSpeedDial extends StatefulWidget {
  final OnStartCondition onStartCondition;
  final OnQuickLog onQuickLog;

  const FabSpeedDial({
    super.key,
    required this.onStartCondition,
    required this.onQuickLog,
  });

  @override
  State<FabSpeedDial> createState() => _FabSpeedDialState();
}

class _FabSpeedDialState extends State<FabSpeedDial>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  int _layer = 0; // 0=closed, 1=Layer 1 (native only), 2=Layer 2 / flat (web)

  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      if (kIsWeb) {
        // Web: single click → flat 4 options
        _openFlat();
      } else {
        // Native: tap → Layer 1
        _openLayer1();
      }
    }
  }

  void _openLayer1() {
    setState(() { _isOpen = true; _layer = 1; });
    _controller.forward();
  }

  void _openLayer2() {
    // Transition from Layer 1 to Layer 2 (native only)
    _controller.reverse().then((_) {
      if (mounted) {
        setState(() => _layer = 2);
        _controller.forward();
      }
    });
  }

  void _openFlat() {
    // Web: all 4 options in one arc
    setState(() { _isOpen = true; _layer = 2; });
    _controller.forward();
  }

  void _close() {
    _controller.reverse().then((_) {
      if (mounted) setState(() { _isOpen = false; _layer = 0; });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 360,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // ─── Scrim ───
          if (_isOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _close,
                child: Container(color: Colors.transparent),
              ),
            ),

          // ─── Arc Items ───
          if (_isOpen) ..._buildArcItems(),

          // ─── Main FAB ───
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              // Long press: native only → skip to Layer 2
              onLongPress: kIsWeb ? null : () {
                if (!_isOpen) {
                  setState(() { _isOpen = true; _layer = 2; });
                  _controller.forward();
                }
              },
              child: FloatingActionButton(
                onPressed: _toggle,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _animation.value * math.pi / 4, // + → ✕
                      child: const Icon(Icons.add),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildArcItems() {
    if (kIsWeb) {
      // Web: flat 4 options
      return _buildWebItems();
    }
    if (_layer == 1) {
      return _buildNativeLayer1();
    } else if (_layer == 2) {
      return _buildNativeLayer2();
    }
    return [];
  }

  // ─── Web: 4 flat options in one arc ───
  List<Widget> _buildWebItems() {
    final items = [
      _ArcItem(
        label: 'Start Timer',
        icon: Icons.timer,
        color: KitabColors.primary,
        onTap: () { _close(); widget.onQuickLog(QuickLogType.timer); },
      ),
      _ArcItem(
        label: 'Log Habit',
        icon: Icons.check_circle_outline,
        color: KitabColors.success,
        onTap: () { _close(); widget.onQuickLog(QuickLogType.habit); },
      ),
      _ArcItem(
        label: 'Log Metric',
        icon: Icons.speed,
        color: KitabColors.accent,
        onTap: () { _close(); widget.onQuickLog(QuickLogType.metric); },
      ),
      _ArcItem(
        label: 'Condition',
        icon: Icons.healing,
        color: KitabColors.warning,
        onTap: () { _close(); widget.onStartCondition(); },
      ),
    ];
    return _positionOnArc(items);
  }

  // ─── Native Layer 1: Record Activity + Start Condition ───
  List<Widget> _buildNativeLayer1() {
    final items = [
      _ArcItem(
        label: 'Record Activity',
        icon: Icons.edit_note,
        color: KitabColors.primary,
        onTap: () { _openLayer2(); },
      ),
      _ArcItem(
        label: 'Start Condition',
        icon: Icons.healing,
        color: KitabColors.accent,
        onTap: () { _close(); widget.onStartCondition(); },
      ),
    ];
    return _positionOnArc(items);
  }

  // ─── Native Layer 2: Timer + Habit + Metric ───
  List<Widget> _buildNativeLayer2() {
    final items = [
      _ArcItem(
        label: 'Timer',
        icon: Icons.timer,
        color: KitabColors.primary,
        onTap: () { _close(); widget.onQuickLog(QuickLogType.timer); },
      ),
      _ArcItem(
        label: 'Habit',
        icon: Icons.check_circle_outline,
        color: KitabColors.success,
        onTap: () { _close(); widget.onQuickLog(QuickLogType.habit); },
      ),
      _ArcItem(
        label: 'Metric',
        icon: Icons.speed,
        color: KitabColors.accent,
        onTap: () { _close(); widget.onQuickLog(QuickLogType.metric); },
      ),
    ];
    return _positionOnArc(items);
  }

  /// Position items vertically, stacked above the FAB with even spacing.
  /// Labels to the left, buttons on the right (aligned with the FAB).
  List<Widget> _positionOnArc(List<_ArcItem> items) {
    const spacing = 52.0; // vertical distance between items
    const fabSize = 56.0;

    return List.generate(items.length, (index) {
      // Stack items upward from the FAB position
      final bottomOffset = fabSize + 8 + (spacing * (index + 1));

      return Positioned(
        right: 0, // Align buttons with the FAB's right edge
        bottom: bottomOffset,
        child: ScaleTransition(
          scale: _animation,
          child: _buildArcButton(items[index]),
        ),
      );
    });
  }

  Widget _buildArcButton(_ArcItem item) {
    // Always: label to the left, button to the right.
    // This ensures nothing extends past the right edge of the container.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(6),
            boxShadow: KitabShadows.level1,
          ),
          child: Text(
            item.label,
            style: KitabTypography.caption.copyWith(color: KitabColors.gray700),
          ),
        ),
        const SizedBox(width: 6),
        FloatingActionButton.small(
          heroTag: item.label,
          backgroundColor: item.color,
          foregroundColor: Colors.white,
          onPressed: item.onTap,
          child: Icon(item.icon, size: 20),
        ),
      ],
    );
  }
}

class _ArcItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ArcItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
