// ═══════════════════════════════════════════════════════════════════
// KITAB_COLORS.DART — Color Palette
// All colors from the Kitab design system.
// Inspired by Islamic art: deep teal, warm gold, warm grays.
// See SPEC.md §3.1 for full documentation.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

/// Kitab's complete color palette.
/// Never use raw hex colors in widgets — always reference these tokens.
class KitabColors {
  KitabColors._(); // Prevent instantiation

  // ─── Primary — Deep Teal/Emerald ───
  // Inspired by turquoise tiles in Islamic mosques
  static const Color primary = Color(0xFF0D7377);
  static const Color primaryLight = Color(0xFF14A3A8);
  static const Color primaryDark = Color(0xFF095456);

  // ─── Accent — Warm Gold/Amber (Aged/Antique) ───
  // Inspired by illuminated Quran manuscripts
  static const Color accent = Color(0xFFC8963E);
  static const Color accentLight = Color(0xFFE8B960);
  static const Color accentDark = Color(0xFF9A7230);

  // ─── Neutrals — Warm Grays ───
  // Evoke aged paper and stone — tied to the "book" metaphor
  static const Color white = Color(0xFFFAFAF8);
  static const Color gray50 = Color(0xFFF5F4F2);
  static const Color gray100 = Color(0xFFE8E6E3);
  static const Color gray200 = Color(0xFFD4D1CC);
  static const Color gray300 = Color(0xFFB8B4AE);
  static const Color gray400 = Color(0xFF9C9790);
  static const Color gray500 = Color(0xFF7A756E);
  static const Color gray600 = Color(0xFF5C5850);
  static const Color gray700 = Color(0xFF3E3B35);
  static const Color gray800 = Color(0xFF2A2722);
  static const Color gray900 = Color(0xFF1A1815);
  static const Color black = Color(0xFF121110);

  // ─── Semantic Colors ───
  // NEVER use alone to convey meaning — always pair with icon/label
  static const Color success = Color(0xFF2D8659);
  static const Color warning = Color(0xFFC4841D);
  static const Color error = Color(0xFFC43D3D);
  static const Color info = Color(0xFF2D6B8A);

  // ─── Light Theme Colors ───
  static const Color lightBackground = white;
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = gray900;
  static const Color lightTextSecondary = gray600;
  static const Color lightBorder = gray100;

  // ─── Dark Theme Colors ───
  static const Color darkBackground = black;
  static const Color darkSurface = gray900;
  static const Color darkTextPrimary = gray50;
  static const Color darkTextSecondary = gray400;
  static const Color darkBorder = gray700;
}
