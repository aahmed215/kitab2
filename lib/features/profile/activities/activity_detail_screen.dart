// ═══════════════════════════════════════════════════════════════════
// ACTIVITY_DETAIL_SCREEN.DART — Activity Overview & History
// Shows: overview stats, goal performance, entry history.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/theme/kitab_theme.dart';
import '../../../core/widgets/streak_badge.dart';
import '../../../data/models/activity.dart';
import '../../../data/models/category.dart' as domain;
import '../../../core/utils/condition_merge.dart' show createOrExtendCondition;
import '../../../data/models/entry.dart';
import '../../../data/models/period_status.dart';
import '../../../core/widgets/kitab_toast.dart';
import '../../entry/entry_form_screen.dart';
import 'activity_form_screen.dart';
import 'widgets/field_config_section.dart' show FieldConfig;

class ActivityDetailScreen extends ConsumerWidget {
  final Activity activity;

  const ActivityDetailScreen({super.key, required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            activity.isPrivate ? '••••••••' : activity.name,
            style: KitabTypography.h2,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ActivityFormScreen(existingActivity: activity),
                ),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Goals'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(activity: activity, userId: userId),
            _GoalsTab(activity: activity),
            _HistoryTab(activity: activity, userId: userId),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  final Activity activity;
  final String userId;

  const _OverviewTab({required this.activity, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesFuture = ref.read(entryRepositoryProvider).getByActivityAndDateRange(
      userId, activity.id, DateTime(2020), DateTime.now().add(const Duration(days: 1)),
    );
    final statusesFuture = ref.read(periodStatusRepositoryProvider)
        .getActivityStatusHistory(userId, activity.id);
    final categoryFuture = ref.read(categoryRepositoryProvider).getById(activity.categoryId);

    return FutureBuilder(
      future: Future.wait([entriesFuture, statusesFuture, categoryFuture]),
      builder: (context, snapshot) {
        final entries = (snapshot.data?[0] as List<Entry>?) ?? [];
        final statuses = (snapshot.data?[1] as List<ActivityPeriodStatus>?) ?? [];
        final category = snapshot.data?[2] as domain.Category?;

        // Compute streak from actual entries (more reliable than period status matching)
        // Compute streaks with correct rules:
        // - Completed (has entry) → streak +1
        // - Excused → streak unchanged (skip, don't break or increase)
        // - Missed → streak resets to 0
        // - Pending → streak frozen (stop counting, don't reset)
        int currentStreak = 0;
        int bestStreak = 0;
        bool streakFrozen = false;

        if (activity.schedule != null) {
          final entriesByDay = <String, bool>{};
          for (final e in entries) {
            final key = '${e.loggedAt.year}-${e.loggedAt.month}-${e.loggedAt.day}';
            entriesByDay[key] = true;
          }

          final statusByDay = <String, String>{};
          for (final s in statuses) {
            final key = '${s.periodStart.year}-${s.periodStart.month}-${s.periodStart.day}';
            statusByDay[key] = s.status;
          }

          // Current streak: walk backwards from today
          final now = DateTime.now();
          for (var i = 0; i < 365; i++) {
            final checkDate = now.subtract(Duration(days: i));
            final key = '${checkDate.year}-${checkDate.month}-${checkDate.day}';

            final hasEntry = entriesByDay.containsKey(key);
            final dayStatus = statusByDay[key];
            final isMissed = dayStatus == 'missed';
            final isExcused = dayStatus == 'excused';
            final isPending = !hasEntry && dayStatus == null;

            if (hasEntry) {
              currentStreak++;
            } else if (isExcused) {
              // Excused: skip this day, don't increase or break streak
              continue;
            } else if (isPending && i == 0) {
              // Today is pending: freeze the streak
              streakFrozen = true;
              continue;
            } else if (isMissed || isPending) {
              // Missed or older pending: break the streak
              break;
            } else {
              break;
            }
          }

          // Best streak: walk through all days from start
          int tempStreak = 0;
          final startDate = activity.createdAt;
          final totalDays = now.difference(startDate).inDays + 1;
          for (var i = 0; i < totalDays && i < 365; i++) {
            final checkDate = DateTime(startDate.year, startDate.month, startDate.day).add(Duration(days: i));
            final key = '${checkDate.year}-${checkDate.month}-${checkDate.day}';

            final hasEntry = entriesByDay.containsKey(key);
            final dayStatus = statusByDay[key];
            final isExcused = dayStatus == 'excused';
            final isMissed = dayStatus == 'missed';

            if (hasEntry) {
              tempStreak++;
              if (tempStreak > bestStreak) bestStreak = tempStreak;
            } else if (isExcused) {
              // Excused: don't count but don't break
              continue;
            } else if (isMissed) {
              // Missed: reset
              tempStreak = 0;
            } else {
              // Pending/no data: don't break (activity may not have been scheduled)
            }
          }
        }

        final allZero = currentStreak == 0 && bestStreak == 0 && entries.isEmpty;

        return ListView(
          padding: const EdgeInsets.all(KitabSpacing.lg),
          children: [
            // ─── Stats card ───
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: KitabRadii.borderMd,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(
                        label: 'Current Streak',
                        child: StreakBadge(
                          count: currentStreak,
                          isFrozen: streakFrozen,
                        ),
                      ),
                      _StatColumn(
                        label: 'Best Streak',
                        child: Text('${bestStreak}d', style: KitabTypography.mono),
                      ),
                      _StatColumn(
                        label: 'Total Entries',
                        child: Text('${entries.length}', style: KitabTypography.mono),
                      ),
                    ],
                  ),
                  if (allZero) ...[
                    const SizedBox(height: KitabSpacing.sm),
                    Text('Ready to start your streak!',
                        style: KitabTypography.caption.copyWith(color: KitabColors.primary)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: KitabSpacing.lg),

            // ─── At a glance ───
            _SectionHeader(title: 'At a Glance'),
            const SizedBox(height: KitabSpacing.sm),
            _buildAtAGlance(category, ref.watch(dateFormatterProvider)),
            const SizedBox(height: KitabSpacing.lg),

            // ─── Description ───
            if (activity.description != null && activity.description!.isNotEmpty) ...[
              _SectionHeader(title: 'Description'),
              const SizedBox(height: KitabSpacing.sm),
              Text(activity.description!, style: KitabTypography.body),
              const SizedBox(height: KitabSpacing.lg),
            ],

            // ─── Schedule ───
            _SectionHeader(title: 'Schedule'),
            const SizedBox(height: KitabSpacing.sm),
            _buildScheduleDetails(ref.watch(dateFormatterProvider)),
            const SizedBox(height: KitabSpacing.lg),

            // ─── Fields ───
            if (activity.fields.isNotEmpty) ...[
              _SectionHeader(title: 'Fields'),
              const SizedBox(height: KitabSpacing.sm),
              _buildFields(),
              const SizedBox(height: KitabSpacing.lg),
            ],

            // ─── Primary goal ───
            _buildPrimaryGoal(),
          ],
        );
      },
    );
  }

  // ─── At a glance: category, privacy, created ───
  Widget _buildAtAGlance(domain.Category? category, KitabDateFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(KitabSpacing.md),
      decoration: BoxDecoration(
        color: KitabColors.gray100.withValues(alpha: 0.5),
        borderRadius: KitabRadii.borderMd,
      ),
      child: Column(
        children: [
          if (category != null)
            _InfoRow(
              icon: Icons.category_outlined,
              label: 'Category',
              value: '${category.icon} ${category.name}',
            ),
          if (activity.isPrivate)
            const _InfoRow(
              icon: Icons.lock_outline,
              label: 'Privacy',
              value: 'Private — hidden from others',
            ),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Created',
            value: fmt.fullDate(activity.createdAt),
          ),
          _InfoRow(
            icon: Icons.update,
            label: 'Last Updated',
            value: fmt.fullDate(activity.updatedAt),
          ),
        ],
      ),
    );
  }

  // ─── Schedule details ───
  Widget _buildScheduleDetails(KitabDateFormat fmt) {
    if (activity.schedule == null) {
      return Container(
        padding: const EdgeInsets.all(KitabSpacing.md),
        decoration: BoxDecoration(
          color: KitabColors.gray100.withValues(alpha: 0.5),
          borderRadius: KitabRadii.borderMd,
        ),
        child: const _InfoRow(
          icon: Icons.all_inclusive,
          label: 'Frequency',
          value: 'No schedule — log whenever you want',
        ),
      );
    }

    final versions = activity.schedule!['versions'] as List<dynamic>?;
    if (versions == null || versions.isEmpty) {
      return Text('Schedule configured', style: KitabTypography.body.copyWith(color: KitabColors.gray500));
    }

    final latestVersion = versions.last as Map<String, dynamic>;
    final config = latestVersion['config'] as Map<String, dynamic>? ?? {};
    final freq = config['frequency'] as String? ?? 'daily';
    final calendar = config['calendar'] as String? ?? 'gregorian';
    // Prefer the version's effective_from over config.start_date — that's
    // the authoritative "Starts" date after retroactive schedule changes.
    final startDate = (latestVersion['effective_from'] as String?) ??
        (config['start_date'] as String?);
    final endDate = (latestVersion['effective_to'] as String?) ??
        (config['end_date'] as String?);
    final selectionMode = config['selection_mode'] as String? ?? 'specific';
    final selectedDays = (config['selected_days'] as List<dynamic>?)?.cast<int>() ?? [];
    final hasTimeWindow = config['has_time_window'] as bool? ?? false;
    final timeType = config['time_type'] as String? ?? 'specific';
    final windowStart = config['window_start'] as String?;
    final windowEnd = config['window_end'] as String?;
    final windowStartOffset = config['window_start_offset'] as int? ?? 0;
    final windowEndOffset = config['window_end_offset'] as int? ?? 0;
    final expectedEntries = config['expected_entries'] as String? ?? 'once';
    final consecutiveAsOne = config['consecutive_as_one_period'] as bool? ?? false;
    final customInterval = config['custom_interval'] as int? ?? 1;
    final customUnit = config['custom_unit'] as String? ?? 'days';

    // Build frequency label
    final freqLabel = switch (freq) {
      'daily' => 'Daily',
      'weekly' => _weeklyLabel(selectionMode, selectedDays, consecutiveAsOne),
      'monthly' => _monthlyLabel(selectionMode, selectedDays, consecutiveAsOne),
      'yearly' => 'Yearly',
      'custom' => 'Every $customInterval $customUnit',
      _ => freq,
    };

    // Build time window label
    String? windowLabel;
    if (hasTimeWindow && windowStart != null && windowEnd != null) {
      if (timeType == 'dynamic') {
        final startLabel = _dynamicTimeLabel(windowStart, windowStartOffset);
        final endLabel = _dynamicTimeLabel(windowEnd, windowEndOffset);
        windowLabel = '$startLabel → $endLabel';
      } else {
        windowLabel = '$windowStart → $windowEnd';
      }
    }

    return Container(
      padding: const EdgeInsets.all(KitabSpacing.md),
      decoration: BoxDecoration(
        color: KitabColors.gray100.withValues(alpha: 0.5),
        borderRadius: KitabRadii.borderMd,
      ),
      child: Column(
        children: [
          _InfoRow(icon: Icons.repeat, label: 'Frequency', value: freqLabel),
          if (calendar == 'hijri')
            const _InfoRow(icon: Icons.auto_awesome, label: 'Calendar', value: 'Hijri'),
          if (startDate != null)
            _InfoRow(
              icon: Icons.play_arrow_outlined,
              label: 'Starts',
              value: _formatDate(startDate, fmt),
            ),
          if (endDate != null)
            _InfoRow(
              icon: Icons.stop_outlined,
              label: 'Ends',
              value: _formatDate(endDate, fmt),
            ),
          if (windowLabel != null)
            _InfoRow(icon: Icons.schedule, label: 'Time Window', value: windowLabel),
          if (expectedEntries == 'multiple')
            const _InfoRow(icon: Icons.layers_outlined, label: 'Entries', value: 'Multiple per period'),
        ],
      ),
    );
  }

  String _weeklyLabel(String mode, List<int> days, bool consecutive) {
    if (mode == 'any') return 'Weekly — any day';
    if (days.isEmpty) return 'Weekly';
    const dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final names = days.map((d) => d >= 1 && d <= 7 ? dayNames[d] : '?').join(', ');
    final suffix = consecutive ? ' (as one period)' : '';
    return 'Weekly — $names$suffix';
  }

  String _monthlyLabel(String mode, List<int> days, bool consecutive) {
    if (mode == 'any') return 'Monthly — any day';
    if (days.isEmpty) return 'Monthly';
    final dayStr = days.length <= 5
        ? days.map((d) => _ordinal(d)).join(', ')
        : '${days.length} selected days';
    final suffix = consecutive ? ' (as one period)' : '';
    return 'Monthly — $dayStr$suffix';
  }

  String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    return switch (n % 10) {
      1 => '${n}st',
      2 => '${n}nd',
      3 => '${n}rd',
      _ => '${n}th',
    };
  }

  String _dynamicTimeLabel(String ref, int offset) {
    final name = switch (ref) {
      'fajr' => 'Fajr',
      'sunrise' => 'Sunrise',
      'dhuhr' => 'Dhuhr',
      'asr' => 'Asr',
      'maghrib' => 'Maghrib',
      'isha' => 'Isha',
      _ => ref,
    };
    if (offset == 0) return name;
    final sign = offset > 0 ? '+' : '';
    return '$name $sign${offset}min';
  }

  String _formatDate(String isoDate, KitabDateFormat fmt) {
    try {
      return fmt.fullDate(DateTime.parse(isoDate));
    } catch (_) {
      return isoDate;
    }
  }

  // ─── Fields list ───
  Widget _buildFields() {
    return Wrap(
      spacing: KitabSpacing.xs,
      runSpacing: KitabSpacing.xs,
      children: activity.fields.map((f) {
        final fieldConfig = FieldConfig.fromJson(Map<String, dynamic>.from(f));
        return Chip(
          avatar: Icon(fieldConfig.type.icon, size: 16, color: KitabColors.gray500),
          label: Text(fieldConfig.label, style: KitabTypography.caption),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }

  // ─── Primary goal one-liner ───
  Widget _buildPrimaryGoal() {
    if (activity.goals == null) return const SizedBox.shrink();

    final versions = activity.goals!['versions'] as List<dynamic>?;
    if (versions == null || versions.isEmpty) return const SizedBox.shrink();

    final goals = (versions.last as Map<String, dynamic>)['goals'] as List<dynamic>? ?? [];
    if (goals.isEmpty) return const SizedBox.shrink();

    // Find primary goal, or first goal
    final primary = goals.firstWhere(
      (g) => (g as Map<String, dynamic>)['is_primary'] == true,
      orElse: () => goals.first,
    ) as Map<String, dynamic>;

    final goalType = primary['goal_type'] as String? ?? 'completion';
    final name = primary['name'] as String? ?? '';

    // Build a short summary
    String summary;
    switch (goalType) {
      case 'completion':
        final comp = _compLabelShort(primary['completion_comparison'] as String? ?? '>=');
        final count = primary['completion_count']?.toString() ?? '1';
        final freq = _getFrequency();
        summary = 'Complete $comp $count ${int.tryParse(count) == 1 ? 'time' : 'times'} per $freq';
      case 'target':
        final condition = primary['condition'] as Map<String, dynamic>?;
        final fieldLabel = condition?['field_label'] as String? ?? 'field';
        final comp = _compLabelShort(condition?['comparison'] as String? ?? '>=');
        if (condition?['use_relative_time'] == true) {
          final anchor = condition?['relative_time_anchor'] == 'window_end' ? 'window end' : 'window start';
          final offset = condition?['relative_time_offset']?.toString() ?? '?';
          summary = '$fieldLabel $comp $offset min of $anchor';
        } else {
          final target = condition?['target_value']?.toString() ??
              condition?['target_text'] as String? ?? '?';
          summary = '$fieldLabel $comp $target';
        }
      case 'combined':
        final conditions = primary['conditions'] as List<dynamic>? ?? [];
        final logic = primary['combine_logic'] == 'all' ? 'all' : 'any';
        summary = '${conditions.length} conditions — $logic must be met';
      default:
        summary = 'Goal configured';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Primary Goal'),
        const SizedBox(height: KitabSpacing.sm),
        Container(
          padding: const EdgeInsets.all(KitabSpacing.md),
          decoration: BoxDecoration(
            color: KitabColors.accent.withValues(alpha: 0.05),
            borderRadius: KitabRadii.borderMd,
            border: Border.all(color: KitabColors.accent.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.star, size: 20, color: KitabColors.accent),
              const SizedBox(width: KitabSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (name.isNotEmpty)
                      Text(name, style: KitabTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                    Text(summary, style: KitabTypography.body.copyWith(color: KitabColors.gray600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getFrequency() {
    if (activity.schedule == null) return 'period';
    final versions = activity.schedule!['versions'] as List<dynamic>?;
    if (versions == null || versions.isEmpty) return 'period';
    final config = (versions.last as Map<String, dynamic>)['config'] as Map<String, dynamic>?;
    final freq = config?['frequency'] as String? ?? 'daily';
    return switch (freq) {
      'daily' => 'day',
      'weekly' => 'week',
      'monthly' => 'month',
      'yearly' => 'year',
      _ => 'period',
    };
  }

  String _compLabelShort(String comp) {
    return switch (comp) {
      '>=' => 'at least',
      '<=' => 'at most',
      '=' || '==' => 'exactly',
      '>' => 'more than',
      '<' => 'less than',
      _ => comp,
    };
  }
}

// ─── Reusable section header ───
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: KitabTypography.h3);
  }
}

// ─── Reusable info row ───
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: KitabColors.gray400),
          const SizedBox(width: KitabSpacing.sm),
          SizedBox(
            width: 100,
            child: Text(label, style: KitabTypography.caption.copyWith(color: KitabColors.gray500)),
          ),
          Expanded(
            child: Text(value, style: KitabTypography.body),
          ),
        ],
      ),
    );
  }
}

class _GoalsTab extends StatelessWidget {
  final Activity activity;

  const _GoalsTab({required this.activity});

  @override
  Widget build(BuildContext context) {
    if (activity.goals == null) {
      return Center(
        child: Text('No goals configured',
            style: KitabTypography.body.copyWith(color: KitabColors.gray500)),
      );
    }

    final versions = activity.goals!['versions'] as List<dynamic>?;
    if (versions == null || versions.isEmpty) {
      return Center(
        child: Text('No goals configured',
            style: KitabTypography.body.copyWith(color: KitabColors.gray500)),
      );
    }

    final latest = versions.last as Map<String, dynamic>;
    final goals = latest['goals'] as List<dynamic>? ?? [];

    if (goals.isEmpty) {
      return Center(
        child: Text('No goals configured',
            style: KitabTypography.body.copyWith(color: KitabColors.gray500)),
      );
    }

    // Get frequency from schedule for context
    final freq = _getFrequency();

    return ListView.builder(
      padding: const EdgeInsets.all(KitabSpacing.lg),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final goal = goals[index] as Map<String, dynamic>;
        return _GoalCard(goal: goal, frequency: freq);
      },
    );
  }

  String _getFrequency() {
    if (activity.schedule == null) return 'period';
    final versions = activity.schedule!['versions'] as List<dynamic>?;
    if (versions == null || versions.isEmpty) return 'period';
    final config = (versions.last as Map<String, dynamic>)['config'] as Map<String, dynamic>?;
    if (config == null) return 'period';
    final freq = config['frequency'] as String? ?? 'daily';
    return switch (freq) {
      'daily' => 'day',
      'weekly' => 'week',
      'monthly' => 'month',
      'yearly' => 'year',
      _ => 'period',
    };
  }
}

class _GoalCard extends StatelessWidget {
  final Map<String, dynamic> goal;
  final String frequency;

  const _GoalCard({required this.goal, required this.frequency});

  @override
  Widget build(BuildContext context) {
    final goalType = goal['goal_type'] as String? ?? 'completion';
    final isPrimary = goal['is_primary'] as bool? ?? false;
    final name = goal['name'] as String? ?? '';

    // Icon and color based on type
    final (IconData icon, Color color) = switch (goalType) {
      'completion' => (Icons.check_circle_outline, KitabColors.success),
      'target' => (Icons.track_changes, KitabColors.primary),
      'combined' => (Icons.join_inner, KitabColors.info),
      _ => (Icons.flag_outlined, KitabColors.gray400),
    };

    final typeLabel = switch (goalType) {
      'completion' => 'Completion goal',
      'target' => 'Target goal',
      'combined' => 'Combined goal',
      _ => 'Goal',
    };

    return Card(
      margin: const EdgeInsets.only(bottom: KitabSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(KitabSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: KitabSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isNotEmpty ? name : typeLabel,
                        style: KitabTypography.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (name.isNotEmpty)
                        Text(typeLabel,
                            style: KitabTypography.caption.copyWith(color: KitabColors.gray500)),
                    ],
                  ),
                ),
                if (isPrimary)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: KitabColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: KitabColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 14, color: KitabColors.accent),
                        const SizedBox(width: 3),
                        Text('Primary',
                            style: KitabTypography.caption.copyWith(
                                color: KitabColors.accent, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: KitabSpacing.sm),
            const Divider(height: 1),
            const SizedBox(height: KitabSpacing.sm),

            // Goal description
            Text(
              _buildDescription(goalType),
              style: KitabTypography.body.copyWith(color: KitabColors.gray600),
            ),

            // Success rate
            if (goal['success_rate_type'] != null) ...[
              const SizedBox(height: KitabSpacing.xs),
              _buildSuccessRate(),
            ],
          ],
        ),
      ),
    );
  }

  String _buildDescription(String goalType) {
    switch (goalType) {
      case 'completion':
        final comparison = _compLabel(goal['completion_comparison'] as String? ?? '>=');
        final count = goal['completion_count']?.toString() ?? '1';
        return 'Complete this activity $comparison $count ${int.tryParse(count) == 1 ? 'time' : 'times'} per $frequency';

      case 'target':
        return _buildTargetDescription(goal['condition'] as Map<String, dynamic>?);

      case 'combined':
        final logic = goal['combine_logic'] as String? ?? 'all';
        final conditions = goal['conditions'] as List<dynamic>? ?? [];
        final logicText = logic == 'all' ? 'All conditions must be met' : 'Any condition must be met';
        final buf = StringBuffer(logicText);
        for (var i = 0; i < conditions.length; i++) {
          final cond = conditions[i] as Map<String, dynamic>;
          buf.write('\n  ${i + 1}. ${_buildConditionSummary(cond)}');
        }
        return buf.toString();

      default:
        return 'Goal configured';
    }
  }

  String _buildTargetDescription(Map<String, dynamic>? condition) {
    if (condition == null) return 'Target configured';

    final fieldLabel = condition['field_label'] as String? ?? 'Field';
    final scope = _scopeLabel(goal['entries_scope'] as String? ?? 'most_recent');
    final calc = goal['calculation'] as String?;

    final buf = StringBuffer();

    // "The [calculation] of [field] across [scope]..."
    if (calc != null && calc != 'sum' && goal['entries_scope'] != 'most_recent') {
      buf.write('The ${_calcLabel(calc)} of $fieldLabel ($scope)');
    } else if (goal['entries_scope'] == 'most_recent') {
      buf.write('$fieldLabel (most recent entry)');
    } else {
      buf.write('$fieldLabel ($scope)');
    }

    // "...should be [comparison] [target]"
    buf.write(' should be ');
    buf.write(_buildConditionTarget(condition));

    return buf.toString();
  }

  String _buildConditionSummary(Map<String, dynamic> cond) {
    final fieldLabel = cond['field_label'] as String? ?? 'Field';
    return '$fieldLabel ${_buildConditionTarget(cond)}';
  }

  String _buildConditionTarget(Map<String, dynamic> cond) {
    final comparison = cond['comparison'] as String? ?? '>=';

    // Time-relative target
    if (cond['use_relative_time'] == true) {
      final anchor = cond['relative_time_anchor'] == 'window_end' ? 'window end' : 'window start';
      final offset = cond['relative_time_offset']?.toString() ?? '0';
      return '${_compLabel(comparison)} $offset min of $anchor';
    }

    // Calculated target
    if (cond['use_calculated_target'] == true) {
      final agg = _calcLabel(cond['calc_target_aggregation'] as String? ?? 'average');
      final scope = cond['calc_target_scope'] as String? ?? 'last_n_entries';
      final count = cond['calc_target_scope_count']?.toString();
      final scopeText = switch (scope) {
        'previous' => 'previous entry',
        'all_time' => 'all entries',
        String s when s.startsWith('last_n_') && count != null => 'last $count ${s.replaceAll('last_n_', '')}',
        _ => scope.replaceAll('_', ' '),
      };
      return '${_compLabel(comparison)} $agg of $scopeText';
    }

    // Location target
    if (cond['location_name'] != null) {
      final radius = cond['location_radius']?.toStringAsFixed(0) ?? '500';
      return '${_compLabel(comparison == 'at_location' ? 'at' : comparison)} ${cond['location_name']} (within ${radius}m)';
    }

    // Regular target value
    final targetValue = cond['target_value'];
    final targetText = cond['target_text'] as String?;
    final targetBool = cond['target_bool'];

    String valueStr;
    if (targetBool != null) {
      valueStr = targetBool == true ? 'Yes' : 'No';
    } else if (targetText != null) {
      valueStr = targetText;
    } else if (targetValue != null) {
      final num = targetValue is double && targetValue == targetValue.roundToDouble()
          ? targetValue.toInt().toString()
          : targetValue.toString();
      valueStr = num;
    } else {
      valueStr = '?';
    }

    if (comparison == 'between' || comparison == 'not_between') {
      final to = cond['target_to']?.toString() ?? '?';
      return '${_compLabel(comparison)} $valueStr and $to';
    }

    return '${_compLabel(comparison)} $valueStr';
  }

  Widget _buildSuccessRate() {
    final type = goal['success_rate_type'] as String? ?? 'percentage';
    final value = goal['success_rate_value']?.toString() ?? '80';
    final of = goal['success_rate_of']?.toString();

    final text = type == 'percentage'
        ? 'Success rate: at least $value% of all entries'
        : 'Success rate: at least $value of last ${of ?? '?'} entries';

    return Row(
      children: [
        Icon(Icons.trending_up, size: 14, color: KitabColors.gray400),
        const SizedBox(width: 4),
        Flexible(
          child: Text(text,
              style: KitabTypography.caption.copyWith(color: KitabColors.gray500)),
        ),
      ],
    );
  }

  String _compLabel(String comp) {
    return switch (comp) {
      '>=' => 'at least',
      '<=' => 'at most',
      '=' || '==' => 'exactly',
      '>' => 'more than',
      '<' => 'less than',
      'between' => 'between',
      'not_between' => 'not between',
      'contains' => 'contains',
      'not_contains' => 'does not contain',
      'at_location' || 'at' => 'at',
      'not_at_location' => 'not at',
      _ => comp,
    };
  }

  String _calcLabel(String calc) {
    return switch (calc) {
      'sum' => 'total',
      'average' => 'average',
      'min' => 'lowest',
      'max' => 'highest',
      'count' => 'count',
      'mode' => 'most frequent',
      _ => calc,
    };
  }

  String _scopeLabel(String scope) {
    return switch (scope) {
      'most_recent' => 'most recent',
      'most_recent_period' => 'this $frequency',
      'last_n_entries' => 'last ${goal['entries_scope_count'] ?? '?'} entries',
      'last_n_time' => 'last ${goal['entries_scope_count'] ?? '?'} ${goal['entries_scope_unit'] ?? 'days'}',
      'all_time' => 'all time',
      _ => scope.replaceAll('_', ' '),
    };
  }
}

class _HistoryTab extends ConsumerStatefulWidget {
  final Activity activity;
  final String userId;

  const _HistoryTab({required this.activity, required this.userId});

  @override
  ConsumerState<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<_HistoryTab> {
  int _refreshKey = 0;

  void _refresh() => setState(() => _refreshKey++);

  Activity get activity => widget.activity;
  String get userId => widget.userId;
  bool get _hasSchedule => activity.schedule != null;

  @override
  Widget build(BuildContext context) {
    // Load entries
    final entriesFuture = ref.read(entryRepositoryProvider).getByActivityAndDateRange(
      userId, activity.id, DateTime(2020), DateTime.now().add(const Duration(days: 1)),
    );

    // Load period statuses if scheduled
    final statusesFuture = _hasSchedule
        ? ref.read(periodStatusRepositoryProvider).getActivityStatusHistory(userId, activity.id)
        : Future.value(<ActivityPeriodStatus>[]);

    return FutureBuilder(
      future: Future.wait([entriesFuture, statusesFuture]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final entries = (snapshot.data?[0] as List<Entry>?) ?? [];
        final statuses = (snapshot.data?[1] as List<ActivityPeriodStatus>?) ?? [];

        if (entries.isEmpty && statuses.isEmpty) {
          return _buildEmptyState();
        }

        if (_hasSchedule) {
          return _buildScheduledTimeline(context, entries, statuses);
        } else {
          return _buildEntryList(context, entries);
        }
      },
    );
  }

  // ─── Empty state ───
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KitabSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: KitabColors.gray300),
            const SizedBox(height: KitabSpacing.md),
            Text('No entries yet', style: KitabTypography.h3),
            const SizedBox(height: KitabSpacing.sm),
            Text(
              'Your history will appear here once you start logging.',
              style: KitabTypography.body.copyWith(color: KitabColors.gray500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Unscheduled: simple entry list ───
  Widget _buildEntryList(BuildContext context, List<Entry> entries) {
    final sorted = [...entries]..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

    return ListView.builder(
      padding: const EdgeInsets.all(KitabSpacing.lg),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final entry = sorted[index];
        return _EntryTile(entry: entry, activity: activity, fmt: ref.watch(dateFormatterProvider));
      },
    );
  }

  // ─── Scheduled: timeline with period statuses + entries ───
  Widget _buildScheduledTimeline(
      BuildContext context, List<Entry> entries, List<ActivityPeriodStatus> statuses) {
    // Build a map of period start → entries
    final entryByPeriod = <DateTime, List<Entry>>{};
    for (final e in entries) {
      final key = e.periodStart ?? e.loggedAt;
      entryByPeriod.putIfAbsent(key, () => []).add(e);
    }

    // Build timeline items: merge statuses and orphan entries
    final timelineItems = <_TimelineItem>[];

    // Add all period statuses
    for (final s in statuses) {
      final periodEntries = <Entry>[];
      // Find entries that match this period
      entryByPeriod.forEach((key, list) {
        for (final e in list) {
          if (e.periodStart != null &&
              e.periodStart == s.periodStart &&
              e.periodEnd == s.periodEnd) {
            periodEntries.add(e);
          }
        }
      });

      timelineItems.add(_TimelineItem(
        date: s.periodStart,
        periodEnd: s.periodEnd,
        status: s.status,
        entries: periodEntries,
        conditionId: s.conditionId,
      ));
    }

    // Add entries without a matching period status (orphan entries)
    for (final e in entries) {
      final hasStatus = timelineItems.any((item) => item.entries.contains(e));
      if (!hasStatus) {
        final existingItem = timelineItems.where((item) =>
            item.date.year == e.loggedAt.year &&
            item.date.month == e.loggedAt.month &&
            item.date.day == e.loggedAt.day).firstOrNull;
        if (existingItem != null) {
          existingItem.entries.add(e);
        } else {
          timelineItems.add(_TimelineItem(
            date: e.loggedAt,
            periodEnd: null,
            status: 'completed',
            entries: [e],
          ));
        }
      }
    }

    // Sort newest first
    timelineItems.sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      padding: const EdgeInsets.all(KitabSpacing.lg),
      itemCount: timelineItems.length,
      itemBuilder: (context, index) {
        final item = timelineItems[index];
        return _PeriodRow(item: item, activity: activity, onStatusChanged: _refresh);
      },
    );
  }
}

// ─── Timeline item model ───
class _TimelineItem {
  final DateTime date;
  final DateTime? periodEnd;
  String status;
  final List<Entry> entries;
  String? conditionId;

  _TimelineItem({
    required this.date,
    required this.periodEnd,
    required this.status,
    required this.entries,
    this.conditionId,
  });
}

// ─── Period row (for scheduled activities) ───
class _PeriodRow extends ConsumerWidget {
  final _TimelineItem item;
  final Activity activity;
  final VoidCallback? onStatusChanged;

  const _PeriodRow({required this.item, required this.activity, this.onStatusChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (IconData icon, Color color, String label) = switch (item.status) {
      'completed' => (Icons.check_circle, KitabColors.success, 'Completed'),
      'missed' => (Icons.cancel, KitabColors.error, 'Missed'),
      'excused' => (Icons.remove_circle, KitabColors.gray400, 'Excused'),
      'pending' => (Icons.schedule, KitabColors.warning, 'Pending'),
      _ => (Icons.circle_outlined, KitabColors.gray400, item.status),
    };

    final fmt = ref.watch(dateFormatterProvider);
    final dateStr = fmt.shortDateWithDayName(item.date);
    final isToday = _isToday(item.date);

    return Card(
      margin: const EdgeInsets.only(bottom: KitabSpacing.sm),
      child: InkWell(
        borderRadius: KitabRadii.borderMd,
        onTap: () => _showStatusChangeSheet(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(KitabSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period header
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: KitabSpacing.sm),
                  Expanded(
                    child: Text(
                      isToday ? 'Today — $dateStr' : dateStr,
                      style: KitabTypography.body.copyWith(
                        fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(label,
                        style: KitabTypography.caption.copyWith(
                            color: color, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),

              // Excuse reason
              if (item.status == 'excused' && item.conditionId != null) ...[
                const SizedBox(height: KitabSpacing.xs),
                FutureBuilder(
                  future: ref.read(conditionRepositoryProvider).getByUser(
                    ref.read(currentUserIdProvider)),
                  builder: (context, snapshot) {
                    final conditions = snapshot.data ?? [];
                    final condition = conditions.where((c) => c.id == item.conditionId).firstOrNull;
                    if (condition == null) return const SizedBox.shrink();
                    return Row(
                      children: [
                        Text(condition.emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text('Reason: ${condition.label}',
                            style: KitabTypography.caption.copyWith(color: KitabColors.gray500)),
                      ],
                    );
                  },
                ),
              ],

              // Entries under this period
              if (item.entries.isNotEmpty) ...[
                const SizedBox(height: KitabSpacing.xs),
                const Divider(height: 1),
                ...item.entries.map((entry) => _EntryTile(entry: entry, activity: activity, compact: true, fmt: ref.watch(dateFormatterProvider))),
              ] else if (item.status == 'missed') ...[
                const SizedBox(height: KitabSpacing.xs),
                Text('No entries logged for this period.',
                    style: KitabTypography.caption.copyWith(color: KitabColors.gray400)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusChangeSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(KitabSpacing.md),
              child: Text('Change Status — ${ref.read(dateFormatterProvider).shortDateWithDayName(item.date)}',
                  style: KitabTypography.h3),
            ),
            if (item.status != 'pending')
              ListTile(
                leading: const Icon(Icons.schedule, color: KitabColors.warning),
                title: const Text('Set as Pending'),
                subtitle: const Text('Reset to unresolved'),
                onTap: () {
                  Navigator.pop(ctx);
                  _changeStatus(ref, 'pending', context);
                },
              ),
            if (item.status != 'missed')
              ListTile(
                leading: const Icon(Icons.cancel_outlined, color: KitabColors.error),
                title: const Text('Mark as Missed'),
                onTap: () {
                  Navigator.pop(ctx);
                  _changeStatus(ref, 'missed', context);
                },
              ),
            if (item.status != 'excused')
              ListTile(
                leading: const Icon(Icons.info_outline, color: KitabColors.gray500),
                title: const Text('Mark as Excused'),
                subtitle: const Text('With a reason'),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (!context.mounted) return;
                  await _changeStatusWithReason(ref, context);
                },
              ),
            if (item.entries.isNotEmpty && item.status == 'completed')
              ListTile(
                leading: const Icon(Icons.link_off, color: KitabColors.gray400),
                title: const Text('Unlink entries'),
                subtitle: const Text('Keep entries but remove period link'),
                onTap: () {
                  Navigator.pop(ctx);
                  // TODO: Unlink entries from this period
                },
              ),
            const SizedBox(height: KitabSpacing.md),
          ],
        ),
      ),
    );
  }

  Future<void> _changeStatus(WidgetRef ref, String newStatus, BuildContext context) async {
    final userId = ref.read(currentUserIdProvider);
    final now = DateTime.now();

    if (newStatus == 'pending') {
      // Delete the existing status record to reset to pending
      // For now, save with 'pending' status
      final status = ActivityPeriodStatus(
        id: const Uuid().v4(),
        userId: userId,
        activityId: activity.id,
        periodStart: item.date,
        periodEnd: item.periodEnd ?? item.date.add(const Duration(days: 1)),
        status: 'pending',
        createdAt: now,
        updatedAt: now,
      );
      await ref.read(periodStatusRepositoryProvider).saveActivityStatus(status);
    } else {
      final status = ActivityPeriodStatus(
        id: const Uuid().v4(),
        userId: userId,
        activityId: activity.id,
        periodStart: item.date,
        periodEnd: item.periodEnd ?? item.date.add(const Duration(days: 1)),
        status: newStatus,
        resolvedAt: newStatus == 'excused' ? now : null,
        createdAt: now,
        updatedAt: now,
      );
      await ref.read(periodStatusRepositoryProvider).saveActivityStatus(status);
    }

    if (context.mounted) {
      KitabToast.success(context, 'Status changed to $newStatus');
    }
    onStatusChanged?.call();
  }

  Future<void> _changeStatusWithReason(WidgetRef ref, BuildContext context) async {
    final userId = ref.read(currentUserIdProvider);
    final conditionRepo = ref.read(conditionRepositoryProvider);
    final activeConditions = await conditionRepo.getByUser(userId);
    final presets = await conditionRepo.getPresetsByUser(userId);
    final now = DateTime.now();
    final currentConditions = activeConditions.where((c) => c.endDate == null || c.endDate!.isAfter(now)).toList();

    if (!context.mounted) return;

    final result = await showModalBottomSheet<({String? conditionId, String label})>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: KitabSpacing.lg, right: KitabSpacing.lg, top: KitabSpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + KitabSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: KitabColors.gray300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: KitabSpacing.lg),
              Text('Select a Reason', style: KitabTypography.h3),
              const SizedBox(height: KitabSpacing.md),

              if (currentConditions.isNotEmpty) ...[
                Text('Active Conditions', style: KitabTypography.bodySmall.copyWith(
                    color: KitabColors.gray600, fontWeight: FontWeight.w600)),
                const SizedBox(height: KitabSpacing.xs),
                ...currentConditions.map((c) => ListTile(
                  leading: Text(c.emoji, style: const TextStyle(fontSize: 20)),
                  title: Text(c.label),
                  dense: true,
                  onTap: () => Navigator.pop(ctx, (conditionId: c.id, label: '${c.emoji} ${c.label}')),
                )),
                const Divider(),
              ],

              if (presets.isNotEmpty) ...[
                Text('From Presets', style: KitabTypography.bodySmall.copyWith(
                    color: KitabColors.gray600, fontWeight: FontWeight.w600)),
                const SizedBox(height: KitabSpacing.xs),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: presets.map((p) => ActionChip(
                    avatar: Text(p.emoji, style: const TextStyle(fontSize: 14)),
                    label: Text(p.label),
                    onPressed: () async {
                      // Create a condition from the preset
                      final conditionId = await createOrExtendCondition(
                        repo: conditionRepo,
                        userId: userId,
                        presetId: p.id,
                        label: p.label,
                        emoji: p.emoji,
                        startDate: item.date,
                        endDate: item.periodEnd ?? item.date,
                      );
                      if (ctx.mounted) Navigator.pop(ctx, (conditionId: conditionId, label: '${p.emoji} ${p.label}'));
                    },
                  )).toList(),
                ),
              ],
              const SizedBox(height: KitabSpacing.md),
            ],
          ),
        ),
      ),
    );

    if (result == null) return;

    final status = ActivityPeriodStatus(
      id: const Uuid().v4(),
      userId: userId,
      activityId: activity.id,
      periodStart: item.date,
      periodEnd: item.periodEnd ?? item.date.add(const Duration(days: 1)),
      status: 'excused',
      conditionId: result.conditionId,
      resolvedAt: now,
      createdAt: now,
      updatedAt: now,
    );
    await ref.read(periodStatusRepositoryProvider).saveActivityStatus(status);

    if (context.mounted) {
      KitabToast.success(context, 'Period excused: ${result.label}');
    }
    onStatusChanged?.call();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

// ─── Entry tile (used by both scheduled and unscheduled) ───
class _EntryTile extends StatelessWidget {
  final Entry entry;
  final Activity activity;
  final bool compact;
  final KitabDateFormat fmt;

  const _EntryTile({required this.entry, required this.activity, this.compact = false, required this.fmt});

  @override
  Widget build(BuildContext context) {
    // Prefer start_time field, fallback to loggedAt
    DateTime displayTime = entry.loggedAt;
    final rawStartTime = entry.fieldValues['start_time'];
    if (rawStartTime is String) {
      final parsed = DateTime.tryParse(rawStartTime);
      if (parsed != null) displayTime = parsed.toLocal();
    }
    final timeStr = fmt.time(displayTime);
    final fieldSummary = _buildFieldSummary();

    return ListTile(
      contentPadding: compact ? const EdgeInsets.symmetric(horizontal: 4) : null,
      dense: compact,
      leading: compact
          ? null
          : const Icon(Icons.article_outlined, color: KitabColors.gray400, size: 20),
      title: Text(
        compact ? timeStr : fmt.shortDateWithTime(displayTime),
        style: compact ? KitabTypography.bodySmall : KitabTypography.body,
      ),
      subtitle: fieldSummary != null || entry.notes != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fieldSummary != null)
                  Text(fieldSummary,
                      style: KitabTypography.caption.copyWith(color: KitabColors.gray500),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                if (entry.notes != null)
                  Text(entry.notes!,
                      style: KitabTypography.caption.copyWith(
                          color: KitabColors.gray400, fontStyle: FontStyle.italic),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: KitabColors.gray400, size: 18),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EntryFormScreen(existingEntry: entry)),
      ),
    );
  }

  /// Build a compact summary of field values like "Start: 5:15 AM · Duration: 12 min"
  String? _buildFieldSummary() {
    if (entry.fieldValues.isEmpty) return null;

    // Parse field definitions from activity template
    final fieldDefs = activity.fields;
    if (fieldDefs.isEmpty) return null;

    final parts = <String>[];
    for (final fieldDef in fieldDefs) {
      final fieldId = fieldDef['id'] as String?;
      if (fieldId == null) continue;

      final value = entry.fieldValues[fieldId];
      if (value == null) continue;

      final label = fieldDef['label'] as String? ?? 'Field';
      final type = fieldDef['type'] as String? ?? 'text';

      final formatted = _formatFieldValue(type, value);
      if (formatted != null) {
        parts.add('$label: $formatted');
      }
    }

    return parts.isEmpty ? null : parts.join(' · ');
  }

  String? _formatFieldValue(String type, dynamic value) {
    switch (type) {
      case 'start_time':
      case 'end_time':
        if (value is String) return value;
        return value?.toString();
      case 'duration':
        if (value is num) {
          final mins = value.toInt();
          if (mins >= 60) return '${mins ~/ 60}h ${mins % 60}m';
          return '${mins}m';
        }
        return value?.toString();
      case 'number':
      case 'range':
        if (value is num) {
          return value == value.roundToDouble()
              ? value.toInt().toString()
              : value.toStringAsFixed(1);
        }
        return value?.toString();
      case 'star_rating':
        if (value is num) return '${'★' * value.toInt()}${'☆' * (5 - value.toInt())}';
        return value?.toString();
      case 'mood':
        if (value is num) {
          return switch (value.toInt()) {
            1 => '😢',
            2 => '😟',
            3 => '😐',
            4 => '😊',
            5 => '😄',
            _ => value.toString(),
          };
        }
        return value?.toString();
      case 'yes_no':
        if (value is bool) return value ? 'Yes' : 'No';
        return value?.toString();
      case 'single_choice':
      case 'text':
        return value?.toString();
      case 'multiple_choice':
      case 'list':
        if (value is List) return value.join(', ');
        return value?.toString();
      case 'location':
        if (value is Map) return value['name'] as String? ?? 'Location set';
        return null;
      default:
        return value?.toString();
    }
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final Widget child;

  const _StatColumn({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        child,
        const SizedBox(height: 4),
        Text(label,
            style: KitabTypography.caption
                .copyWith(color: KitabColors.gray500)),
      ],
    );
  }
}
