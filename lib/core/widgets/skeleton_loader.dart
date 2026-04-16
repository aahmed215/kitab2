// ═══════════════════════════════════════════════════════════════════
// SKELETON_LOADER.DART — Shimmer Skeleton Loading Widgets
// Used as placeholders while data loads. Provides a polished
// loading experience instead of blank screens or spinners.
// See SPEC.md §17.2 for specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../theme/kitab_theme.dart';

/// A shimmer effect widget that wraps skeleton shapes.
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? KitabColors.gray800 : KitabColors.gray100;
    final highlightColor = isDark ? KitabColors.gray700 : KitabColors.gray200;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton for a card-like element.
class SkeletonCard extends StatelessWidget {
  final double height;

  const SkeletonCard({super.key, this.height = 70});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KitabSpacing.sm),
      child: ShimmerBox(
        width: double.infinity,
        height: height,
        borderRadius: 12,
      ),
    );
  }
}

/// Skeleton for a text line.
class SkeletonText extends StatelessWidget {
  final double width;
  final double height;

  const SkeletonText({super.key, this.width = 120, this.height = 14});

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(
      width: width,
      height: height,
      borderRadius: 4,
    );
  }
}

/// Skeleton for the Home screen summary card.
class HomeSummarySkeleton extends StatelessWidget {
  const HomeSummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ShimmerBox(width: double.infinity, height: 140, borderRadius: 12),
        const SizedBox(height: KitabSpacing.lg),
        const SkeletonText(width: 180),
        const SizedBox(height: KitabSpacing.md),
        ...List.generate(3, (_) => const SkeletonCard()),
      ],
    );
  }
}

/// Skeleton for the Book screen entry list.
class BookEntrySkeleton extends StatelessWidget {
  const BookEntrySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(KitabSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonText(width: 140, height: 18),
          const SizedBox(height: KitabSpacing.md),
          ...List.generate(5, (_) => const SkeletonCard(height: 60)),
        ],
      ),
    );
  }
}
