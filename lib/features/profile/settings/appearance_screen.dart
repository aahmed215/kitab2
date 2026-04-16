// ═══════════════════════════════════════════════════════════════════
// APPEARANCE_SCREEN.DART — Theme Settings
// Light / Dark / System Auto toggle. Changes apply immediately.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/kitab_theme.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Appearance', style: KitabTypography.h2),
      ),
      body: ListView(
        padding: const EdgeInsets.all(KitabSpacing.lg),
        children: [
          Text('Theme', style: KitabTypography.h3),
          const SizedBox(height: KitabSpacing.md),

          _ThemeOption(
            title: 'Light',
            icon: Icons.light_mode,
            isSelected: currentMode == ThemeMode.light,
            onTap: () => ref.read(themeModeProvider.notifier).setLight(),
          ),
          _ThemeOption(
            title: 'Dark',
            icon: Icons.dark_mode,
            isSelected: currentMode == ThemeMode.dark,
            onTap: () => ref.read(themeModeProvider.notifier).setDark(),
          ),
          _ThemeOption(
            title: 'System Auto',
            icon: Icons.settings_brightness,
            isSelected: currentMode == ThemeMode.system,
            onTap: () => ref.read(themeModeProvider.notifier).setSystem(),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon,
          color: isSelected ? KitabColors.primary : KitabColors.gray500),
      title: Text(title, style: KitabTypography.body),
      trailing: isSelected
          ? const Icon(Icons.check, color: KitabColors.primary)
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      selected: isSelected,
    );
  }
}
