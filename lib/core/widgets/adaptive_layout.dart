// ═══════════════════════════════════════════════════════════════════
// ADAPTIVE_LAYOUT.DART — Responsive Layout Wrapper
// Automatically switches between phone, tablet, and desktop layouts.
// Phone: bottom nav. Tablet/Desktop: icon rail on left.
// See SPEC.md §4.7 for layout specifications.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../constants/breakpoints.dart';
import '../theme/kitab_theme.dart';

/// Wraps the app shell and provides adaptive navigation.
/// - Phone (< 600px): Bottom navigation bar
/// - Tablet (600-1024px): Icon rail on left + bottom nav
/// - Desktop (> 1024px): Icon rail on left, no bottom nav
class AdaptiveScaffold extends StatelessWidget {
  /// The currently selected navigation index (0-4)
  final int currentIndex;

  /// Callback when a navigation item is tapped
  final ValueChanged<int> onIndexChanged;

  /// The body content for each tab
  final List<Widget> screens;

  /// Optional FAB widget
  final Widget? floatingActionButton;

  const AdaptiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.screens,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = Breakpoints.isDesktop(context);

    // ─── Desktop/Tablet: Icon Rail + Content ───
    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // Icon Rail (56px)
            _KitabIconRail(
              currentIndex: currentIndex,
              onIndexChanged: onIndexChanged,
            ),
            // Content area
            Expanded(
              child: IndexedStack(
                index: currentIndex,
                children: screens,
              ),
            ),
          ],
        ),
        floatingActionButton: floatingActionButton,
      );
    }

    // ─── Phone/Mobile Web: Bottom Navigation ───
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: _KitabBottomNav(
        currentIndex: currentIndex,
        onIndexChanged: onIndexChanged,
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

/// The 5-tab bottom navigation bar.
/// Fixed (not floating). Solid background with top border.
/// Active = Primary color (filled icon), Inactive = Gray 400 (outlined icon).
class _KitabBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const _KitabBottomNav({
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onIndexChanged,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Book',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Social',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// Icon-only navigation rail for tablet and desktop viewports.
/// 56px wide. Shows "K" brand at top. Tooltip on hover shows section name.
/// Active item has Primary tint background.
class _KitabIconRail extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const _KitabIconRail({
    required this.currentIndex,
    required this.onIndexChanged,
  });

  static const _items = [
    _RailItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    _RailItem(icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book, label: 'Book'),
    _RailItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Insights'),
    _RailItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Social'),
    _RailItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: Breakpoints.iconRailWidth,
      decoration: BoxDecoration(
        color: isDark ? KitabColors.darkSurface : KitabColors.lightSurface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // ─── Brand "K" ───
          const SizedBox(height: 16),
          Text(
            'K',
            style: KitabTypography.h2.copyWith(
              color: KitabColors.primary,
            ),
          ),
          const SizedBox(height: 16),

          // ─── Nav Items ───
          ...List.generate(_items.length, (index) {
            final item = _items[index];
            final isActive = index == currentIndex;

            return Tooltip(
              message: item.label,
              preferBelow: false,
              waitDuration: const Duration(milliseconds: 300),
              child: InkWell(
                onTap: () => onIndexChanged(index),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 42,
                  height: 42,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isActive
                        ? KitabColors.primary.withValues(alpha: 0.08)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    isActive ? item.activeIcon : item.icon,
                    size: 20,
                    color: isActive
                        ? KitabColors.primary
                        : KitabColors.gray400,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Data class for rail navigation items.
class _RailItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _RailItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
