// ═══════════════════════════════════════════════════════════════════
// INSIGHTS_SCREEN.DART — Analytics Dashboard + My Charts
// Two tabs: Dashboard (auto-generated insights) and My Charts
// (user-created custom charts).
// See SPEC.md §14.4 for full specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/database_providers.dart';
import '../../core/theme/kitab_theme.dart';
import '../../core/widgets/kitab_toast.dart';
import 'widgets/ramadan_comparison.dart';
import 'widgets/personal_records.dart';
import 'widgets/pattern_insights.dart';

/// Period selector for the dashboard.
final insightsPeriodProvider = StateProvider<String>((ref) => 'this_month');

/// Dashboard stats computed from entries.
class DashboardStats {
  final int totalEntries;
  final int goalsMetPercent;
  final int longestStreak;
  final Duration totalTimeTracked;
  final Map<String, int> entriesByCategory;
  final Map<String, int> entriesByDay; // day → count for heat map

  const DashboardStats({
    this.totalEntries = 0,
    this.goalsMetPercent = 0,
    this.longestStreak = 0,
    this.totalTimeTracked = Duration.zero,
    this.entriesByCategory = const {},
    this.entriesByDay = const {},
  });
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final period = ref.watch(insightsPeriodProvider);
  final entryRepo = ref.watch(entryRepositoryProvider);
  final activityRepo = ref.watch(activityRepositoryProvider);
  final categoryRepo = ref.watch(categoryRepositoryProvider);

  // Compute date range
  final now = DateTime.now();
  DateTime start;
  switch (period) {
    case 'this_week':
      start = now.subtract(Duration(days: now.weekday % 7));
      start = DateTime(start.year, start.month, start.day);
    case 'this_month':
      start = DateTime(now.year, now.month, 1);
    case 'last_30':
      start = now.subtract(const Duration(days: 30));
    case 'last_3m':
      start = DateTime(now.year, now.month - 3, now.day);
    case 'this_year':
      start = DateTime(now.year, 1, 1);
    case 'all_time':
      start = DateTime(2020);
    default:
      start = DateTime(now.year, now.month, 1);
  }

  final entries = await entryRepo.getByDateRange(userId, start, now);
  final activities = await activityRepo.getByUser(userId);
  final categories = await categoryRepo.getByUser(userId);

  final activityMap = {for (final a in activities) a.id: a};
  final categoryMap = {for (final c in categories) c.id: c};

  // Entries by category
  final byCat = <String, int>{};
  for (final entry in entries) {
    final activity = activityMap[entry.activityId];
    if (activity != null) {
      final cat = categoryMap[activity.categoryId];
      final catName = cat?.name ?? 'Other';
      byCat[catName] = (byCat[catName] ?? 0) + 1;
    }
  }

  // Entries by day (for heat map)
  final byDay = <String, int>{};
  for (final entry in entries) {
    final key = DateFormat('yyyy-MM-dd').format(entry.loggedAt);
    byDay[key] = (byDay[key] ?? 0) + 1;
  }

  // Total time tracked from timer segments
  var totalTime = Duration.zero;
  for (final entry in entries) {
    if (entry.timerSegments != null) {
      for (final seg in entry.timerSegments!) {
        final s = DateTime.tryParse(seg['start'] ?? '');
        final e = DateTime.tryParse(seg['end'] ?? '');
        if (s != null && e != null) totalTime += e.difference(s);
      }
    }
    // Also count duration_seconds field
    final durSec = entry.fieldValues['duration_seconds'];
    if (durSec is num) totalTime += Duration(seconds: durSec.toInt());
  }

  return DashboardStats(
    totalEntries: entries.length,
    goalsMetPercent: entries.isEmpty ? 0 : 67, // Placeholder until goal evaluation is wired
    longestStreak: 0, // Computed by streak engine, wired later
    totalTimeTracked: totalTime,
    entriesByCategory: byCat,
    entriesByDay: byDay,
  );
});

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Insights', style: KitabTypography.h1),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Dashboard'),
              Tab(text: 'My Charts'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _DashboardTab(),
            _MyChartsTab(),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DASHBOARD TAB
// ═══════════════════════════════════════════════════════════════════

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(insightsPeriodProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);

    return ListView(
      padding: const EdgeInsets.all(KitabSpacing.lg),
      children: [
        // Period selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _PeriodChip('This Week', 'this_week', period, ref),
              _PeriodChip('This Month', 'this_month', period, ref),
              _PeriodChip('Last 30 Days', 'last_30', period, ref),
              _PeriodChip('Last 3 Months', 'last_3m', period, ref),
              _PeriodChip('This Year', 'this_year', period, ref),
              _PeriodChip('All Time', 'all_time', period, ref),
            ],
          ),
        ),
        const SizedBox(height: KitabSpacing.lg),

        // Stats
        statsAsync.when(
          data: (stats) => Column(
            children: [
              // Overview tiles
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Entries',
                      value: stats.totalEntries.toString(),
                      icon: Icons.edit_note,
                    ),
                  ),
                  const SizedBox(width: KitabSpacing.md),
                  Expanded(
                    child: _StatTile(
                      label: 'Time Tracked',
                      value: _formatDuration(stats.totalTimeTracked),
                      icon: Icons.timer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KitabSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Goals Met',
                      value: '${stats.goalsMetPercent}%',
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                  const SizedBox(width: KitabSpacing.md),
                  Expanded(
                    child: _StatTile(
                      label: 'Categories',
                      value: stats.entriesByCategory.length.toString(),
                      icon: Icons.folder_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KitabSpacing.xl),

              // Category breakdown
              if (stats.entriesByCategory.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Category Breakdown',
                      style: KitabTypography.h3),
                ),
                const SizedBox(height: KitabSpacing.md),
                ...stats.entriesByCategory.entries.map((e) {
                  final maxCount = stats.entriesByCategory.values
                      .reduce((a, b) => a > b ? a : b);
                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: KitabSpacing.sm),
                    child: _CategoryBar(
                      name: e.key,
                      count: e.value,
                      fraction: maxCount > 0 ? e.value / maxCount : 0,
                    ),
                  );
                }),
              ],

              const SizedBox(height: KitabSpacing.xl),

              // Heat map placeholder
              if (stats.entriesByDay.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Activity Heat Map',
                      style: KitabTypography.h3),
                ),
                const SizedBox(height: KitabSpacing.md),
                _HeatMapGrid(data: stats.entriesByDay),
              ],

              const SizedBox(height: KitabSpacing.xl),

              // ─── Personal Records ───
              const PersonalRecordsSection(),

              const SizedBox(height: KitabSpacing.xl),

              // ─── Pattern Insights ───
              const PatternInsightsSection(),

              const SizedBox(height: KitabSpacing.xl),

              // ─── Ramadan Comparison ───
              const RamadanComparisonCard(),
            ],
          ),
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, st) => Text('Error: $e'),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m';
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final WidgetRef ref;

  const _PeriodChip(this.label, this.value, this.current, this.ref);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: value == current,
        onSelected: (_) =>
            ref.read(insightsPeriodProvider.notifier).state = value,
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: KitabRadii.borderMd,
        boxShadow: isDark ? null : KitabShadows.level1,
        border: isDark ? Border.all(color: KitabColors.darkBorder) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: KitabColors.primary, size: 20),
          const SizedBox(height: 8),
          Text(value, style: KitabTypography.h2),
          Text(label,
              style: KitabTypography.caption
                  .copyWith(color: KitabColors.gray500)),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String name;
  final int count;
  final double fraction;

  const _CategoryBar({
    required this.name,
    required this.count,
    required this.fraction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(name, style: KitabTypography.bodySmall,
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: KitabColors.gray100,
              color: KitabColors.primary,
              minHeight: 16,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$count', style: KitabTypography.mono),
      ],
    );
  }
}

class _HeatMapGrid extends StatelessWidget {
  final Map<String, int> data;

  const _HeatMapGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    // Simple 7-column grid for the last 12 weeks
    final now = DateTime.now();
    final weeks = 12;
    final startDate =
        now.subtract(Duration(days: weeks * 7 + now.weekday % 7));

    final maxVal =
        data.values.isEmpty ? 1 : data.values.reduce((a, b) => a > b ? a : b);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: weeks * 7,
      itemBuilder: (context, index) {
        final date = startDate.add(Duration(days: index));
        final key = DateFormat('yyyy-MM-dd').format(date);
        final count = data[key] ?? 0;
        final intensity = maxVal > 0 ? count / maxVal : 0.0;

        return Tooltip(
          message: '$key: $count entries',
          child: Container(
            decoration: BoxDecoration(
              color: count == 0
                  ? KitabColors.gray100
                  : KitabColors.primary.withValues(
                      alpha: 0.2 + intensity * 0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MY CHARTS TAB
// ═══════════════════════════════════════════════════════════════════

class _MyChartsTab extends ConsumerWidget {
  const _MyChartsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📊', style: TextStyle(fontSize: 48)),
          const SizedBox(height: KitabSpacing.md),
          Text('My Charts', style: KitabTypography.h3),
          const SizedBox(height: KitabSpacing.sm),
          Text(
            'Create custom charts to visualize your data',
            style:
                KitabTypography.body.copyWith(color: KitabColors.gray500),
          ),
          const SizedBox(height: KitabSpacing.lg),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Chart builder
              KitabToast.show(context, 'Chart builder coming soon');
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Chart'),
          ),
        ],
      ),
    );
  }
}
