// ═══════════════════════════════════════════════════════════════════
// BREAKPOINTS.DART — Responsive Breakpoints
// Defines viewport breakpoints and helper methods for adaptive layouts.
// Phone < 600px, Tablet 600-1024px, Desktop > 1024px.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

/// Responsive breakpoint values and helper methods.
/// Use these to build adaptive layouts across phone, tablet, and desktop.
class Breakpoints {
  Breakpoints._();

  /// Phone: width < 600px
  static const double phone = 600;

  /// Tablet: 600px <= width < 1024px
  static const double tablet = 1024;

  /// Maximum content width for desktop layouts
  static const double maxContentWidth = 600;

  /// Icon rail width (tablet + desktop web)
  static const double iconRailWidth = 56;

  /// Check if the current viewport is phone-sized
  static bool isPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < phone;

  /// Check if the current viewport is tablet-sized
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= phone && width < tablet;
  }

  /// Check if the current viewport is desktop-sized
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;
}
