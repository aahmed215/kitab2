// ═══════════════════════════════════════════════════════════════════
// KITAB_CARD.DART — Reusable Card Component
// Standard card with optional category color left border.
// Level 1 shadow in light mode, border in dark mode.
// See SPEC.md §4.4 for component specifications.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../theme/kitab_theme.dart';

/// A styled card that follows the Kitab design system.
/// Optionally shows a colored left border (for category-coded entries).
class KitabCard extends StatelessWidget {
  /// The card content
  final Widget child;

  /// Optional left border color (category color for activity entries)
  /// When null, no left border is shown.
  final Color? borderColor;

  /// Card padding. Defaults to 14px horizontal, 13px vertical.
  final EdgeInsetsGeometry? padding;

  /// Called when the card is tapped
  final VoidCallback? onTap;

  /// Called when the card is long-pressed
  final VoidCallback? onLongPress;

  /// Whether the card appears faded (for completed/excused items)
  final bool faded;

  const KitabCard({
    super.key,
    required this.child,
    this.borderColor,
    this.padding,
    this.onTap,
    this.onLongPress,
    this.faded = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Opacity(
      opacity: faded ? 0.6 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? KitabColors.darkSurface : KitabColors.lightSurface,
            borderRadius: KitabRadii.borderMd,
            boxShadow: isDark ? null : KitabShadows.level1,
            border: isDark
                ? Border.all(color: KitabColors.darkBorder)
                : null,
          ),
          child: ClipRRect(
            borderRadius: KitabRadii.borderMd,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── Optional Left Border ───
                  if (borderColor != null)
                    Container(
                      width: 5,
                      color: borderColor,
                    ),

                  // ─── Card Content ───
                  Expanded(
                    child: Padding(
                      padding: padding ??
                          const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
