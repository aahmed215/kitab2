// ═══════════════════════════════════════════════════════════════════
// ACCESSIBLE_TAP.DART — Accessible Tap Target Wrapper
// Ensures minimum 48x48 touch target and provides semantic labels.
// See SPEC.md §17.1 for accessibility specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

/// Wraps a widget with proper semantic label and minimum touch target.
class AccessibleTap extends StatelessWidget {
  final Widget child;
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? hint;
  final bool isButton;

  const AccessibleTap({
    super.key,
    required this.child,
    required this.label,
    this.onTap,
    this.onLongPress,
    this.hint,
    this.isButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: isButton,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Utility extension to add semantic labels to any widget.
extension SemanticLabel on Widget {
  Widget withSemantics({
    required String label,
    String? hint,
    bool button = false,
    bool header = false,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: button,
      header: header,
      child: this,
    );
  }
}
