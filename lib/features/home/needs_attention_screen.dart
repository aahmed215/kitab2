// ═══════════════════════════════════════════════════════════════════
// NEEDS_ATTENTION_SCREEN.DART — Full List of Pending Past Periods
// Grouped by date with day separators. Same action sheet per card.
// See SPEC.md §14.1.4 for specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_provider.dart';
import 'package:intl/intl.dart';
import '../../core/engines/engines.dart';
import '../../core/providers/database_providers.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/theme/kitab_theme.dart';
import '../../core/widgets/kitab_card.dart';
import '../../core/widgets/status_icon.dart';
import '../../data/models/activity.dart';
import '../../data/models/category.dart' as domain;
import 'widgets/activity_action_sheet.dart';


const _periodEngine = PeriodEngine();

/// A pending period that needs the user's attention.
class PendingItem {
  final Activity activity;
  final ComputedPeriod period;
  final domain.Category? category;

  const PendingItem({
    required this.activity,
    required this.period,
    this.category,
  });
}

/// Provider for all pending past periods across all activities.
final needsAttentionProvider =
    FutureProvider<List<PendingItem>>((ref) async {
  final activityRepo = ref.watch(activityRepositoryProvider);
  final entryRepo = ref.watch(entryRepositoryProvider);
  final statusRepo = ref.watch(periodStatusRepositoryProvider);
  final categoryRepo = ref.watch(categoryRepositoryProvider);

  final activities = await activityRepo.getByUser(ref.watch(currentUserIdProvider));
  final categories = await categoryRepo.getByUser(ref.watch(currentUserIdProvider));
  final categoryMap = {for (final c in categories) c.id: c};

  final now = DateTime.now();
  final lookback = now.subtract(const Duration(days: 30));
  final userId = ref.watch(currentUserIdProvider);

  final pending = <PendingItem>[];

  for (final activity in activities) {
    if (activity.schedule == null || activity.isArchived || activity.deletedAt != null) continue;

    final periods = _periodEngine.computePeriods(
      scheduleJson: activity.schedule,
      queryStart: lookback,
      queryEnd: now, // Include today
    );

    // Deduplicate periods
    final seen = <String>{};
    final uniquePeriods = periods.where((p) {
      final key = '${p.start.millisecondsSinceEpoch}_${p.end.millisecondsSinceEpoch}';
      return seen.add(key);
    }).toList();

    for (final period in uniquePeriods) {
      // Skip periods that haven't ended yet
      if (period.end.isAfter(now)) continue;

      // Check if there's already a status or entry for this period's day
      final dayStart = DateTime(period.start.year, period.start.month, period.start.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      // Check for any status record on this day for this activity
      final dayStatuses = await statusRepo.getActivityStatusesByDateRange(userId, dayStart, dayEnd);
      final hasStatus = dayStatuses.any((s) => s.activityId == activity.id);
      if (hasStatus) continue;

      // Check for any entries on this day
      final entries = await entryRepo.getByActivityAndDateRange(
        userId, activity.id, dayStart, dayEnd,
      );

      if (entries.isEmpty) {
        pending.add(PendingItem(
          activity: activity,
          period: period,
          category: categoryMap[activity.categoryId],
        ));
      }
    }
  }

  // Sort by most recent period first
  pending.sort((a, b) => b.period.end.compareTo(a.period.end));
  return pending;
});

class NeedsAttentionScreen extends ConsumerWidget {
  const NeedsAttentionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(needsAttentionProvider);
    final fmt = ref.watch(dateFormatterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Needs Attention', style: KitabTypography.h2),
      ),
      body: pendingAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('✅', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: KitabSpacing.md),
                  Text("You're all caught up!", style: KitabTypography.h3),
                  const SizedBox(height: KitabSpacing.sm),
                  Text(
                    'No pending periods need your attention',
                    style: KitabTypography.body
                        .copyWith(color: KitabColors.gray500),
                  ),
                ],
              ),
            );
          }

          // Group by date
          final grouped = _groupByDate(items);

          return ListView.builder(
            padding: const EdgeInsets.all(KitabSpacing.lg),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final group = grouped[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (index > 0) const SizedBox(height: KitabSpacing.lg),
                  // Day separator
                  _DaySeparator(date: group.date, fmt: fmt),
                  const SizedBox(height: KitabSpacing.sm),
                  // Cards
                  ...group.items.map((item) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: KitabSpacing.sm),
                        child: _PendingCard(
                          item: item,
                          fmt: fmt,
                          onTap: () async {
                            await showActivityActionSheet(
                              context,
                              ref,
                              activity: item.activity,
                              period: item.period,
                              currentStatus: 'pending',
                            );
                            ref.invalidate(needsAttentionProvider);
                          },
                        ),
                      )),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  List<_DateGroup> _groupByDate(List<PendingItem> items) {
    final groups = <String, _DateGroup>{};
    for (final item in items) {
      final dateKey =
          DateFormat('yyyy-MM-dd').format(item.period.end);
      groups.putIfAbsent(
        dateKey,
        () => _DateGroup(date: item.period.end, items: []),
      );
      groups[dateKey]!.items.add(item);
    }
    return groups.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}

class _DateGroup {
  final DateTime date;
  final List<PendingItem> items;
  _DateGroup({required this.date, required this.items});
}

class _DaySeparator extends StatelessWidget {
  final DateTime date;
  final KitabDateFormat fmt;
  const _DaySeparator({required this.date, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);

    String label;
    if (dateDay == today) {
      label = 'Today';
    } else if (dateDay == yesterday) {
      label = 'Yesterday';
    } else {
      label = fmt.longDateWithDayName(date);
    }

    return Row(
      children: [
        Text(label,
            style: KitabTypography.h3.copyWith(color: KitabColors.gray700)),
        const SizedBox(width: KitabSpacing.sm),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _PendingCard extends StatelessWidget {
  final PendingItem item;
  final KitabDateFormat fmt;
  final VoidCallback? onTap;

  const _PendingCard({required this.item, required this.fmt, this.onTap});

  @override
  Widget build(BuildContext context) {
    return KitabCard(
      borderColor: item.category != null
          ? _parseColor(item.category!.color)
          : null,
      onTap: onTap,
      child: Row(
        children: [
          const StatusIcon(status: ActivityStatus.pending),
          const SizedBox(width: KitabSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.activity.isPrivate
                      ? '••••••••'
                      : item.activity.name,
                  style: KitabTypography.body
                      .copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  _periodLabel(item, fmt),
                  style: KitabTypography.caption
                      .copyWith(color: KitabColors.gray500),
                ),
              ],
            ),
          ),
          Text(
            item.category?.icon ?? '📁',
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}

String _periodLabel(PendingItem item, KitabDateFormat fmt) {
  // Check if the activity has dynamic time windows
  if (item.activity.schedule != null) {
    final versions = item.activity.schedule!['versions'] as List<dynamic>?;
    if (versions != null && versions.isNotEmpty) {
      final config = (versions.last as Map<String, dynamic>)['config'] as Map<String, dynamic>?;
      if (config != null) {
        final timeType = config['time_type'] as String?;
        final winStart = config['window_start'] as String?;
        final winEnd = config['window_end'] as String?;
        if (timeType == 'dynamic' && winStart != null && winEnd != null) {
          final startOffset = config['window_start_offset'] as int? ?? 0;
          final endOffset = config['window_end_offset'] as int? ?? 0;
          final startLabel = startOffset != 0 ? '$winStart ${startOffset > 0 ? '+' : ''}${startOffset}m' : winStart;
          final endLabel = endOffset != 0 ? '$winEnd ${endOffset > 0 ? '+' : ''}${endOffset}m' : winEnd;

          // For today, show actual times + dynamic names
          final now = DateTime.now();
          final isToday = item.period.start.year == now.year &&
              item.period.start.month == now.month &&
              item.period.start.day == now.day;
          if (isToday) {
            return '$startLabel → $endLabel (${fmt.time(item.period.start)} — ${fmt.time(item.period.end)})';
          }
          return '$startLabel → $endLabel';
        }
      }
    }
  }
  // Specific times
  return '${fmt.time(item.period.start)} — ${fmt.time(item.period.end)}';
}

Color _parseColor(String hex) {
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  } catch (_) {
    return KitabColors.primary;
  }
}
