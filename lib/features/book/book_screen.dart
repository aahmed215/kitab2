// ═══════════════════════════════════════════════════════════════════
// BOOK_SCREEN.DART — Chronological Entry Timeline ("Book of Deeds")
// Complete record of entries and conditions, grouped by date.
// Filter row, sticky headers, long-press menus, master-detail.
// See SPEC.md §14.3 for full specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/database_providers.dart';
import '../../core/engines/engines.dart';
import '../../core/theme/kitab_theme.dart';
import '../../core/widgets/kitab_card.dart';
import '../../data/models/entry.dart';
import '../../data/models/category.dart' as domain;
import '../../data/models/activity.dart';
import '../../data/models/condition.dart';
import '../../core/utils/provider_refresh.dart';
import '../../core/widgets/kitab_toast.dart';
import '../entry/entry_form_screen.dart';
import '../home/providers/home_providers.dart';

// ═══════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════

/// All entries (most recent first).
final bookEntriesProvider = StreamProvider<List<Entry>>((ref) {
  return ref.watch(entryRepositoryProvider).watchByUser(ref.watch(currentUserIdProvider));
});

/// All activities (for name/category lookup).
final bookActivitiesProvider = FutureProvider<Map<String, Activity>>((ref) async {
  final activities = await ref.watch(activityRepositoryProvider).getByUser(ref.watch(currentUserIdProvider));
  return {for (final a in activities) a.id: a};
});

/// All categories (for color lookup).
final bookCategoriesProvider = StreamProvider<Map<String, domain.Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchByUser(ref.watch(currentUserIdProvider)).map(
    (categories) => {for (final c in categories) c.id: c},
  );
});

/// All conditions (for day headers and condition filter).
final bookConditionsProvider = FutureProvider<List<Condition>>((ref) async {
  return ref.watch(conditionRepositoryProvider).getByUser(ref.watch(currentUserIdProvider));
});

// ═══════════════════════════════════════════════════════════════════
// BOOK SCREEN
// ═══════════════════════════════════════════════════════════════════

class BookScreen extends ConsumerStatefulWidget {
  const BookScreen({super.key});

  @override
  ConsumerState<BookScreen> createState() => BookScreenState();
}

class BookScreenState extends ConsumerState<BookScreen> {
  // Filter state
  bool _showSearch = false;
  String _searchQuery = '';
  Set<String> _selectedCategoryIds = {};
  Set<String> _selectedGoalStatuses = {};
  bool _showConditions = false;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showTodayPill = false;

  // Master-detail (desktop)
  Entry? _selectedEntry;
  Condition? _selectedCondition;
  _MergedCondition? _selectedMergedGroup;
  bool _entryFormDirty = false;
  bool _conditionDirty = false;

  /// Check if there are unsaved changes in the embedded entry form.
  bool get hasDirtyForm => _entryFormDirty;

  /// Discard unsaved changes and deselect entry.
  void discardChanges() {
    setState(() {
      _selectedEntry = null;
      _entryFormDirty = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final shouldShow = _scrollController.offset > 400;
      if (shouldShow != _showTodayPill) setState(() => _showTodayPill = shouldShow);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(bookEntriesProvider);
    final activitiesAsync = ref.watch(bookActivitiesProvider);
    final categoriesAsync = ref.watch(bookCategoriesProvider);
    final isDesktop = MediaQuery.of(context).size.width > 1024;

    final activities = activitiesAsync.valueOrNull ?? {};
    final categories = categoriesAsync.valueOrNull ?? {};
    List<Condition> conditions;
    try {
      final conditionsAsync = ref.watch(bookConditionsProvider);
      conditions = conditionsAsync.valueOrNull ?? [];
    } catch (_) {
      conditions = [];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Book', style: KitabTypography.h1),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Entry',
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const EntryFormScreen()));
              ref.invalidate(bookEntriesProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Filter Row ───
          _FilterRow(
            showSearch: _showSearch,
            searchQuery: _searchQuery,
            selectedCategoryIds: _selectedCategoryIds,
            selectedGoalStatuses: _selectedGoalStatuses,
            showConditions: _showConditions,
            categories: categories,
            onSearchToggle: () => setState(() => _showSearch = !_showSearch),
            onCategoryFilter: () => _showCategoryFilter(categories),
            onGoalStatusFilter: _showGoalStatusFilter,
            onConditionsToggle: () => setState(() => _showConditions = !_showConditions),
            onDateJump: () => _showDatePicker(),
            onAdvancedFilters: () => _showAdvancedFilters(activities, categories),
            onClear: () => setState(() {
              _selectedCategoryIds = {};
              _selectedGoalStatuses = {};
              _searchQuery = '';
              _searchController.clear();
              _showSearch = false;
              _showConditions = false;
            }),
            hasActiveFilters: _selectedCategoryIds.isNotEmpty ||
                _selectedGoalStatuses.isNotEmpty ||
                _searchQuery.isNotEmpty ||
                _showConditions,
          ),

          // ─── Search bar ───
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: KitabSpacing.lg, vertical: KitabSpacing.xs),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or notes...',
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                        )
                      : null,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),

          // ─── Content ───
          Expanded(
            child: isDesktop
                ? _buildMasterDetail(entriesAsync, activities, categories, conditions)
                : _buildTimeline(entriesAsync, activities, categories, conditions),
          ),
        ],
      ),

      // ─── "Today ↑" pill ───
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _showTodayPill
          ? Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: FloatingActionButton.extended(
                heroTag: 'today_pill',
                onPressed: () => _scrollController.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut),
                backgroundColor: KitabColors.primary,
                icon: const Icon(Icons.arrow_upward, size: 16, color: Colors.white),
                label: const Text('Today', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 4,
              ),
            )
          : null,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TIMELINE (single column — phone)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTimeline(
    AsyncValue<List<Entry>> entriesAsync,
    Map<String, Activity> activities,
    Map<String, domain.Category> categories,
    List<Condition> conditions,
  ) {
    final fmt = ref.watch(dateFormatterProvider);
    return entriesAsync.when(
      data: (entries) {
        if (_showConditions) return _buildConditionsView(conditions);
        if (entries.isEmpty && conditions.isEmpty) return _buildEmptyState();

        final filtered = _applyFilters(entries, activities);
        if (filtered.isEmpty) {
          return Center(
            child: Text('No entries match your filters',
                style: KitabTypography.body.copyWith(color: KitabColors.gray400)),
          );
        }

        var grouped = _groupByDate(filtered);

        // Add days with active conditions that have no entries
        if (conditions.isNotEmpty) {
          final existingDays = grouped.map((g) =>
            '${g.date.year}-${g.date.month}-${g.date.day}'
          ).toSet();

          final now = DateTime.now();
          // Check last 30 days for condition-only days
          for (var i = 0; i < 30; i++) {
            final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
            final dayKey = '${day.year}-${day.month}-${day.day}';
            if (existingDays.contains(dayKey)) continue;

            final dayConditions = _conditionsForDate(conditions, day);
            if (dayConditions.isNotEmpty) {
              grouped.add(_DateGroup(date: day, entries: []));
              existingDays.add(dayKey);
            }
          }

          // Re-sort by date descending
          grouped.sort((a, b) => b.date.compareTo(a.date));
        }

        // Pre-compute merged condition chains (same logic as condition card
        // view) so day headers use a single source of truth.
        final mergedChains = _mergeConditionsForDisplay(conditions);

        return CustomScrollView(
          key: const ValueKey('book_timeline'),
          controller: _scrollController,
          slivers: [
            const SliverPadding(padding: EdgeInsets.only(top: KitabSpacing.lg)),
            for (var index = 0; index < grouped.length; index++) ...[
              // Sticky day header
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyDayHeaderDelegate(
                  child: _DaySeparator(
                    date: grouped[index].date,
                    mergedChains: mergedChains,
                    fmt: fmt,
                  ),
                ),
              ),
              // Entry cards for this day
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: KitabSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: KitabSpacing.sm),
                    ...grouped[index].entries.map((entry) => _buildEntryCard(entry, activities, categories, entries)),
                    if (grouped[index].entries.isEmpty && _conditionsForDate(conditions, grouped[index].date).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: KitabSpacing.sm),
                        child: Text('No entries — condition active',
                            style: KitabTypography.caption.copyWith(color: KitabColors.gray400)),
                      ),
                    const SizedBox(height: KitabSpacing.md),
                  ]),
                ),
              ),
            ],
            const SliverPadding(padding: EdgeInsets.only(bottom: KitabSpacing.lg)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MASTER-DETAIL (desktop — timeline left, detail right)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildMasterDetail(
    AsyncValue<List<Entry>> entriesAsync,
    Map<String, Activity> activities,
    Map<String, domain.Category> categories,
    List<Condition> conditions,
  ) {
    return Row(
      children: [
        // Timeline (40%)
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.4,
          child: _buildTimeline(entriesAsync, activities, categories, conditions),
        ),
        const VerticalDivider(width: 1),
        // Detail (60%)
        Expanded(
          child: _selectedEntry != null
              ? EntryFormScreen(
                  key: ValueKey('entry_${_selectedEntry!.id}'),
                  existingEntry: _selectedEntry,
                  preselectedActivity: _selectedEntry!.activityId != null
                      ? activities[_selectedEntry!.activityId]
                      : null,
                  embedded: true,
                  onSaved: () {
                    setState(() => _entryFormDirty = false);
                    ref.invalidate(bookEntriesProvider);
                  },
                  onDeleted: () {
                    setState(() { _selectedEntry = null; _entryFormDirty = false; });
                    ref.invalidate(bookEntriesProvider);
                  },
                  onDirtyChanged: (dirty) {
                    _entryFormDirty = dirty;
                  },
                )
              : _selectedCondition != null
                  ? _ConditionDetailPanel(
                      key: ValueKey('cond_${_selectedCondition!.id}'),
                      condition: _selectedCondition!,
                      mergedStartDate: _selectedMergedGroup?.startDate,
                      mergedEndDate: _selectedMergedGroup?.endDate,
                      mergedConditionIds: _selectedMergedGroup?.conditionIds,
                      onDirtyChanged: (dirty) {
                        _conditionDirty = dirty;
                      },
                      onChanged: () {
                        ref.invalidate(bookConditionsProvider);
                        ref.invalidate(activeConditionsProvider);
                        setState(() { _selectedCondition = null; _selectedMergedGroup = null; _conditionDirty = false; });
                      },
                    )
                  : Center(
                      child: Text('Select an entry or condition to view details',
                          style: KitabTypography.body.copyWith(color: KitabColors.gray400)),
                    ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ENTRY CARD (SPEC-compliant two-column layout)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildEntryCard(Entry entry, Map<String, Activity> activities, Map<String, domain.Category> categories, List<Entry> allEntries) {
    final activity = entry.activityId != null ? activities[entry.activityId] : null;
    final category = activity != null ? categories[activity.categoryId] : null;
    final borderColor = category != null ? _parseColor(category.color) : KitabColors.gray400;
    final isPrivate = activity?.isPrivate == true;
    final isSelected = _selectedEntry?.id == entry.id;

    // Time display — parse ISO or formatted times to short local time
    final rawStart = entry.fieldValues['start_time'];
    final rawEnd = entry.fieldValues['end_time'];
    final durationMins = entry.fieldValues['duration_minutes'];
    final durationSecs = entry.fieldValues['duration_seconds'];

    String timeStr;
    final fmt = ref.watch(dateFormatterProvider);
    final startFormatted = _parseTimeDisplay(rawStart, fmt);
    final endFormatted = _parseTimeDisplay(rawEnd, fmt);
    if (startFormatted != null && endFormatted != null) {
      timeStr = '$startFormatted – $endFormatted';
    } else if (startFormatted != null) {
      timeStr = startFormatted;
    } else {
      timeStr = fmt.time(entry.loggedAt);
    }

    String? durationStr;
    if (durationSecs is int && durationSecs > 0) {
      final d = Duration(seconds: durationSecs);
      if (d.inHours > 0) {
        final mins = d.inMinutes.remainder(60);
        durationStr = mins > 0 ? '${d.inHours}h ${mins}m' : '${d.inHours}h';
      } else if (d.inMinutes > 0) {
        durationStr = '${d.inMinutes}m';
      } else {
        durationStr = '${d.inSeconds}s';
      }
    } else if (durationMins is int && durationMins > 0) {
      durationStr = durationMins >= 60
          ? '${durationMins ~/ 60}h ${durationMins % 60}m'
          : '${durationMins}m';
    }

    // Evaluate the PRIMARY goal for this entry's period.
    // Three states: met (✓), not_met (✕), in_progress (○).
    String? goalStatus; // 'met' | 'not_met' | 'in_progress' | null
    String? goalProgressText;
    if (activity?.goals != null) {
      // Determine the period boundaries:
      //   1. Use the entry's saved periodStart/periodEnd if present, OR
      //   2. Compute from the activity's schedule using the entry's loggedAt date
      ComputedPeriod? period;
      if (entry.periodStart != null && entry.periodEnd != null) {
        period = ComputedPeriod(start: entry.periodStart!, end: entry.periodEnd!);
      } else if (activity!.schedule != null) {
        // Use the entry's start_time field as the primary timestamp,
        // falling back to loggedAt if no start_time is recorded.
        final referenceTime = _entryReferenceTime(entry);
        final periods = const PeriodEngine().computePeriodsForDate(
          scheduleJson: activity.schedule,
          date: referenceTime,
        );
        // Pick the period that contains the reference time
        for (final p in periods) {
          if (!referenceTime.isBefore(p.start) && referenceTime.isBefore(p.end)) {
            period = p;
            break;
          }
        }
        // Fallback to the first period for that day if no exact match
        period ??= periods.isEmpty ? null : periods.first;
      }

      if (period != null) {
        // Find all entries that belong to this period.
        // Two strategies:
        //   - Entry HAS periodStart/End → strict match on both boundaries
        //   - Entry has NO periodStart  → check reference time inside period
        // Always include the entry we're evaluating (safety net for entries
        // whose own periodStart drifted slightly from the computed period).
        final periodEntries = allEntries.where((e) {
          if (e.activityId != activity!.id) return false;
          if (e.id == entry.id) return true;
          if (e.periodStart != null && e.periodEnd != null) {
            return e.periodStart!.isAtSameMomentAs(period!.start) &&
                   e.periodEnd!.isAtSameMomentAs(period.end);
          }
          final ref = _entryReferenceTime(e);
          return !ref.isBefore(period!.start) && ref.isBefore(period.end);
        }).map((e) => GoalEntry(
          id: e.id,
          loggedAt: e.loggedAt,
          fieldValues: e.fieldValues,
          periodStart: e.periodStart,
          periodEnd: e.periodEnd,
        )).toList();

        // Period is "finalized" only after it has ended
        final isFinalized = period.end.isBefore(DateTime.now());

        var evals = const GoalEngine().evaluateGoals(
          goalsJson: activity!.goals,
          period: period,
          periodEntries: periodEntries,
          isFinalized: isFinalized,
        );

        // Fallback: if no goal version applies to this period (entry predates
        // all goal versions), retry with the latest version's goals so the
        // user still sees what the status WOULD be under current rules.
        if (evals.isEmpty && activity.goals != null) {
          final latestGoals = _extractLatestGoalsVersion(activity.goals!);
          if (latestGoals != null) {
            evals = const GoalEngine().evaluateGoals(
              goalsJson: latestGoals,
              period: period,
              periodEntries: periodEntries,
              isFinalized: isFinalized,
            );
          }
        }

        // Find the PRIMARY goal evaluation by matching activity.primaryGoalId.
        // Falls back to first eval if primaryGoalId is null or no match.
        GoalEvaluation? primary;
        final primaryId = activity.primaryGoalId;
        if (primaryId != null) {
          for (final e in evals) {
            if (e.goalId == primaryId) {
              primary = e;
              break;
            }
          }
        }
        primary ??= evals.isEmpty ? null : evals.first;

        if (primary != null) {
          goalStatus = primary.status;
          goalProgressText = primary.progressText;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: KitabSpacing.sm),
      child: Dismissible(
        key: ValueKey(entry.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(color: KitabColors.error, borderRadius: KitabRadii.borderMd),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (_) async {
          return await _confirmDelete(entry.id);
        },
        child: Container(
          decoration: isSelected ? BoxDecoration(
            borderRadius: KitabRadii.borderMd,
            color: KitabColors.primary.withValues(alpha: 0.06),
            border: Border.all(color: KitabColors.primary.withValues(alpha: 0.4), width: 1.5),
          ) : null,
          child: KitabCard(
          borderColor: borderColor,
          onTap: () {
            final isDesktop = MediaQuery.of(context).size.width > 1024;
            if (isDesktop) {
              final isDirty = _entryFormDirty || _conditionDirty;
              if (isDirty && _selectedEntry?.id != entry.id) {
                _promptDiscardAndSwitch(entry);
              } else {
                setState(() { _selectedEntry = entry; _selectedCondition = null; _selectedMergedGroup = null; _entryFormDirty = false; _conditionDirty = false; });
                ref.invalidate(bookEntriesProvider);
              }
            } else {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => EntryFormScreen(existingEntry: entry, preselectedActivity: activity),
              )).then((_) => ref.invalidate(bookEntriesProvider));
            }
          },
          onLongPress: () => _showEntryMenu(entry, activity),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Left side: name + category ───
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Line 1: Activity name
                    Text(
                      isPrivate ? '••••••••' : entry.name,
                      style: KitabTypography.body.copyWith(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Line 2: Category icon + name, OR "Not linked" hint for freeform entries
                    if (category != null)
                      Row(
                        children: [
                          Text(category.icon, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              category.name,
                              style: KitabTypography.caption.copyWith(color: KitabColors.gray500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Unlinked period warning (has template but no period link)
                          if (activity?.schedule != null && entry.periodStart == null) ...[
                            const SizedBox(width: 4),
                            Tooltip(
                              message: "This entry isn't linked to a scheduled period. Tap to link it.",
                              child: Icon(Icons.info_outline, size: 14, color: KitabColors.warning),
                            ),
                          ],
                        ],
                      )
                    else
                      // Fully unlinked entry (no activity template)
                      Row(
                        children: [
                          Tooltip(
                            message: "This entry isn't linked to any activity. Tap to add a category or link it to a template.",
                            child: Icon(Icons.info_outline, size: 14, color: KitabColors.warning),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Not linked',
                            style: KitabTypography.caption.copyWith(color: KitabColors.gray400),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(width: KitabSpacing.sm),

              // ─── Right side: time + goal status + duration + progress ───
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Line 1: Time + goal status icon
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(timeStr, style: KitabTypography.caption.copyWith(color: KitabColors.gray500)),
                      if (goalStatus != null) ...[
                        const SizedBox(width: 4),
                        _GoalStatusIcon(status: goalStatus),
                      ],
                    ],
                  ),
                  // Line 2: Duration + goal progress
                  if (durationStr != null || goalProgressText != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (durationStr != null)
                          Text(durationStr, style: KitabTypography.caption.copyWith(color: KitabColors.gray400)),
                        if (durationStr != null && goalProgressText != null)
                          const SizedBox(width: 6),
                        if (goalProgressText != null)
                          Text(goalProgressText, style: KitabTypography.monoSmall.copyWith(color: KitabColors.gray500)),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CONDITIONS VIEW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildConditionsView(List<Condition> conditions) {
    if (conditions.isEmpty) {
      return Center(
        child: Text('No conditions recorded', style: KitabTypography.body.copyWith(color: KitabColors.gray400)),
      );
    }

    // Merge consecutive same-preset conditions into visual groups
    final merged = _mergeConditionsForDisplay(conditions);

    return ListView.builder(
      padding: const EdgeInsets.all(KitabSpacing.lg),
      itemCount: merged.length,
      itemBuilder: (_, index) {
        final group = merged[index];
        final isActive = group.endDate == null;
        final days = isActive
            ? DateTime.now().difference(group.startDate).inDays + 1
            : group.endDate!.difference(group.startDate).inDays + 1;
        final fmt = ref.watch(dateFormatterProvider);
        final dateRange = isActive
            ? '${fmt.fullDate(group.startDate)} – Present'
            : group.startDate == group.endDate
                ? fmt.fullDate(group.startDate)
                : '${fmt.fullDate(group.startDate)} – ${fmt.fullDate(group.endDate!)}';

        final isSelected = group.conditionIds.contains(_selectedCondition?.id);

        return Padding(
          padding: const EdgeInsets.only(bottom: KitabSpacing.sm),
          child: Container(
            decoration: isSelected ? BoxDecoration(
              borderRadius: KitabRadii.borderMd,
              border: Border.all(color: KitabColors.primary, width: 2),
            ) : null,
            child: KitabCard(
            onTap: () {
              // Use the first condition in the group for editing
              final primaryCond = conditions.where((c) => c.id == group.conditionIds.first).firstOrNull;
              if (primaryCond == null) return;
              final isDesktop = MediaQuery.of(context).size.width > 1024;
              if (isDesktop) {
                final hasDirty = _entryFormDirty || _conditionDirty;
                if (hasDirty && _selectedCondition?.id != primaryCond.id) {
                  _promptDiscardAndSwitchCondition(primaryCond, group);
                } else {
                  setState(() { _selectedCondition = primaryCond; _selectedMergedGroup = group; _selectedEntry = null; _conditionDirty = false; });
                }
              } else {
                _showConditionEditSheet(context, primaryCond, group);
              }
            },
            child: Row(
              children: [
                Text(group.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: KitabSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.label, style: KitabTypography.body.copyWith(fontWeight: FontWeight.w500)),
                      Text('$dateRange  ·  $days ${days == 1 ? 'day' : 'days'}',
                          style: KitabTypography.caption.copyWith(color: KitabColors.gray500)),
                    ],
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: KitabColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Active', style: KitabTypography.caption.copyWith(
                      color: KitabColors.success, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

  /// Merge consecutive same-preset conditions into visual groups.
  List<_MergedCondition> _mergeConditionsForDisplay(List<Condition> conditions) {
    if (conditions.isEmpty) return [];

    final sorted = [...conditions]..sort((a, b) => a.startDate.compareTo(b.startDate));
    final merged = <_MergedCondition>[];

    for (final cond in sorted) {
      // Try to merge with the last group if same preset and adjacent/overlapping
      if (merged.isNotEmpty) {
        final last = merged.last;
        if (last.presetId == cond.presetId) {
          final lastEnd = last.endDate ?? DateTime(2099, 12, 31);
          final lastEndDay = DateTime(lastEnd.year, lastEnd.month, lastEnd.day);
          final condStartDay = DateTime(cond.startDate.year, cond.startDate.month, cond.startDate.day);

          // Adjacent: lastEnd + 1 day >= condStart, or overlapping
          final nextDayAfterEnd = lastEndDay.add(const Duration(days: 1));
          if (nextDayAfterEnd.isBefore(condStartDay)) {
            // Gap between conditions — not adjacent, create new group
          } else {
            // Merge: extend end date
            final condEnd = cond.endDate;
            if (condEnd == null) {
              last.endDate = null; // Now active
            } else if (last.endDate != null && condEnd.isAfter(last.endDate!)) {
              last.endDate = condEnd;
            }
            last.conditionIds.add(cond.id);
            continue;
          }
        }
      }

      // Start new group
      merged.add(_MergedCondition(
        label: cond.label,
        emoji: cond.emoji,
        presetId: cond.presetId,
        startDate: cond.startDate,
        endDate: cond.endDate,
        conditionIds: [cond.id],
      ));
    }

    // Sort newest first
    merged.sort((a, b) => b.startDate.compareTo(a.startDate));
    return merged;
  }

  void _showConditionEditSheet(BuildContext context, Condition cond, [_MergedCondition? group]) {
    final fmt = ref.watch(dateFormatterProvider);
    // Prefer merged group boundaries so multi-day conditions edit as one unit
    var startDate = group?.startDate ?? cond.startDate;
    var endDate = (group?.endDate ?? cond.endDate) ?? DateTime.now();
    final isActive = (group?.endDate ?? cond.endDate) == null;
    final idsToAffect = group?.conditionIds ?? [cond.id];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(KitabSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(cond.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: KitabSpacing.sm),
                    Expanded(child: Text(cond.label, style: KitabTypography.h3)),
                  ],
                ),
                const SizedBox(height: KitabSpacing.md),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.calendar_today, size: 18),
                  title: const Text('Start Date'),
                  subtitle: Text(fmt.shortDateWithDay(startDate)),
                  trailing: const Icon(Icons.edit, size: 16, color: KitabColors.gray400),
                  onTap: () async {
                    final picked = await showDatePicker(context: ctx, initialDate: startDate,
                        firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (picked != null) setSheetState(() => startDate = picked);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.event_available, size: 18),
                  title: Text(isActive ? 'End Date (set to end condition)' : 'End Date'),
                  subtitle: Text(isActive ? 'Active — no end date' : fmt.shortDateWithDay(endDate)),
                  trailing: const Icon(Icons.edit, size: 16, color: KitabColors.gray400),
                  onTap: () async {
                    final picked = await showDatePicker(context: ctx, initialDate: endDate,
                        firstDate: startDate, lastDate: DateTime.now());
                    if (picked != null) setSheetState(() => endDate = picked);
                  },
                ),
                const SizedBox(height: KitabSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final repo = ref.read(conditionRepositoryProvider);
                          if (startDate != cond.startDate) {
                            await repo.saveCondition(cond.copyWith(startDate: startDate));
                          }
                          if (endDate != ((group?.endDate) ?? cond.endDate)) {
                            // End all condition records in the merged group
                            for (final id in idsToAffect) {
                              await repo.endCondition(id, endDate);
                              await ref.read(periodStatusRepositoryProvider).clearExcusesOutsideRange(
                                id, startDate, endDate,
                              );
                            }
                          }
                          ref.invalidate(bookConditionsProvider);
                          ref.invalidate(activeConditionsProvider);
                          refreshAllEntryProviders(ref);
                        },
                        child: Text(isActive ? 'End Condition' : 'Save Changes'),
                      ),
                    ),
                    const SizedBox(width: KitabSpacing.sm),
                    OutlinedButton(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: ctx,
                          builder: (d) => AlertDialog(
                            title: const Text('Delete Condition?'),
                            content: const Text('Activities excused with this condition will become unexcused.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
                              FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: KitabColors.error),
                                onPressed: () => Navigator.pop(d, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          final condRepo = ref.read(conditionRepositoryProvider);
                          final statusRepo = ref.read(periodStatusRepositoryProvider);
                          // Delete all condition records in the merged group
                          for (final id in idsToAffect) {
                            await condRepo.deleteCondition(id);
                            await statusRepo.clearExcusesByConditionId(id);
                          }
                          ref.invalidate(bookConditionsProvider);
                          ref.invalidate(activeConditionsProvider);
                          refreshAllEntryProviders(ref);
                        }
                      },
                      style: OutlinedButton.styleFrom(foregroundColor: KitabColors.error,
                          side: const BorderSide(color: KitabColors.error)),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KitabSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_stories, size: 64, color: KitabColors.gray300),
            const SizedBox(height: KitabSpacing.lg),
            Text('Every journey starts with\na single entry.',
                style: KitabTypography.h3, textAlign: TextAlign.center),
            const SizedBox(height: KitabSpacing.sm),
            Text('Start writing your Kitab.',
                style: KitabTypography.body.copyWith(color: KitabColors.gray500)),
            const SizedBox(height: KitabSpacing.lg),
            FilledButton.icon(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const EntryFormScreen()));
                ref.invalidate(bookEntriesProvider);
              },
              icon: const Icon(Icons.add),
              label: const Text('Log Your First Entry'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // LONG-PRESS MENU (Duplicate, Edit, Delete)
  // ═══════════════════════════════════════════════════════════════

  void _showEntryMenu(Entry entry, Activity? activity) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(KitabSpacing.md),
              child: Text(entry.name, style: KitabTypography.h3),
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: KitabColors.primary),
              title: const Text('Duplicate'),
              subtitle: const Text('Create a copy with current time'),
              onTap: () {
                Navigator.pop(ctx);
                _duplicateEntry(entry, activity);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: KitabColors.primary),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => EntryFormScreen(existingEntry: entry, preselectedActivity: activity),
                )).then((_) => ref.invalidate(bookEntriesProvider));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: KitabColors.error),
              title: const Text('Delete'),
              onTap: () async {
                Navigator.pop(ctx);
                await _confirmDelete(entry.id);
              },
            ),
            const SizedBox(height: KitabSpacing.md),
          ],
        ),
      ),
    );
  }

  void _duplicateEntry(Entry entry, Activity? activity) async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => EntryFormScreen(
        preselectedActivity: activity,
        // Passing null for existingEntry creates a new entry with preselected activity
      ),
    ));
    ref.invalidate(bookEntriesProvider);
  }

  Future<bool> _confirmDelete(String entryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: KitabColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(entryRepositoryProvider).delete(entryId);
      // Clear selected entry if it was the deleted one
      if (_selectedEntry?.id == entryId) {
        setState(() => _selectedEntry = null);
      }
      refreshAllEntryProviders(ref);
      return true;
    }
    return false;
  }

  // ═══════════════════════════════════════════════════════════════
  // FILTERS
  // ═══════════════════════════════════════════════════════════════

  void _promptDiscardAndSwitch(Entry newEntry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard unsaved changes?'),
        content: const Text('You have unsaved changes that haven\'t been saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() { _selectedEntry = newEntry; _selectedCondition = null; _selectedMergedGroup = null; _entryFormDirty = false; _conditionDirty = false; });
              ref.invalidate(bookEntriesProvider);
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  void _promptDiscardAndSwitchCondition(Condition newCondition, _MergedCondition group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard unsaved changes?'),
        content: const Text('You have unsaved changes that haven\'t been saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() { _selectedCondition = newCondition; _selectedMergedGroup = group; _selectedEntry = null; _entryFormDirty = false; _conditionDirty = false; });
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  List<Entry> _applyFilters(List<Entry> entries, Map<String, Activity> activities) {
    return entries.where((e) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!e.name.toLowerCase().contains(q) && !(e.notes?.toLowerCase().contains(q) ?? false)) return false;
      }
      if (_selectedCategoryIds.isNotEmpty && e.activityId != null) {
        final activity = activities[e.activityId];
        if (activity == null || !_selectedCategoryIds.contains(activity.categoryId)) return false;
      }
      return true;
    }).toList();
  }

  List<Condition> _conditionsForDate(List<Condition> conditions, DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return conditions.where((c) {
      final start = DateTime(c.startDate.year, c.startDate.month, c.startDate.day);
      if (day.isBefore(start)) return false;
      if (c.endDate != null) {
        final end = DateTime(c.endDate!.year, c.endDate!.month, c.endDate!.day);
        if (day.isAfter(end)) return false;
      }
      return true;
    }).toList();
  }

  void _showCategoryFilter(Map<String, domain.Category> categories) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => SafeArea(
        child: StatefulBuilder(
          builder: (ctx, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(padding: const EdgeInsets.all(KitabSpacing.md), child: Text('Filter by Category', style: KitabTypography.h3)),
              ...categories.values.map((cat) => CheckboxListTile(
                title: Text('${cat.icon} ${cat.name}'),
                value: _selectedCategoryIds.contains(cat.id),
                onChanged: (v) {
                  setSheetState(() { v == true ? _selectedCategoryIds.add(cat.id) : _selectedCategoryIds.remove(cat.id); });
                  setState(() {});
                },
              )),
              const SizedBox(height: KitabSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  void _showGoalStatusFilter() {
    const statuses = ['Met', 'Missed', 'Excused'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => SafeArea(
        child: StatefulBuilder(
          builder: (ctx, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(padding: const EdgeInsets.all(KitabSpacing.md), child: Text('Filter by Goal Status', style: KitabTypography.h3)),
              ...statuses.map((status) => CheckboxListTile(
                title: Text(status),
                value: _selectedGoalStatuses.contains(status),
                onChanged: (v) {
                  setSheetState(() { v == true ? _selectedGoalStatuses.add(status) : _selectedGoalStatuses.remove(status); });
                  setState(() {});
                },
              )),
              const SizedBox(height: KitabSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  void _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    // Scroll to the date — find the group index
    // For now, just filter to that date's entries
    // TODO: Implement scroll-to-date with SliverList
  }

  void _showAdvancedFilters(Map<String, Activity> activities, Map<String, domain.Category> categories) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(KitabSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Advanced Filters', style: KitabTypography.h2),
              const SizedBox(height: KitabSpacing.lg),

              // Date range
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.date_range),
                title: const Text('Date Range'),
                subtitle: const Text('Filter entries by date range'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.pop(ctx);
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                  );
                  if (range != null) {
                    // TODO: Apply date range filter
                  }
                },
              ),

              // Activity template filter
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.list_alt),
                title: const Text('Activity Templates'),
                subtitle: const Text('Show entries from specific activities'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  // TODO: Show activity multi-select
                },
              ),

              // Entry type filter
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.tune),
                title: const Text('Entry Type'),
                subtitle: const Text('Timer, habit, metric, or quick entry'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  // TODO: Show entry type filter
                },
              ),

              const SizedBox(height: KitabSpacing.md),
            ],
          ),
        );
      },
    );
  }

  List<_DateGroup> _groupByDate(List<Entry> entries) {
    final groups = <String, _DateGroup>{};
    for (final entry in entries) {
      final dateKey = DateFormat('yyyy-MM-dd').format(entry.loggedAt);
      groups.putIfAbsent(dateKey, () => _DateGroup(date: entry.loggedAt, entries: []));
      groups[dateKey]!.entries.add(entry);
    }
    return groups.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }
}

// ═══════════════════════════════════════════════════════════════════
// DATE GROUP
// ═══════════════════════════════════════════════════════════════════

class _DateGroup {
  final DateTime date;
  final List<Entry> entries;
  _DateGroup({required this.date, required this.entries});
}

// ═══════════════════════════════════════════════════════════════════
// FILTER ROW
// ═══════════════════════════════════════════════════════════════════

class _FilterRow extends StatelessWidget {
  final bool showSearch;
  final String searchQuery;
  final Set<String> selectedCategoryIds;
  final Set<String> selectedGoalStatuses;
  final bool showConditions;
  final Map<String, domain.Category> categories;
  final VoidCallback onSearchToggle;
  final VoidCallback onCategoryFilter;
  final VoidCallback onGoalStatusFilter;
  final VoidCallback onConditionsToggle;
  final VoidCallback onDateJump;
  final VoidCallback onClear;
  final VoidCallback? onAdvancedFilters;
  final bool hasActiveFilters;

  const _FilterRow({
    required this.showSearch,
    required this.searchQuery,
    required this.selectedCategoryIds,
    required this.selectedGoalStatuses,
    required this.showConditions,
    required this.categories,
    required this.onSearchToggle,
    required this.onCategoryFilter,
    required this.onGoalStatusFilter,
    required this.onConditionsToggle,
    required this.onDateJump,
    required this.onClear,
    this.onAdvancedFilters,
    required this.hasActiveFilters,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: KitabSpacing.lg, vertical: KitabSpacing.xs),
      child: Row(
        children: [
          // Advanced filters
          if (onAdvancedFilters != null) ...[
            _chip(Icons.tune, 'Filters', false, onAdvancedFilters!),
            const SizedBox(width: 6),
          ],
          // Search
          _chip(Icons.search, 'Search', showSearch, onSearchToggle),
          const SizedBox(width: 6),
          // Date jump
          _chip(Icons.calendar_today, 'Date', false, onDateJump),
          const SizedBox(width: 6),
          // Categories
          _chip(
            Icons.category_outlined,
            selectedCategoryIds.isEmpty ? 'Categories' : 'Categories (${selectedCategoryIds.length})',
            selectedCategoryIds.isNotEmpty,
            onCategoryFilter,
          ),
          const SizedBox(width: 6),
          // Goal Status
          _chip(
            Icons.flag_outlined,
            selectedGoalStatuses.isEmpty ? 'Goal Status' : 'Goal: ${selectedGoalStatuses.join(', ')}',
            selectedGoalStatuses.isNotEmpty,
            onGoalStatusFilter,
          ),
          const SizedBox(width: 6),
          // Conditions
          _chip(Icons.healing, 'Conditions', showConditions, onConditionsToggle),
          // Clear
          if (hasActiveFilters) ...[
            const SizedBox(width: 6),
            ActionChip(
              avatar: const Icon(Icons.clear, size: 16, color: KitabColors.error),
              label: const Text('Clear'),
              onPressed: onClear,
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, bool active, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onTap,
      side: active ? const BorderSide(color: KitabColors.primary) : null,
      backgroundColor: active ? KitabColors.primary.withValues(alpha: 0.1) : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DAY SEPARATOR (with conditions)
// ═══════════════════════════════════════════════════════════════════

class _DaySeparator extends StatelessWidget {
  final DateTime date;
  /// Pre-computed merged condition chains (from `_mergeConditionsForDisplay`).
  /// Same source of truth as the condition card view — no separate chain walk.
  final List<_MergedCondition> mergedChains;
  final KitabDateFormat fmt;

  const _DaySeparator({
    required this.date,
    this.mergedChains = const [],
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);

    String label;
    if (dateDay == today) {
      label = 'Today, ${fmt.monthDay(date)}';
    } else if (dateDay == today.subtract(const Duration(days: 1))) {
      label = 'Yesterday, ${fmt.monthDay(date)}';
    } else {
      label = fmt.longDateWithDayName(date);
    }

    // Find merged chains that cover this day
    final dayCovering = mergedChains.where((chain) {
      final chainStartDay = DateTime(
        chain.startDate.year, chain.startDate.month, chain.startDate.day,
      );
      if (dateDay.isBefore(chainStartDay)) return false;
      if (chain.endDate != null) {
        final chainEndDay = DateTime(
          chain.endDate!.year, chain.endDate!.month, chain.endDate!.day,
        );
        if (dateDay.isAfter(chainEndDay)) return false;
      }
      return true;
    }).take(2);

    return Row(
      children: [
        Text(label, style: KitabTypography.bodySmall.copyWith(
          color: KitabColors.gray600, fontWeight: FontWeight.w600)),
        if (dayCovering.isNotEmpty) ...[
          const Text(' · ', style: TextStyle(color: KitabColors.gray400)),
          ...dayCovering.map((chain) {
            final chainStartDay = DateTime(
              chain.startDate.year, chain.startDate.month, chain.startDate.day,
            );
            final DateTime? chainEndDay = chain.endDate != null
                ? DateTime(chain.endDate!.year, chain.endDate!.month, chain.endDate!.day)
                : null;

            final daysSinceStart = dateDay.difference(chainStartDay).inDays;
            String dayLabel;
            if (chainEndDay != null && chainEndDay == chainStartDay) {
              dayLabel = '1 day';
            } else if (daysSinceStart == 0) {
              dayLabel = 'started';
            } else if (chainEndDay != null && dateDay == chainEndDay) {
              dayLabel = 'ended';
            } else {
              dayLabel = 'Day ${daysSinceStart + 1}';
            }
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                '${chain.emoji} $dayLabel',
                style: KitabTypography.caption.copyWith(color: KitabColors.gray500),
              ),
            );
          }),
        ],
        const SizedBox(width: KitabSpacing.sm),
        Expanded(child: Divider(color: KitabColors.gray200, thickness: 1)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════

/// Parse a time value (ISO string, formatted time, or other) into a short local time.
String? _parseTimeDisplay(dynamic value, KitabDateFormat fmt) {
  if (value == null) return null;
  if (value is String) {
    // Try ISO 8601 parse
    final dt = DateTime.tryParse(value);
    if (dt != null) return fmt.time(dt.toLocal());
    // Already a formatted time like "5:15 AM" — return as-is
    if (value.contains('AM') || value.contains('PM') || value.contains('am') || value.contains('pm')) {
      return value;
    }
    return value;
  }
  return null;
}

class _MergedCondition {
  final String label;
  final String emoji;
  final String presetId;
  final DateTime startDate;
  DateTime? endDate;
  final List<String> conditionIds;

  _MergedCondition({
    required this.label,
    required this.emoji,
    required this.presetId,
    required this.startDate,
    this.endDate,
    required this.conditionIds,
  });
}

class _ConditionDetailPanel extends ConsumerStatefulWidget {
  final Condition condition;
  final VoidCallback onChanged;
  final ValueChanged<bool>? onDirtyChanged;
  /// Override dates from a merged condition group.
  final DateTime? mergedStartDate;
  final DateTime? mergedEndDate;
  /// All condition record IDs in the merged group.
  /// Used so edits (end/delete) apply to every day, not just the first.
  final List<String>? mergedConditionIds;

  const _ConditionDetailPanel({
    super.key,
    required this.condition,
    required this.onChanged,
    this.onDirtyChanged,
    this.mergedStartDate,
    this.mergedEndDate,
    this.mergedConditionIds,
  });

  @override
  ConsumerState<_ConditionDetailPanel> createState() => _ConditionDetailPanelState();
}

class _ConditionDetailPanelState extends ConsumerState<_ConditionDetailPanel> {
  late DateTime _startDate;
  late DateTime _endDate;
  late DateTime _originalStartDate;
  late DateTime _originalEndDate;
  bool get _isActive => widget.condition.endDate == null;
  bool get _hasChanges =>
      _startDate != _originalStartDate || _endDate != _originalEndDate;

  @override
  void initState() {
    super.initState();
    _initDates();
  }

  @override
  void didUpdateWidget(covariant _ConditionDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.condition.id != widget.condition.id) {
      _initDates();
    }
  }

  void _initDates() {
    _startDate = widget.mergedStartDate ?? widget.condition.startDate;
    _endDate = widget.mergedEndDate ?? widget.condition.endDate ?? DateTime.now();
    _originalStartDate = _startDate;
    _originalEndDate = _endDate;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = ref.watch(dateFormatterProvider);
    return Padding(
      padding: const EdgeInsets.all(KitabSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(widget.condition.emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: KitabSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.condition.label, style: KitabTypography.h2),
                    if (_isActive)
                      Text('Active', style: KitabTypography.bodySmall.copyWith(color: KitabColors.success, fontWeight: FontWeight.w600))
                    else
                      Text('Ended', style: KitabTypography.bodySmall.copyWith(color: KitabColors.gray500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: KitabSpacing.xl),

          // Start date
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: const Text('Start Date'),
            subtitle: Text(fmt.fullDateWithDay(_startDate)),
            trailing: const Icon(Icons.edit, size: 18, color: KitabColors.gray400),
            onTap: () async {
              final picked = await showDatePicker(
                context: context, initialDate: _startDate,
                firstDate: DateTime(2020), lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _startDate = picked);
                widget.onDirtyChanged?.call(_hasChanges);
              }
            },
          ),

          // End date
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_available),
            title: Text(_isActive ? 'End Date (set to end condition)' : 'End Date'),
            subtitle: Text(_isActive ? 'Still active — tap to set end date' : fmt.fullDateWithDay(_endDate)),
            trailing: const Icon(Icons.edit, size: 18, color: KitabColors.gray400),
            onTap: () async {
              final picked = await showDatePicker(
                context: context, initialDate: _endDate,
                firstDate: _startDate, lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _endDate = picked);
                widget.onDirtyChanged?.call(_hasChanges);
              }
            },
          ),

          const Spacer(),

          // Actions
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _hasChanges || _isActive
                  ? () async {
                      final repo = ref.read(conditionRepositoryProvider);
                      final statusRepo = ref.read(periodStatusRepositoryProvider);
                      final ids = widget.mergedConditionIds ?? [widget.condition.id];
                      // Apply start date change to the FIRST condition record only
                      // (it represents the group's start day)
                      if (_startDate != _originalStartDate) {
                        await repo.saveCondition(
                          widget.condition.copyWith(startDate: _startDate),
                        );
                      }
                      // End date + status cleanup applies to EVERY record in the group
                      for (final id in ids) {
                        await repo.endCondition(id, _endDate);
                        await statusRepo.clearExcusesOutsideRange(
                          id, _startDate, _endDate,
                        );
                      }
                      refreshAllEntryProviders(ref);
                      widget.onDirtyChanged?.call(false);
                      widget.onChanged();
                      if (mounted) {
                        KitabToast.success(context, '${widget.condition.label} updated');
                      }
                    }
                  : null,
              child: Text(_isActive ? 'End Condition' : 'Save Changes'),
            ),
          ),
          const SizedBox(height: KitabSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: const Text('Delete Condition?'),
                    content: const Text('Activities excused with this condition will become unexcused.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: KitabColors.error),
                        onPressed: () => Navigator.pop(d, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  final condRepo = ref.read(conditionRepositoryProvider);
                  final statusRepo = ref.read(periodStatusRepositoryProvider);
                  // Delete all condition records in the merged group (or
                  // just the single condition if not part of a group).
                  final ids = widget.mergedConditionIds ?? [widget.condition.id];
                  for (final id in ids) {
                    await condRepo.deleteCondition(id);
                    await statusRepo.clearExcusesByConditionId(id);
                  }
                  refreshAllEntryProviders(ref);
                  widget.onChanged();
                }
              },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete Condition'),
              style: OutlinedButton.styleFrom(
                foregroundColor: KitabColors.error,
                side: const BorderSide(color: KitabColors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _parseColor(String hex) {
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  } catch (_) {
    return KitabColors.primary;
  }
}

/// The "when did this happen" timestamp for an entry.
/// Prefers the user-recorded start_time field, falls back to loggedAt.
DateTime _entryReferenceTime(Entry entry) {
  final rawStart = entry.fieldValues['start_time'];
  if (rawStart is String) {
    final parsed = DateTime.tryParse(rawStart);
    if (parsed != null) return parsed.toLocal();
  }
  return entry.loggedAt;
}

/// Build a non-versioned goalsJson using the most recent goal version.
/// Used as a fallback for entries that predate all goal versions, so the
/// goal status icon can still be shown under current rules.
Map<String, dynamic>? _extractLatestGoalsVersion(Map<String, dynamic> goalsJson) {
  final versions = goalsJson['versions'] as List<dynamic>?;
  if (versions == null || versions.isEmpty) {
    // Already non-versioned — return as-is
    return goalsJson;
  }
  // Sort versions by effective_from descending and take the most recent
  final sorted = [...versions]..sort((a, b) {
    final aFrom = DateTime.tryParse((a as Map)['effective_from'] as String? ?? '') ?? DateTime(0);
    final bFrom = DateTime.tryParse((b as Map)['effective_from'] as String? ?? '') ?? DateTime(0);
    return bFrom.compareTo(aFrom);
  });
  final latest = sorted.first as Map<String, dynamic>;
  final goals = latest['goals'] as List<dynamic>?;
  if (goals == null) return null;
  return {'goals': goals};
}

/// Three-state goal status icon for entry cards.
///   met         → ✓ (green) — goal satisfied
///   not_met     → ✕ (red)   — period ended without meeting goal
///   in_progress → ○ (gray)  — period still active, not yet met
class _GoalStatusIcon extends StatelessWidget {
  final String status;
  const _GoalStatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'met':
        return Tooltip(
          message: 'Goal met',
          child: const Icon(Icons.check_circle, size: 14, color: KitabColors.success),
        );
      case 'not_met':
        return Tooltip(
          message: 'Goal not met',
          child: const Icon(Icons.cancel, size: 14, color: KitabColors.error),
        );
      case 'in_progress':
        return Tooltip(
          message: 'In progress — period still active',
          child: const Icon(Icons.radio_button_unchecked, size: 14, color: KitabColors.gray400),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

/// Delegate for sticky day headers in the Book timeline.
class _StickyDayHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyDayHeaderDelegate({required this.child});

  @override
  double get minExtent => 36;
  @override
  double get maxExtent => 36;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 36,
      color: isDark ? KitabColors.darkBackground : KitabColors.lightBackground,
      padding: const EdgeInsets.symmetric(horizontal: KitabSpacing.lg),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyDayHeaderDelegate oldDelegate) => true;
}
