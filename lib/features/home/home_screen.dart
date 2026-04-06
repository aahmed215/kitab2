// ═══════════════════════════════════════════════════════════════════
// HOME_SCREEN.DART — Home Screen (Today View)
// The first screen the user sees. Answers:
// "What should I do today, and how am I doing?"
// See SPEC.md §14.1 for full specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/kitab_theme.dart';

/// The Home screen — the main entry point of the app.
/// Shows: summary card, conditions, scheduled today, needs attention.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ─── App Bar ───
      // Left: "Kitab" in DM Serif Display
      // Right: notification bell with badge dot
      appBar: AppBar(
        title: Text(
          'Kitab',
          style: KitabTypography.h1,
        ),
        actions: [
          // Notification bell button
          IconButton(
            icon: Badge(
              // Small red dot for unread notifications
              smallSize: 8,
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () {
              // TODO: Navigate to notifications screen
            },
          ),
        ],
      ),

      // ─── Body ───
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: KitabSpacing.lg,
          ),
          children: [
            // ─── Summary Card ───
            _SummaryCard(),

            const SizedBox(height: KitabSpacing.lg),

            // ─── Scheduled Today ───
            Text('Scheduled Today', style: KitabTypography.h2),
            const SizedBox(height: KitabSpacing.md),

            // Placeholder for activity cards
            _PlaceholderCard(
              text: 'Activity cards will appear here when you create activities.',
            ),

            const SizedBox(height: KitabSpacing.xl),

            // ─── Needs Attention ───
            // Only shown when there are pending items
            // (hidden for now since there's no data)
          ],
        ),
      ),
    );
  }
}

/// The summary card at the top of the Home screen.
/// Shows greeting, date, Hijri date, progress ring, streak.
class _SummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: KitabRadii.borderMd,
        boxShadow: isDark ? null : KitabShadows.level1,
        border: isDark
            ? Border.all(color: KitabColors.darkBorder)
            : null,
      ),
      child: Row(
        children: [
          // ─── Left side: Greeting + Date + Stats ───
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                Text(
                  'Assalamu Alaikum',
                  style: KitabTypography.h2,
                ),
                const SizedBox(height: 2),

                // Gregorian date — uses actual current date
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                  style: KitabTypography.bodySmall,
                ),
                const SizedBox(height: 2),

                // Hijri date placeholder
                // TODO: Replace with actual Hijri date from Aladhan API
                // Sun/moon icon depends on sunrise/sunset times
                Builder(builder: (context) {
                  final hour = DateTime.now().hour;
                  // Simple approximation: sun between 6am-6pm, moon otherwise
                  // Will be replaced with actual sunrise/sunset from API
                  final isDaytime = hour >= 6 && hour < 18;
                  final icon = isDaytime ? '☀' : '☽';
                  final period = isDaytime ? 'Day' : 'Night';
                  return Row(
                    children: [
                      Text(
                        '$icon ',
                        style: KitabTypography.bodySmall,
                      ),
                      Text(
                        '$period of 18 Shawwal 1447 AH',
                        style: KitabTypography.caption.copyWith(
                          color: KitabColors.gray500,
                        ),
                      ),
                    ],
                  );
                }),

                const SizedBox(height: KitabSpacing.md),

                // Stats
                Text(
                  '0 of 0 goals met today',
                  style: KitabTypography.body,
                ),

                const SizedBox(height: KitabSpacing.xs),

                // Streak
                Row(
                  children: [
                    const Text('🔥 ', style: TextStyle(fontSize: 14)),
                    Text(
                      '0 day all-goals streak',
                      style: KitabTypography.bodySmall.copyWith(
                        color: KitabColors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── Right side: Progress Ring ───
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Track (background circle)
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: 0, // 0% complete
                    strokeWidth: 6,
                    backgroundColor: isDark
                        ? KitabColors.gray700
                        : KitabColors.gray100,
                    valueColor: AlwaysStoppedAnimation(
                      KitabColors.primary,
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                // Center text
                Text(
                  '0/0',
                  style: KitabTypography.mono,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A placeholder card shown when no content is available.
class _PlaceholderCard extends StatelessWidget {
  final String text;

  const _PlaceholderCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KitabSpacing.xl),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: KitabRadii.borderMd,
        border: Border.all(
          color: Theme.of(context).dividerColor,
          style: BorderStyle.solid,
        ),
      ),
      child: Text(
        text,
        style: KitabTypography.body.copyWith(
          color: KitabColors.gray400,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
