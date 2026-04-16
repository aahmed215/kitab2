// ═══════════════════════════════════════════════════════════════════
// THEME_PROVIDER.DART — App Theme State
// Reads initial theme from user settings, persists changes back.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';

/// The current theme mode. Syncs with user settings.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  // Read initial theme from settings
  final settings = ref.watch(userSettingsProvider);
  final initial = switch (settings.theme) {
    'dark' => ThemeMode.dark,
    'system' => ThemeMode.system,
    _ => ThemeMode.light,
  };
  return ThemeModeNotifier(ref, initial);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final Ref _ref;

  ThemeModeNotifier(this._ref, ThemeMode initial) : super(initial);

  void setLight() {
    state = ThemeMode.light;
    _ref.read(userSettingsProvider.notifier).update({'theme': 'light'});
  }

  void setDark() {
    state = ThemeMode.dark;
    _ref.read(userSettingsProvider.notifier).update({'theme': 'dark'});
  }

  void setSystem() {
    state = ThemeMode.system;
    _ref.read(userSettingsProvider.notifier).update({'theme': 'system'});
  }
}
