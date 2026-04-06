// ═══════════════════════════════════════════════════════════════════
// KITAB_SPACING.DART — Spacing, Radii & Elevation
// All spacing tokens from the Kitab design system.
// Based on a 4px base unit for consistent rhythm.
// See SPEC.md §3.3–3.5 for full documentation.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

/// Spacing tokens based on 4px base unit.
class KitabSpacing {
  KitabSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Border radius tokens.
/// 12px card radius is the signature — modern but grounded.
class KitabRadii {
  KitabRadii._();

  static const double none = 0;
  static const double sm = 6;
  static const double md = 12; // Signature radius for cards, inputs, buttons
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;

  // Convenience BorderRadius objects
  static final BorderRadius borderSm = BorderRadius.circular(sm);
  static final BorderRadius borderMd = BorderRadius.circular(md);
  static final BorderRadius borderLg = BorderRadius.circular(lg);
  static final BorderRadius borderXl = BorderRadius.circular(xl);
  static final BorderRadius borderFull = BorderRadius.circular(full);
}

/// Elevation / shadow tokens.
/// Warm-toned shadows using neutral-warm rgba.
class KitabShadows {
  KitabShadows._();

  /// No shadow — flat elements
  static const List<BoxShadow> level0 = [];

  /// Subtle lift — cards
  static const List<BoxShadow> level1 = [
    BoxShadow(
      color: Color.fromRGBO(26, 24, 21, 0.08),
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
  ];

  /// Medium — dropdowns, hover cards
  static const List<BoxShadow> level2 = [
    BoxShadow(
      color: Color.fromRGBO(26, 24, 21, 0.12),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  /// Strong — modals, FAB
  static const List<BoxShadow> level3 = [
    BoxShadow(
      color: Color.fromRGBO(26, 24, 21, 0.16),
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
  ];
}

/// Responsive breakpoints.
class KitabBreakpoints {
  KitabBreakpoints._();

  /// Phone: < 600px
  static const double phone = 600;

  /// Tablet: 600–1024px
  static const double tablet = 1024;

  /// Desktop: > 1024px
  static const double desktop = 1024;

  /// Check if the current width is phone-sized
  static bool isPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < phone;

  /// Check if the current width is tablet-sized
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= phone && width < desktop;
  }

  /// Check if the current width is desktop-sized
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;
}
