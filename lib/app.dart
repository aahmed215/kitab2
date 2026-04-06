// ═══════════════════════════════════════════════════════════════════
// APP.DART — Root App Widget
// Sets up MaterialApp with theming, routing, and the app shell.
// Theme supports Light, Dark, and System Auto modes.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'core/theme/kitab_theme.dart';
import 'core/widgets/adaptive_layout.dart';
import 'features/home/home_screen.dart';

/// The root widget of the Kitab app.
/// Wraps MaterialApp with the Kitab design system theme.
class KitabApp extends StatelessWidget {
  const KitabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kitab',
      debugShowCheckedModeBanner: false,

      // ─── Theming ───
      // System Auto: follows device light/dark setting
      theme: KitabTheme.light,
      darkTheme: KitabTheme.dark,
      themeMode: ThemeMode.system, // Will be user-configurable via Settings

      // ─── Root Screen ───
      home: const AppShell(),
    );
  }
}

/// The main app shell with adaptive navigation.
/// Phone: bottom nav. Tablet/Desktop: icon rail on left.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // Currently selected tab index
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      currentIndex: _currentIndex,
      onIndexChanged: (index) => setState(() => _currentIndex = index),
      screens: const [
        HomeScreen(),
        _PlaceholderScreen(title: 'Book', icon: '📖'),
        _PlaceholderScreen(title: 'Insights', icon: '📊'),
        _PlaceholderScreen(title: 'Social', icon: '👥'),
        _PlaceholderScreen(title: 'Profile', icon: '👤'),
      ],
      // ─── FAB ───
      // Always visible on every screen. Arc speed dial (built later).
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement FAB arc speed dial
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('FAB tapped — speed dial coming soon'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Temporary placeholder screen for tabs not yet built.
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final String icon;

  const _PlaceholderScreen({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: KitabTypography.h1,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: KitabSpacing.lg),
            Text(
              title,
              style: KitabTypography.h2,
            ),
            const SizedBox(height: KitabSpacing.sm),
            Text(
              'Coming soon',
              style: KitabTypography.body,
            ),
          ],
        ),
      ),
    );
  }
}
