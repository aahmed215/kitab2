// ═══════════════════════════════════════════════════════════════════
// KITAB_TOAST.DART — Custom Toast / Snackbar
// A styled, auto-dismissing toast that matches the Kitab design system.
// Warm, minimal, and non-intrusive. Use instead of raw SnackBar.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../theme/kitab_theme.dart';

/// Show a styled Kitab toast. Auto-dismisses after [duration].
///
/// Usage:
///   KitabToast.show(context, 'Entry saved');
///   KitabToast.show(context, 'Condition ended', action: ToastAction(label: 'Undo', onPressed: () => ...));
///   KitabToast.error(context, 'Something went wrong');
///   KitabToast.success(context, 'Fajr logged!');
class KitabToast {
  KitabToast._();

  /// Standard informational toast (neutral).
  static void show(
    BuildContext context,
    String message, {
    ToastAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showToast(context, message, action: action, duration: duration);
  }

  /// Success toast (green accent).
  static void success(
    BuildContext context,
    String message, {
    ToastAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showToast(context, message,
        action: action, duration: duration, accentColor: KitabColors.success);
  }

  /// Error toast (red accent).
  static void error(
    BuildContext context,
    String message, {
    ToastAction? action,
    Duration duration = const Duration(seconds: 4),
  }) {
    _showToast(context, message,
        action: action, duration: duration, accentColor: KitabColors.error);
  }

  static void _showToast(
    BuildContext context,
    String message, {
    ToastAction? action,
    Duration duration = const Duration(seconds: 3),
    Color? accentColor,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (accentColor != null) ...[
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                message,
                style: KitabTypography.body.copyWith(
                  color: isDark ? KitabColors.gray50 : KitabColors.gray900,
                ),
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  action.onPressed();
                },
                style: TextButton.styleFrom(
                  foregroundColor: KitabColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(action.label, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
        backgroundColor: isDark ? KitabColors.gray800 : KitabColors.white,
        elevation: 0,
        behavior: SnackBarBehavior.fixed,
        shape: Border(
          top: BorderSide(
            color: isDark ? KitabColors.gray700 : KitabColors.gray200,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: duration,
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }
}

/// An action button for the toast.
class ToastAction {
  final String label;
  final VoidCallback onPressed;

  const ToastAction({required this.label, required this.onPressed});
}
