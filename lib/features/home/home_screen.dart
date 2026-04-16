// ═══════════════════════════════════════════════════════════════════
// HOME_SCREEN.DART — Home Screen (Today View)
// The first screen the user sees. Answers:
// "What should I do today, and how am I doing?"
// See SPEC.md §14.1 for full specification.
// ═══════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/engines/engines.dart';
import '../../core/providers/database_providers.dart';
import '../../core/utils/condition_merge.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/condition.dart';
import '../../core/utils/provider_refresh.dart';
import '../../core/providers/privacy_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/greeting_service.dart';
import '../../core/services/prayer_time_service.dart';
import '../../core/theme/kitab_theme.dart';
import '../../core/widgets/status_icon.dart';
import '../../core/widgets/kitab_card.dart';
import '../notifications/notifications_screen.dart';
import 'needs_attention_screen.dart';
import 'providers/home_providers.dart';
import 'widgets/activity_action_sheet.dart';
import '../../core/widgets/kitab_toast.dart';
import 'widgets/summary_bottom_sheet.dart';
import '../routines/routine_execution_screen.dart';

/// The Home screen — the main entry point of the app.
/// Shows: summary card, conditions, scheduled today, needs attention.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conditionsAsync = ref.watch(activeConditionsProvider);

    return Scaffold(
      // ─── App Bar ───
      appBar: AppBar(
        title: GestureDetector(
          onDoubleTap: () {
            final current = ref.read(privateActivitiesRevealedProvider);
            ref.read(privateActivitiesRevealedProvider.notifier).state = !current;
            KitabToast.show(context, current
                    ? 'Private activities hidden'
                    : 'Private activities revealed');
          },
          child: Text('Kitab', style: KitabTypography.h1),
        ),
        actions: [
          IconButton(
            icon: Consumer(
              builder: (context, ref, _) {
                final countAsync = ref.watch(notificationCountProvider);
                final count = countAsync.valueOrNull ?? 0;
                // SPEC §14.2: badge is a dot, not a count
                return Badge(
                  isLabelVisible: count > 0,
                  smallSize: 8,
                  backgroundColor: KitabColors.error,
                  child: const Icon(Icons.notifications_outlined),
                );
              },
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NotificationsScreen()),
              );
            },
          ),
        ],
      ),

      // ─── Body ───
      body: RefreshIndicator(
        color: KitabColors.primary,
        onRefresh: () async {
          // Invalidate providers to trigger refresh
          ref.invalidate(scheduledTodayProvider);
          ref.invalidate(scheduledRoutinesTodayProvider);
          ref.invalidate(todayEntriesProvider);
          ref.invalidate(homeSummaryProvider);
          ref.invalidate(weeklyHistoryProvider);
        },
        child: SafeArea(
          child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: KitabSpacing.lg),
            children: [
              // ─── Summary Card ───
              const _SummaryCard(),
              const SizedBox(height: KitabSpacing.md),

              // ─── Active Conditions ───
              conditionsAsync.when(
                data: (conditions) {
                  if (conditions.isEmpty) return const SizedBox.shrink();
                  // Deduplicate by presetId — show one chip per condition type.
                  // If multiple active records of the same preset exist,
                  // keep the most recently started one.
                  final deduped = <String, Condition>{};
                  for (final c in conditions) {
                    final existing = deduped[c.presetId];
                    if (existing == null || c.startDate.isAfter(existing.startDate)) {
                      deduped[c.presetId] = c;
                    }
                  }
                  final uniqueConditions = deduped.values.toList();

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < uniqueConditions.length; i++) ...[
                          if (i > 0) const SizedBox(width: KitabSpacing.xs),
                          Consumer(builder: (context, ref, _) {
                            final c = uniqueConditions[i];
                            // Find the merged chain so "Day X" reflects the
                            // full logical condition period (including earlier
                            // same-preset records that chain into this one).
                            final allConds =
                                ref.watch(allConditionsProvider).valueOrNull ?? conditions;
                            final chain = findConditionChain(c, allConds);
                            final today = DateTime.now();
                            final todayDay = DateTime(today.year, today.month, today.day);
                            final daysSince = todayDay
                                    .difference(chain.chainStart)
                                    .inDays +
                                1;
                            return _ConditionChip(
                              label:
                                  '${c.emoji} ${c.label} · Day $daysSince',
                              onTap: () =>
                                  _showConditionEditDialog(context, ref, c),
                              onClose: () =>
                                  _endConditionNow(context, ref, c),
                            );
                          }),
                        ],
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, st) => const SizedBox.shrink(),
              ),
              const SizedBox(height: KitabSpacing.lg),

              // ─── Needs Attention (above Scheduled Today) ───
              const _NeedsAttentionSection(),

              const SizedBox(height: KitabSpacing.xl),

              // ─── Scheduled Today ───
              Text('Scheduled Today', style: KitabTypography.h2),
              const SizedBox(height: KitabSpacing.md),
              const _ScheduledTodaySection(),

              const SizedBox(height: KitabSpacing.xl),

              // ─── Scheduled Routines ───
              const _ScheduledRoutinesSection(),

              const SizedBox(height: KitabSpacing.xl),
            ],
          ),
          ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SUMMARY CARD
// ═══════════════════════════════════════════════════════════════════

class _SummaryCard extends ConsumerWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summaryAsync = ref.watch(homeSummaryProvider);

    final summary = summaryAsync.valueOrNull ?? const HomeSummary();

    return GestureDetector(
      onTap: () => showSummaryBottomSheet(context, ref),
      child: ClipRRect(
      borderRadius: KitabRadii.borderMd,
      child: Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: KitabRadii.borderMd,
        boxShadow: isDark ? null : KitabShadows.level1,
        border: isDark ? Border.all(color: KitabColors.darkBorder) : null,
      ),
      child: Stack(
        children: [
          // Time-of-day tinted background wash (subtle warm/cool shift)
          Positioned.fill(
            child: Container(
              color: _timeOfDayBackgroundTint(isDark: isDark),
            ),
          ),
          // Geometric pattern background — tinted by time of day
          Positioned.fill(
            child: CustomPaint(
              painter: _GeometricPatternPainter(
                color: _timeOfDayPatternColor(isDark: isDark),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Left side: Greeting + Date ───
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting (8-level priority)
                Consumer(builder: (context, ref, _) {
                  final userName = ref.watch(userFirstNameProvider).valueOrNull;
                  final settings = ref.watch(userSettingsProvider);
                  final hijri = ref.watch(todayHijriDateProvider).valueOrNull;
                  return Text(
                    const GreetingService().getGreeting(
                      userName: userName,
                      islamicPersonalization: settings.islamicPersonalization,
                      hijriDate: hijri,
                    ),
                    style: KitabTypography.h1,
                  );
                }),
                const SizedBox(height: 4),

                // Gregorian date
                Text(
                  ref.watch(dateFormatterProvider).fullDateWithDay(DateTime.now()),
                  style: KitabTypography.body,
                ),
                const SizedBox(height: 2),

                // Hijri date — only shown when Islamic personalization is on.
                // TODO: Gate behind user settings when settings persistence is wired.
                Consumer(builder: (context, ref, _) {
                  final settings = ref.watch(userSettingsProvider);
                  if (!settings.hijriCalendarEnabled) return const SizedBox.shrink();

                  final hijriAsync = ref.watch(todayHijriDateProvider);
                  final hijri = hijriAsync.valueOrNull;
                  if (hijri == null) return const SizedBox.shrink();

                  // Determine Day/Night from prayer times (requires location)
                  final prayerTimes = ref.watch(todayPrayerTimesProvider).valueOrNull ?? {};
                  final now = DateTime.now();
                  String icon;
                  String hijriText;

                  DateTime? sunrise;
                  DateTime? maghrib;
                  try {
                    if (prayerTimes['Sunrise'] != null) {
                      final parts = prayerTimes['Sunrise']!.replaceAll(RegExp(r'[APap][Mm]'), '').trim().split(':');
                      var h = int.parse(parts[0]);
                      final m = int.parse(parts[1]);
                      if (prayerTimes['Sunrise']!.toUpperCase().contains('PM') && h != 12) h += 12;
                      if (prayerTimes['Sunrise']!.toUpperCase().contains('AM') && h == 12) h = 0;
                      sunrise = DateTime(now.year, now.month, now.day, h, m);
                    }
                    if (prayerTimes['Maghrib'] != null) {
                      final parts = prayerTimes['Maghrib']!.replaceAll(RegExp(r'[APap][Mm]'), '').trim().split(':');
                      var h = int.parse(parts[0]);
                      final m = int.parse(parts[1]);
                      if (prayerTimes['Maghrib']!.toUpperCase().contains('PM') && h != 12) h += 12;
                      if (prayerTimes['Maghrib']!.toUpperCase().contains('AM') && h == 12) h = 0;
                      maghrib = DateTime(now.year, now.month, now.day, h, m);
                    }
                  } catch (_) {}

                  if (sunrise != null && maghrib != null) {
                    final isDaytime = now.isAfter(sunrise) && now.isBefore(maghrib);
                    icon = isDaytime ? '☀️' : '🌙';
                    hijriText = '${isDaytime ? 'Day' : 'Night'} of ${hijri.formatted}';
                  } else {
                    // No prayer times (no location, no connection, polar region) — just date
                    icon = '📅';
                    hijriText = hijri.formatted;
                  }

                  return Row(
                    children: [
                      Text('$icon ', style: KitabTypography.body),
                      Flexible(
                        child: Text(
                          hijriText,
                          style: KitabTypography.bodySmall.copyWith(
                            color: KitabColors.gray500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                }),

              ],
            ),
          ),

          // ─── Right side: Progress Ring + Stats ───
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CircularProgressIndicator(
                        value: summary.progressPercent,
                        strokeWidth: 6,
                        backgroundColor:
                            isDark ? KitabColors.gray700 : KitabColors.gray100,
                        valueColor:
                            const AlwaysStoppedAnimation(KitabColors.primary),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '${summary.metGoals}/${summary.totalGoals}',
                      style: KitabTypography.mono,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: KitabSpacing.sm),
              Text(
                'activities done',
                style: KitabTypography.caption.copyWith(
                  color: KitabColors.gray500,
                ),
              ),
              const SizedBox(height: KitabSpacing.xs),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    summary.streakFrozen ? '🧊 ' : '🔥 ',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    '${summary.allGoalsStreak} day streak',
                    style: KitabTypography.caption.copyWith(
                      color: KitabColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
        ],
      ),
    ),
    ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SCHEDULED TODAY SECTION
// ═══════════════════════════════════════════════════════════════════

class _ScheduledTodaySection extends ConsumerWidget {
  const _ScheduledTodaySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduledAsync = ref.watch(scheduledTodayProvider);
    final allActivitiesAsync = ref.watch(activeActivitiesProvider);

    return scheduledAsync.when(
      data: (items) {
        if (items.isEmpty) {
          // Differentiate between first-time user (no activities at all)
          // vs user who has activities but none scheduled today
          final allActivities = allActivitiesAsync.valueOrNull ?? [];
          if (allActivities.isEmpty) {
            return const _FirstTimeEmptyState();
          }
          return const _EmptyState(
            text: 'No activities scheduled today.\n'
                'Create scheduled activities in Profile → My Activities.',
          );
        }
        return Column(
          children: items.map((item) => _ActivityCard(item: item)).toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(KitabSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const _EmptyState(text: 'Error loading activities'),
    );
  }
}

/// SPEC §14.1: First-time user empty state with geometric illustration + CTA.
class _FirstTimeEmptyState extends StatelessWidget {
  const _FirstTimeEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: KitabSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: KitabColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.auto_stories,
                size: 32,
                color: KitabColors.primary,
              ),
            ),
            const SizedBox(height: KitabSpacing.lg),
            Text(
              'Your Kitab awaits\nits first page.',
              style: KitabTypography.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KitabSpacing.sm),
            Text(
              'Start tracking what matters most to you.',
              style: KitabTypography.body
                  .copyWith(color: KitabColors.gray500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KitabSpacing.xl),
            FilledButton.icon(
              onPressed: () {
                // TODO: Navigate to Profile → My Activities → New Activity
                    KitabToast.show(context,
                      'Go to Profile \u2192 My Activities to create your first activity',
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create an Activity'),
                ),
              ],
            ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ACTIVITY CARD
// ═══════════════════════════════════════════════════════════════════

class _ActivityCard extends ConsumerWidget {
  final ScheduledActivityState item;

  const _ActivityCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = item.status == 'completed';
    final isExcused = item.status == 'excused';
    final isMissed = item.status == 'missed';
    final isFaded = isCompleted || isExcused;

    // Map status to ActivityStatus enum
    ActivityStatus statusEnum;
    if (isCompleted) {
      statusEnum = ActivityStatus.completed;
    } else if (isExcused) {
      statusEnum = ActivityStatus.excused;
    } else if (isMissed) {
      statusEnum = ActivityStatus.missed;
    } else if (item.primaryGoalEval?.isMet == true) {
      statusEnum = ActivityStatus.completed;
    } else {
      statusEnum = ActivityStatus.inProgress;
    }

    // Look up category for color + icon
    final categoriesList = ref.watch(homeCategoriesProvider).valueOrNull ?? [];
    final category = categoriesList.where((c) => c.id == item.activity.categoryId).firstOrNull;
    final borderColor = category != null ? _parseHexColor(category.color) : KitabColors.gray400;

    // Subtitle: goal progress if available, otherwise time window
    String? subtitle;
    if (item.primaryGoalEval?.progressText != null &&
        item.primaryGoalEval!.progressText!.isNotEmpty) {
      subtitle = item.primaryGoalEval!.progressText;
    } else {
      subtitle = _formatPeriodWindow(item.period);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: KitabSpacing.sm),
      child: KitabCard(
        faded: isFaded,
        borderColor: borderColor,
        onTap: () async {
          await showActivityActionSheet(
            context,
            ref,
            activity: item.activity,
            period: item.period,
            currentStatus: item.status,
          );
          refreshAllEntryProviders(ref);
        },
        child: Row(
          children: [
            // Status icon (26x26 rounded square)
            StatusIcon(status: statusEnum),
            const SizedBox(width: KitabSpacing.md),

            // Activity info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Line 1: Activity name
                  Text(
                    item.activity.isPrivate
                        ? '••••••••' // Blurred for private
                        : item.activity.name,
                    style: KitabTypography.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isCompleted ? KitabColors.gray500 : null,
                    ),
                  ),

                  // Line 2: category icon + name, plus subtitle (goal or time)
                  if (category != null || subtitle != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (category != null) ...[
                          Text(category.icon, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            category.name,
                            style: KitabTypography.caption
                                .copyWith(color: KitabColors.gray500),
                          ),
                        ],
                        if (category != null && subtitle != null)
                          Text('  ·  ',
                              style: KitabTypography.caption
                                  .copyWith(color: KitabColors.gray300)),
                        if (subtitle != null)
                          Flexible(
                            child: Text(
                              subtitle,
                              style: KitabTypography.caption
                                  .copyWith(color: KitabColors.gray500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SCHEDULED ROUTINES SECTION
// ═══════════════════════════════════════════════════════════════════

class _ScheduledRoutinesSection extends ConsumerWidget {
  const _ScheduledRoutinesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(scheduledRoutinesTodayProvider);

    return routinesAsync.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Routines', style: KitabTypography.h2),
            const SizedBox(height: KitabSpacing.md),
            ...items.map((item) => _RoutineCard(item: item)),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final ScheduledRoutineState item;

  const _RoutineCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isCompleted = item.status == 'completed';

    final (Color statusColor, IconData statusIcon) = switch (item.status) {
      'completed' => (KitabColors.success, Icons.check_circle),
      'partial' => (KitabColors.warning, Icons.pie_chart),
      _ => (KitabColors.gray400, Icons.repeat),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: KitabSpacing.sm),
      child: KitabCard(
        faded: isCompleted,
        onTap: () {
          Navigator.push(context,
            MaterialPageRoute(builder: (_) => RoutineExecutionScreen(routine: item.routine)));
        },
        child: Row(
          children: [
            // Status icon
            StatusIcon(
              status: isCompleted
                  ? ActivityStatus.completed
                  : item.status == 'partial'
                      ? ActivityStatus.inProgress
                      : ActivityStatus.pending,
            ),
            const SizedBox(width: KitabSpacing.md),

            // Routine info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.routine.isPrivate ? '••••••••' : item.routine.name,
                    style: KitabTypography.body.copyWith(
                      fontWeight: FontWeight.w500,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted ? KitabColors.gray400 : null,
                    ),
                  ),
                  Text(
                    '${item.completion.slotsFilled}/${item.completion.slotsTotal} activities done',
                    style: KitabTypography.caption.copyWith(color: KitabColors.gray500),
                  ),
                ],
              ),
            ),

            // Progress indicator
            SizedBox(
              width: 36,
              height: 36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: item.completion.progressPercent,
                    strokeWidth: 3,
                    backgroundColor: KitabColors.gray100,
                    color: statusColor,
                    strokeCap: StrokeCap.round,
                  ),
                  if (isCompleted)
                    Icon(statusIcon, size: 16, color: statusColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// NEEDS ATTENTION SECTION (max 3, with "See All" link)
// ═══════════════════════════════════════════════════════════════════

class _NeedsAttentionSection extends ConsumerWidget {
  const _NeedsAttentionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(needsAttentionProvider);
    final fmt = ref.watch(dateFormatterProvider);

    return pendingAsync.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        final showItems = items.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with "See All"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Needs Attention', style: KitabTypography.h2),
                if (items.length > 3)
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NeedsAttentionScreen(),
                      ),
                    ),
                    child: Text('See All (${items.length})'),
                  ),
              ],
            ),
            const SizedBox(height: KitabSpacing.sm),

            ...showItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: KitabSpacing.sm),
                  child: KitabCard(
                    onTap: () async {
                      await showActivityActionSheet(
                        context,
                        ref,
                        activity: item.activity,
                        period: item.period,
                        currentStatus: 'pending',
                      );
                      ref.invalidate(scheduledTodayProvider);
                      ref.invalidate(todayEntriesProvider);
                      ref.invalidate(homeSummaryProvider);
                      ref.invalidate(needsAttentionProvider);
                    },
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
                                _pendingPeriodLabel(item, fmt),
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
                  ),
                )),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }
}

/// Ends a condition immediately (sets end_date = today).
/// Per SPEC §14.1: tapping the ✕ on a condition chip should end it.
void _endConditionNow(BuildContext context, WidgetRef ref, dynamic condition) async {
  final repo = ref.read(conditionRepositoryProvider);
  await repo.endCondition(condition.id as String, DateTime.now());
  refreshAllEntryProviders(ref);
  if (context.mounted) {
    KitabToast.success(context, '${condition.label} condition ended',
      action: ToastAction(
        label: 'Undo',
        onPressed: () async {
          // Restore by saving the condition with endDate = null
          await repo.saveCondition((condition as dynamic).copyWith(
            endDate: null,
            updatedAt: DateTime.now(),
          ));
          refreshAllEntryProviders(ref);
        },
      ),
    );
  }
}

void _showConditionEditDialog(BuildContext context, WidgetRef ref, dynamic condition) {
  var startDate = condition.startDate as DateTime;
  var endDate = DateTime.now();
  final fmt = ref.read(dateFormatterProvider);

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Row(
          children: [
            Text('${condition.emoji} ', style: const TextStyle(fontSize: 20)),
            Expanded(child: Text(condition.label as String, style: KitabTypography.h3)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Start date
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.calendar_today, size: 18),
              title: const Text('Started'),
              subtitle: Text(fmt.shortDateWithDay(startDate)),
              trailing: const Icon(Icons.edit, size: 16, color: KitabColors.gray400),
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setDialogState(() => startDate = picked);
              },
            ),
            // End date
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.event_available, size: 18),
              title: const Text('Ended'),
              subtitle: Text(fmt.shortDateWithDay(endDate)),
              trailing: const Icon(Icons.edit, size: 16, color: KitabColors.gray400),
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: endDate,
                  firstDate: startDate,
                  lastDate: DateTime.now(),
                );
                if (picked != null) setDialogState(() => endDate = picked);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // End the condition
              await ref.read(conditionRepositoryProvider).endCondition(
                condition.id as String, endDate,
              );
              // Cascade: reset excused statuses outside new date range
              await ref.read(periodStatusRepositoryProvider).clearExcusesOutsideRange(
                condition.id as String, startDate, endDate,
              );
              // Also update start date if changed
              if (startDate != condition.startDate) {
                final updated = (condition as dynamic).copyWith(startDate: startDate);
                await ref.read(conditionRepositoryProvider).saveCondition(updated);
              }
              ref.invalidate(activeConditionsProvider);
              refreshAllEntryProviders(ref);
              if (context.mounted) {
                KitabToast.success(context, '${condition.label} ended');
              }
            },
            child: const Text('End Condition'),
          ),
        ],
      ),
    ),
  );
}

String _pendingPeriodLabel(PendingItem item, KitabDateFormat fmt) {
  final now = DateTime.now();
  final periodDate = item.period.start;
  final isToday = periodDate.year == now.year && periodDate.month == now.month && periodDate.day == now.day;
  final isYesterday = DateTime(periodDate.year, periodDate.month, periodDate.day) ==
      DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));

  // Check for dynamic window names
  String? dynamicLabel;
  if (item.activity.schedule != null) {
    final versions = item.activity.schedule!['versions'] as List<dynamic>?;
    if (versions != null && versions.isNotEmpty) {
      final config = (versions.last as Map<String, dynamic>)['config'] as Map<String, dynamic>?;
      if (config != null) {
        final timeType = config['time_type'] as String?;
        final winStart = config['window_start'] as String?;
        final winEnd = config['window_end'] as String?;
        if (timeType == 'dynamic' && winStart != null && winEnd != null) {
          dynamicLabel = '$winStart → $winEnd';
        }
      }
    }
  }

  final dateStr = isToday ? 'Today' : isYesterday ? 'Yesterday' : fmt.shortDateWithDayName(periodDate);
  final timeStr = dynamicLabel ?? '${fmt.time(item.period.start)} — ${fmt.time(item.period.end)}';

  return '$dateStr · $timeStr';
}

// ═══════════════════════════════════════════════════════════════════
// EMPTY STATE
// ═══════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final String text;

  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KitabSpacing.xl),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: KitabRadii.borderMd,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(
        text,
        style: KitabTypography.body.copyWith(color: KitabColors.gray400),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// CONDITION CHIP (custom — avoids Material Chip label clipping bugs)
// ═══════════════════════════════════════════════════════════════════

class _ConditionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _ConditionChip({
    required this.label,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: KitabRadii.borderFull,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: KitabSpacing.md, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? KitabColors.gray800
                : KitabColors.gray50,
            borderRadius: KitabRadii.borderFull,
            border: Border.all(
              color: isDark ? KitabColors.gray700 : KitabColors.gray200,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: KitabTypography.bodySmall),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClose,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: KitabColors.gray500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════

/// Parse a hex color string like "#C8963E" into a Color.
Color _parseHexColor(String hex) {
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  } catch (_) {
    return KitabColors.primary;
  }
}

/// Determine the current time-of-day phase for subtle visual atmospherics.
/// Uses clock-based approximation (no location needed) per SPEC §14.1.
///   early_morning: 5 AM – 8 AM  (soft amber)
///   morning:       8 AM – 12 PM (warm gold)
///   afternoon:     12 PM – 5 PM (default teal)
///   evening:       5 PM – 9 PM  (deep teal)
///   night:         9 PM – 5 AM  (muted teal)
String _currentTimeOfDayPhase() {
  final h = DateTime.now().hour;
  if (h >= 5 && h < 8) return 'early_morning';
  if (h >= 8 && h < 12) return 'morning';
  if (h >= 12 && h < 17) return 'afternoon';
  if (h >= 17 && h < 21) return 'evening';
  return 'night';
}

/// Pattern tint color per time-of-day phase (see SPEC §14.1 table).
Color _timeOfDayPatternColor({required bool isDark}) {
  switch (_currentTimeOfDayPhase()) {
    case 'early_morning':
      return KitabColors.accent.withValues(alpha: isDark ? 0.06 : 0.08);
    case 'morning':
      return KitabColors.accentLight.withValues(alpha: isDark ? 0.07 : 0.10);
    case 'evening':
      return KitabColors.primaryDark.withValues(alpha: isDark ? 0.07 : 0.09);
    case 'night':
      return KitabColors.primary.withValues(alpha: isDark ? 0.05 : 0.07);
    case 'afternoon':
    default:
      return KitabColors.primary.withValues(alpha: isDark ? 0.06 : 0.09);
  }
}

/// Very subtle full-surface tint behind the pattern (warm/cool shift).
Color _timeOfDayBackgroundTint({required bool isDark}) {
  switch (_currentTimeOfDayPhase()) {
    case 'early_morning':
    case 'morning':
      return KitabColors.accent.withValues(alpha: isDark ? 0.008 : 0.015);
    case 'evening':
    case 'night':
      return KitabColors.primary.withValues(alpha: isDark ? 0.01 : 0.012);
    case 'afternoon':
    default:
      return Colors.transparent;
  }
}

/// Format a period's time window for display on activity cards.
/// Returns null for full-day periods (midnight-to-midnight).
String? _formatPeriodWindow(ComputedPeriod period) {
  final startH = period.start.hour;
  final endH = period.end.hour;
  final startM = period.start.minute;
  final endM = period.end.minute;
  // Skip midnight-to-midnight (whole-day) periods
  if (startH == 0 && startM == 0 && endH == 0 && endM == 0) return null;
  final fmt = DateFormat('h:mm a');
  return '${fmt.format(period.start)} – ${fmt.format(period.end)}';
}

// ═══════════════════════════════════════════════════════════════════
// GEOMETRIC PATTERN PAINTER (Islamic-inspired background texture)
// ═══════════════════════════════════════════════════════════════════

class _GeometricPatternPainter extends CustomPainter {
  final Color color;

  _GeometricPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: (color.a * 0.3).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    const spacing = 36.0;
    const r = spacing * 0.38; // radius for arcs

    // Islamic-inspired interlocking pattern:
    // Eight-pointed stars formed by overlapping squares, with arc connectors
    for (var x = -spacing; x < size.width + spacing * 2; x += spacing) {
      for (var y = -spacing; y < size.height + spacing * 2; y += spacing) {
        final cx = x;
        final cy = y;

        // Rotated square (45°) — forms the star points
        final star = Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r, cy)
          ..lineTo(cx, cy + r)
          ..lineTo(cx - r, cy)
          ..close();
        canvas.drawPath(star, paint);

        // Inner octagon — the center of the star
        final innerR = r * 0.45;
        final octPath = Path();
        for (var i = 0; i < 8; i++) {
          final angle = (i * 45 - 22.5) * math.pi / 180;
          final px = cx + innerR * math.cos(angle);
          final py = cy + innerR * math.sin(angle);
          if (i == 0) {
            octPath.moveTo(px, py);
          } else {
            octPath.lineTo(px, py);
          }
        }
        octPath.close();
        canvas.drawPath(octPath, fillPaint);

        // Connecting arcs between stars (horizontal)
        final arcPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8;
        // Small arc connectors to the right
        final arcPath = Path()
          ..moveTo(cx + r, cy)
          ..quadraticBezierTo(cx + spacing / 2, cy - spacing * 0.15,
              cx + spacing - r, cy);
        canvas.drawPath(arcPath, arcPaint);
        // Small arc connectors downward
        final arcPath2 = Path()
          ..moveTo(cx, cy + r)
          ..quadraticBezierTo(cx + spacing * 0.15, cy + spacing / 2,
              cx, cy + spacing - r);
        canvas.drawPath(arcPath2, arcPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
