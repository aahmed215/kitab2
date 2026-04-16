// ═══════════════════════════════════════════════════════════════════
// KITAB_TYPOGRAPHY.DART — Typography System
// Font families: DM Serif Display (headings), Inter (body),
// JetBrains Mono (data), Amiri (Arabic text).
// Type scale based on Major Third ratio (1.250).
//
// IMPORTANT: Colors are NOT set here. Text inherits color from
// the theme so it automatically adapts to light/dark mode.
// Use .copyWith(color: ...) when you need a specific color.
// See SPEC.md §3.2 for full documentation.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography tokens for the Kitab design system.
/// Colors are intentionally omitted — text inherits from the theme
/// so it works in both light and dark mode automatically.
class KitabTypography {
  KitabTypography._();

  // ─── Heading Font — DM Serif Display ───

  /// Display — 32px Bold. Screen titles, big streak numbers.
  static TextStyle get display => GoogleFonts.dmSerifDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w700,
      );

  /// H1 — 26px Semibold. Section headers.
  static TextStyle get h1 => GoogleFonts.dmSerifDisplay(
        fontSize: 26,
        fontWeight: FontWeight.w600,
      );

  /// H2 — 21px Semibold. Sub-section headers.
  static TextStyle get h2 => GoogleFonts.dmSerifDisplay(
        fontSize: 21,
        fontWeight: FontWeight.w600,
      );

  // ─── Body Font — Inter ───

  /// H3 — 17px Medium. Card titles, list headers.
  static TextStyle get h3 => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w500,
      );

  /// Body Large — 17px Regular. Primary body text.
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w400,
      );

  /// Body — 15px Regular. Standard body text.
  static TextStyle get body => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
      );

  /// Body Small — 13px Regular. Secondary info, captions.
  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
      );

  /// Caption — 11px Medium. Labels, timestamps, badges.
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      );

  // ─── Mono Font — JetBrains Mono ───

  /// Mono — 16px Medium. Timer displays, streak numbers.
  static TextStyle get mono => GoogleFonts.jetBrainsMono(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      );

  /// Mono Small — 12px Regular. Inline data, durations.
  static TextStyle get monoSmall => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      );

  // ─── Arabic Font — Amiri ───

  /// Arabic — 16px Regular. For Arabic text content.
  static TextStyle get arabic => GoogleFonts.amiri(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      );
}
