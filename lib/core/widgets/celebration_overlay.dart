// ═══════════════════════════════════════════════════════════════════
// CELEBRATION_OVERLAY.DART — All-Done Shimmer Celebration
// Gold shimmer particle animation on milestone streaks.
// Shows when all goals are met for the day.
// ═══════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/kitab_theme.dart';
import 'kitab_toast.dart';

/// Shows a brief gold shimmer celebration overlay.
class CelebrationOverlay extends StatefulWidget {
  final Widget child;
  final bool celebrate;

  const CelebrationOverlay({super.key, required this.child, this.celebrate = false});

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _showParticles = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _showParticles = false);
      }
    });
  }

  @override
  void didUpdateWidget(CelebrationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.celebrate && !oldWidget.celebrate) {
      setState(() => _showParticles = true);
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showParticles)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(painter: _ShimmerParticlePainter(progress: _controller.value));
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _ShimmerParticlePainter extends CustomPainter {
  final double progress;
  final _random = math.Random(42);

  _ShimmerParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final opacity = (1 - progress).clamp(0.0, 1.0);

    for (var i = 0; i < 30; i++) {
      final x = _random.nextDouble() * size.width;
      final startY = _random.nextDouble() * size.height;
      final y = startY - (progress * 100 * (1 + _random.nextDouble()));
      final particleSize = 2 + _random.nextDouble() * 4;

      paint.color = (i % 3 == 0 ? KitabColors.accent : KitabColors.primary).withValues(alpha: opacity * (0.3 + _random.nextDouble() * 0.7));

      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ShimmerParticlePainter oldDelegate) => oldDelegate.progress != progress;
}

/// Shows a celebratory snackbar for streak milestones.
void showStreakMilestone(BuildContext context, int count) {
  final milestone = switch (count) {
    7 => '1 Week',
    14 => '2 Weeks',
    21 => '3 Weeks',
    30 => '1 Month',
    60 => '2 Months',
    90 => '3 Months',
    100 => '100 Days',
    180 => '6 Months',
    365 => '1 Year',
    _ => null,
  };

  if (milestone == null) return;

  KitabToast.success(context, '$milestone streak! Amazing dedication!');
}
