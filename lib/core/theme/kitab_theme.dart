// ═══════════════════════════════════════════════════════════════════
// KITAB_THEME.DART — App Theme
// Combines colors, typography, and spacing into Material ThemeData.
// Provides both light and dark themes.
// See SPEC.md §3 for full design system documentation.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'kitab_colors.dart';
import 'kitab_spacing.dart';

/// Exports all theme components for easy importing.
export 'kitab_colors.dart';
export 'kitab_spacing.dart';
export 'kitab_typography.dart';

/// Provides Material ThemeData for light and dark modes.
class KitabTheme {
  KitabTheme._();

  // ─── Light Theme ───
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

        // Colors
        colorScheme: ColorScheme.light(
          primary: KitabColors.primary,
          onPrimary: Colors.white,
          secondary: KitabColors.accent,
          onSecondary: Colors.white,
          surface: KitabColors.lightSurface,
          onSurface: KitabColors.lightTextPrimary,
          error: KitabColors.error,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: KitabColors.lightBackground,
        canvasColor: KitabColors.lightBackground,
        dividerColor: KitabColors.lightBorder,

        // Typography
        textTheme: GoogleFonts.interTextTheme().apply(
          bodyColor: KitabColors.lightTextPrimary,
          displayColor: KitabColors.lightTextPrimary,
        ),

        // AppBar
        appBarTheme: AppBarTheme(
          backgroundColor: KitabColors.lightBackground,
          foregroundColor: KitabColors.lightTextPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false, // Left-aligned titles per spec
        ),

        // Cards
        cardTheme: CardThemeData(
          color: KitabColors.lightSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: KitabRadii.borderMd,
          ),
        ),

        // Bottom Navigation
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: KitabColors.lightSurface,
          selectedItemColor: KitabColors.primary,
          unselectedItemColor: KitabColors.gray400,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),

        // Floating Action Button
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: KitabColors.primary,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: const CircleBorder(),
        ),

        // Input fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: KitabColors.lightSurface,
          border: OutlineInputBorder(
            borderRadius: KitabRadii.borderMd,
            borderSide: BorderSide(color: KitabColors.gray200, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: KitabRadii.borderMd,
            borderSide: BorderSide(color: KitabColors.gray200, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: KitabRadii.borderMd,
            borderSide: BorderSide(color: KitabColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: KitabRadii.borderMd,
            borderSide: BorderSide(color: KitabColors.error, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: KitabSpacing.md,
            vertical: KitabSpacing.md,
          ),
          hintStyle: TextStyle(color: KitabColors.gray300),
          labelStyle: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: KitabColors.gray500,
            letterSpacing: 0.4,
          ),
        ),

        // Dividers
        dividerTheme: DividerThemeData(
          color: KitabColors.lightBorder,
          thickness: 1,
          space: 0,
        ),
      );

  // ─── Dark Theme ───
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,

        // Colors
        colorScheme: ColorScheme.dark(
          primary: KitabColors.primary,
          onPrimary: Colors.white,
          secondary: KitabColors.accent,
          onSecondary: Colors.white,
          surface: KitabColors.darkSurface,
          onSurface: KitabColors.darkTextPrimary,
          error: KitabColors.error,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: KitabColors.darkBackground,
        canvasColor: KitabColors.darkBackground,
        dividerColor: KitabColors.darkBorder,

        // Typography
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
          bodyColor: KitabColors.darkTextPrimary,
          displayColor: KitabColors.darkTextPrimary,
        ),

        // AppBar
        appBarTheme: AppBarTheme(
          backgroundColor: KitabColors.darkBackground,
          foregroundColor: KitabColors.darkTextPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false, // Left-aligned titles per spec
        ),

        // Cards — use borders instead of shadows in dark mode
        cardTheme: CardThemeData(
          color: KitabColors.darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: KitabRadii.borderMd,
            side: BorderSide(color: KitabColors.darkBorder),
          ),
        ),

        // Bottom Navigation
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: KitabColors.darkSurface,
          selectedItemColor: KitabColors.primary,
          unselectedItemColor: KitabColors.gray400,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),

        // FAB
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: KitabColors.primary,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: const CircleBorder(),
        ),

        // Input fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: KitabColors.darkSurface,
          border: OutlineInputBorder(
            borderRadius: KitabRadii.borderMd,
            borderSide: BorderSide(color: KitabColors.gray700, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: KitabRadii.borderMd,
            borderSide: BorderSide(color: KitabColors.gray700, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: KitabRadii.borderMd,
            borderSide: BorderSide(color: KitabColors.primary, width: 1.5),
          ),
          hintStyle: TextStyle(color: KitabColors.gray600),
        ),

        // Dividers
        dividerTheme: DividerThemeData(
          color: KitabColors.darkBorder,
          thickness: 1,
          space: 0,
        ),
      );
}
