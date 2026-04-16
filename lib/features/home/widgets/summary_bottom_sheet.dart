// ═══════════════════════════════════════════════════════════════════
// SUMMARY_BOTTOM_SHEET.DART — Today's Summary Detail Sheet
// Shows detailed breakdown of today's activities, goals, streaks,
// 3-week history grid, today's stats, and active conditions.
// Opened by tapping the summary card on Home screen.
// See SPEC.md §14.1 for full specification.
// ═══════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/services/prayer_time_service.dart';
import '../../../core/theme/kitab_theme.dart';
import '../../../core/engines/engines.dart';
import '../../../core/widgets/kitab_toast.dart';
import '../../../core/widgets/status_icon.dart';
import '../providers/home_providers.dart';

Future<void> showSummaryBottomSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return _SummaryContent(scrollController: scrollController);
      },
    ),
  );
}

class _SummaryContent extends ConsumerWidget {
  final ScrollController scrollController;

  const _SummaryContent({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(homeSummaryProvider);
    final scheduledAsync = ref.watch(scheduledTodayProvider);
    final conditionsAsync = ref.watch(activeConditionsProvider);
    final weeklyAsync = ref.watch(weeklyHistoryProvider);
    final todayEntriesAsync = ref.watch(todayEntriesProvider);
    final settings = ref.watch(userSettingsProvider);
    final hijriAsync = ref.watch(todayHijriDateProvider);
    final prayerTimesAsync = ref.watch(todayPrayerTimesProvider);

    final summary = summaryAsync.valueOrNull ?? const HomeSummary();
    final scheduled = scheduledAsync.valueOrNull ?? [];
    final conditions = conditionsAsync.valueOrNull ?? [];
    final weeklyHistory = weeklyAsync.valueOrNull ?? [];
    final todayEntries = todayEntriesAsync.valueOrNull ?? [];
    final hijri = hijriAsync.valueOrNull;
    final prayerTimes = prayerTimesAsync.valueOrNull ?? {};

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Compute status counts from scheduled activities
    final doneCount = scheduled.where((s) => s.status == 'completed').length;
    final pendingCount = scheduled.where((s) => s.status == 'pending').length;
    final excusedCount = scheduled.where((s) => s.status == 'excused').length;
    final missedCount = scheduled.where((s) => s.status == 'missed').length;

    // Compute today's stats
    final entriesLogged = todayEntries.length;

    // Time tracked: sum of entries with duration fields
    Duration totalTracked = Duration.zero;
    for (final entry in todayEntries) {
      final dur = entry.fieldValues['duration'];
      if (dur is num) {
        totalTracked += Duration(seconds: dur.toInt());
      }
    }

    // Count categories from completed scheduled activities (by category ID)
    final categoryCounts = <String, int>{};
    for (final s in scheduled) {
      if (s.status == 'completed') {
        final catId = s.activity.categoryId;
        categoryCounts[catId] = (categoryCounts[catId] ?? 0) + 1;
      }
    }

    // Resolve the most active category ID → display name
    final categoryMap = ref.watch(categoryMapProvider).valueOrNull ?? {};
    String? mostActiveCategory;
    if (categoryCounts.isNotEmpty) {
      final topCategoryId = categoryCounts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
      mostActiveCategory = categoryMap[topCategoryId] ?? topCategoryId;
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
          KitabSpacing.xl, KitabSpacing.md, KitabSpacing.xl, KitabSpacing.xxl),
      children: [
        // ─── Handle + Close Button ───
        Row(
          children: [
            const Spacer(),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KitabColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: KitabSpacing.sm),

        // ─── Title ───
        Text("Today's Summary", style: KitabTypography.h2),
        const SizedBox(height: KitabSpacing.xs),

        // ─── Date + Hijri ───
        Text(
          ref.watch(dateFormatterProvider).fullDateWithDay(DateTime.now()),
          style: KitabTypography.body.copyWith(color: KitabColors.gray500),
        ),
        if (settings.hijriCalendarEnabled && hijri != null) ...[
          const SizedBox(height: 2),
          _buildHijriLine(hijri, prayerTimes),
        ],
        const SizedBox(height: KitabSpacing.xl),

        // ─── Large Progress Ring ───
        Center(
          child: SizedBox(
            width: 130,
            height: 130,
            child: CustomPaint(
              painter: _ProgressRingPainter(
                progress: summary.progressPercent,
                trackColor: isDark ? KitabColors.gray700 : KitabColors.gray100,
                fillColor: KitabColors.primary,
                strokeWidth: 10,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${summary.metGoals}/${summary.totalGoals}',
                      style: KitabTypography.mono.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'activities done',
                      style: KitabTypography.caption.copyWith(
                        color: KitabColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: KitabSpacing.lg),

        // ─── Status Breakdown Row ───
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatusChip(
              icon: '✓',
              count: doneCount,
              label: 'Done',
              color: KitabColors.success,
            ),
            const SizedBox(width: KitabSpacing.lg),
            _StatusChip(
              icon: '○',
              count: pendingCount,
              label: 'Pending',
              color: KitabColors.gray400,
            ),
            if (excusedCount > 0) ...[
              const SizedBox(width: KitabSpacing.lg),
              _StatusChip(
                icon: '⊘',
                count: excusedCount,
                label: 'Excused',
                color: KitabColors.info,
              ),
            ],
            if (missedCount > 0) ...[
              const SizedBox(width: KitabSpacing.lg),
              _StatusChip(
                icon: '—',
                count: missedCount,
                label: 'Missed',
                color: KitabColors.error,
              ),
            ],
          ],
        ),
        const SizedBox(height: KitabSpacing.xxl),

        // ─── Streak Section ───
        _SectionHeader(title: 'Streak'),
        const SizedBox(height: KitabSpacing.sm),
        Row(
          children: [
            Text(
              summary.streakFrozen ? '🧊' : '🔥',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: KitabSpacing.sm),
            Text(
              '${summary.allGoalsStreak} day streak',
              style: KitabTypography.h3.copyWith(
                color: KitabColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: KitabSpacing.lg),

        // ─── 3-Week Calendar Grid ───
        if (weeklyHistory.isNotEmpty) ...[
          _WeeklyGrid(
            history: weeklyHistory,
            isDark: isDark,
            today: DateTime.now(),
            weekStartDay: ref.watch(userSettingsProvider).weekStartDay,
          ),
          const SizedBox(height: KitabSpacing.sm),
          // Legend
          Wrap(
            alignment: WrapAlignment.center,
            spacing: KitabSpacing.md,
            runSpacing: KitabSpacing.xs,
            children: [
              _GridLegendItem(color: KitabColors.success, label: 'All done'),
              _GridLegendItem(color: KitabColors.info, label: 'Excused'),
              _GridLegendItem(color: KitabColors.error, label: 'Missed'),
              _GridLegendItem(color: KitabColors.primary, label: 'Pending', isHollow: true),
            ],
          ),
          const SizedBox(height: KitabSpacing.xxl),
        ],

        // ─── Today's Stats ───
        _SectionHeader(title: "Today's Stats"),
        const SizedBox(height: KitabSpacing.md),
        _StatsRow(
          totalTracked: totalTracked,
          entriesLogged: entriesLogged,
          mostActiveCategory: mostActiveCategory,
        ),
        const SizedBox(height: KitabSpacing.xxl),

        // ─── Activity Breakdown ───
        _SectionHeader(title: 'Activity Breakdown'),
        const SizedBox(height: KitabSpacing.md),
        if (scheduled.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: KitabSpacing.md),
            child: Text(
              'No scheduled activities today',
              style:
                  KitabTypography.body.copyWith(color: KitabColors.gray500),
            ),
          )
        else
          ...scheduled.map((item) => _ActivityRow(item: item, fmt: ref.watch(dateFormatterProvider))),

        // ─── Active Conditions ───
        if (conditions.isNotEmpty) ...[
          const SizedBox(height: KitabSpacing.xxl),
          _SectionHeader(title: 'Active Conditions'),
          const SizedBox(height: KitabSpacing.md),
          ...conditions.map((c) {
            final daysSince =
                DateTime.now().difference(c.startDate).inDays + 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: KitabSpacing.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: KitabSpacing.lg, vertical: KitabSpacing.md),
                decoration: BoxDecoration(
                  color: KitabColors.info.withValues(alpha: 0.08),
                  borderRadius: KitabRadii.borderMd,
                ),
                child: Row(
                  children: [
                    Text(c.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: KitabSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.label, style: KitabTypography.body),
                          Text(
                            'Day $daysSince',
                            style: KitabTypography.caption
                                .copyWith(color: KitabColors.gray500),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final conditionRepo =
                            ref.read(conditionRepositoryProvider);
                        await conditionRepo.endCondition(
                            c.id, DateTime.now());
                        if (context.mounted) {
                          KitabToast.success(context,
                              '${c.label} condition ended');
                        }
                      },
                      child: const Text('End'),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],

        const SizedBox(height: KitabSpacing.lg),
      ],
    );
  }

  /// Build the Hijri date line with day/night icon.
  Widget _buildHijriLine(
    HijriDate hijri,
    Map<String, String> prayerTimes,
  ) {
    String icon;
    String hijriText;

    final now = DateTime.now();
    DateTime? sunrise;
    DateTime? maghrib;

    try {
      if (prayerTimes['Sunrise'] != null) {
        sunrise = _parsePrayerTime(prayerTimes['Sunrise']!, now);
      }
      if (prayerTimes['Maghrib'] != null) {
        maghrib = _parsePrayerTime(prayerTimes['Maghrib']!, now);
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
        Text('$icon ', style: KitabTypography.bodySmall),
        Flexible(
          child: Text(
            hijriText,
            style: KitabTypography.caption
                .copyWith(color: KitabColors.gray500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  DateTime _parsePrayerTime(String timeStr, DateTime now) {
    final parts =
        timeStr.replaceAll(RegExp(r'[APap][Mm]'), '').trim().split(':');
    var h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    if (timeStr.toUpperCase().contains('PM') && h != 12) h += 12;
    if (timeStr.toUpperCase().contains('AM') && h == 12) h = 0;
    return DateTime(now.year, now.month, now.day, h, m);
  }
}

// ═══════════════════════════════════════════════════════════════════
// PROGRESS RING PAINTER
// ═══════════════════════════════════════════════════════════════════

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color fillColor;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track (background circle)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Fill arc
    if (progress > 0) {
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start from top
        sweepAngle,
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.fillColor != fillColor;
}

// ═══════════════════════════════════════════════════════════════════
// STATUS BREAKDOWN CHIP
// ═══════════════════════════════════════════════════════════════════

class _StatusChip extends StatelessWidget {
  final String icon;
  final int count;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
          alignment: Alignment.center,
          child: Text(
            icon,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: KitabTypography.bodySmall.copyWith(
            color: KitabColors.gray500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SECTION HEADER
// ═══════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: isDark ? KitabColors.gray700 : KitabColors.gray200,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: KitabSpacing.md),
          child: Text(
            title,
            style: KitabTypography.caption.copyWith(
              color: KitabColors.gray500,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: isDark ? KitabColors.gray700 : KitabColors.gray200,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 3-WEEK CALENDAR GRID
// ═══════════════════════════════════════════════════════════════════

class _WeeklyGrid extends StatelessWidget {
  final List<DayHistoryEntry> history;
  final bool isDark;
  final DateTime today;
  final int weekStartDay;

  const _WeeklyGrid({
    required this.history,
    required this.isDark,
    required this.today,
    required this.weekStartDay,
  });

  // All day abbreviations starting from Sunday (index 0)
  static const _allDayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final todayDay = DateTime(today.year, today.month, today.day);
    // Rotate day labels based on weekStartDay (0=Sun, 1=Mon, ..., 6=Sat)
    final dayLabels = List.generate(
      7, (i) => _allDayLabels[(weekStartDay + i) % 7],
    );
    // Row labels
    const weekLabels = ['2 wks ago', 'Last week', 'This week'];

    return Column(
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.only(bottom: KitabSpacing.xs),
          child: Row(
            children: [
              // Space for week label
              const SizedBox(width: 72),
              ...dayLabels.map((d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: KitabTypography.caption.copyWith(
                          color: KitabColors.gray400,
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        ),
        // 3 week rows
        for (var week = 0; week < 3; week++)
          Padding(
            padding: const EdgeInsets.only(bottom: KitabSpacing.xs),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    weekLabels[week],
                    style: KitabTypography.caption
                        .copyWith(color: KitabColors.gray400),
                  ),
                ),
                for (var day = 0; day < 7; day++)
                  Expanded(
                    child: Center(
                      child: _buildDot(
                        week * 7 + day < history.length
                            ? history[week * 7 + day]
                            : null,
                        todayDay,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDot(DayHistoryEntry? entry, DateTime todayDay) {
    if (entry == null) return const SizedBox(width: 16, height: 16);

    final isToday = entry.date == todayDay;

    Color color;
    bool isHollow = false;

    switch (entry.status) {
      case DayStatus.allDone:
        color = KitabColors.success;
      case DayStatus.excused:
        color = KitabColors.info;
      case DayStatus.missed:
        color = KitabColors.error;
      case DayStatus.pending:
        // Today with nothing done — hollow with primary border
        color = KitabColors.primary;
        isHollow = true;
      case DayStatus.future:
        color = isDark ? KitabColors.gray700 : KitabColors.gray200;
        isHollow = true;
      case DayStatus.noData:
        color = isDark ? KitabColors.gray700 : KitabColors.gray200;
        isHollow = true;
    }

    // Today gets a larger dot with an outer ring to stand out
    if (isToday) {
      return Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? KitabColors.gray400 : KitabColors.gray600,
            width: 2,
          ),
        ),
        child: Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isHollow ? null : color,
              border: isHollow ? Border.all(color: color, width: 1.5) : null,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: isHollow ? null : color,
        border: isHollow ? Border.all(color: color, width: 1.5) : null,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// GRID LEGEND ITEM
// ═══════════════════════════════════════════════════════════════════

class _GridLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isHollow;

  const _GridLegendItem({
    required this.color,
    required this.label,
    this.isHollow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isHollow ? null : color,
            border: isHollow ? Border.all(color: color, width: 1.5) : null,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: KitabTypography.caption.copyWith(color: KitabColors.gray500),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TODAY'S STATS ROW
// ═══════════════════════════════════════════════════════════════════

class _StatsRow extends StatelessWidget {
  final Duration totalTracked;
  final int entriesLogged;
  final String? mostActiveCategory;

  const _StatsRow({
    required this.totalTracked,
    required this.entriesLogged,
    this.mostActiveCategory,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(KitabSpacing.lg),
      decoration: BoxDecoration(
        color: isDark
            ? KitabColors.gray800.withValues(alpha: 0.5)
            : KitabColors.gray50,
        borderRadius: KitabRadii.borderMd,
      ),
      child: Column(
        children: [
          if (totalTracked > Duration.zero)
            _StatLine(
              icon: Icons.timer_outlined,
              label: 'Time tracked',
              value: _formatDuration(totalTracked),
            ),
          _StatLine(
            icon: Icons.edit_note,
            label: 'Entries logged',
            value: '$entriesLogged',
          ),
          if (mostActiveCategory != null)
            _StatLine(
              icon: Icons.category_outlined,
              label: 'Most active',
              value: mostActiveCategory!,
              isLast: true,
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m';
  }
}

class _StatLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _StatLine({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : KitabSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 16, color: KitabColors.gray400),
          const SizedBox(width: KitabSpacing.sm),
          Text(label, style: KitabTypography.bodySmall),
          const Spacer(),
          Text(
            value,
            style: KitabTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ACTIVITY BREAKDOWN ROW
// ═══════════════════════════════════════════════════════════════════

class _ActivityRow extends StatelessWidget {
  final ScheduledActivityState item;
  final KitabDateFormat fmt;

  const _ActivityRow({required this.item, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted =
        item.status == 'completed' || item.status == 'excused';

    // Format period time window
    final timeWindow = _formatTimeWindow(item.period);

    return Padding(
      padding: const EdgeInsets.only(bottom: KitabSpacing.sm),
      child: Opacity(
        opacity: isCompleted ? 0.6 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: KitabSpacing.md, vertical: KitabSpacing.sm),
          decoration: BoxDecoration(
            color: isDark
                ? KitabColors.gray800.withValues(alpha: 0.3)
                : KitabColors.gray50.withValues(alpha: 0.5),
            borderRadius: KitabRadii.borderSm,
          ),
          child: Row(
            children: [
              StatusIcon(
                status: switch (item.status) {
                  'completed' => ActivityStatus.completed,
                  'missed' => ActivityStatus.missed,
                  'excused' => ActivityStatus.excused,
                  _ => ActivityStatus.pending,
                },
              ),
              const SizedBox(width: KitabSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.activity.name, style: KitabTypography.body),
                    if (timeWindow != null)
                      Text(
                        timeWindow,
                        style: KitabTypography.caption
                            .copyWith(color: KitabColors.gray500),
                      ),
                  ],
                ),
              ),
              if (item.primaryGoalEval != null &&
                  item.primaryGoalEval!.progressText != null)
                Text(
                  item.primaryGoalEval!.progressText!,
                  style: KitabTypography.monoSmall.copyWith(
                    color: KitabColors.gray500,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String? _formatTimeWindow(ComputedPeriod period) {
    final startHour = period.start.hour;
    final endHour = period.end.hour;

    // Skip midnight-to-midnight (full day) periods
    if (startHour == 0 && endHour == 0 &&
        period.end.difference(period.start).inHours >= 23) {
      return null;
    }

    return '${fmt.time(period.start)} – ${fmt.time(period.end)}';
  }
}
