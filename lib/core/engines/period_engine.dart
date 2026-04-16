// ═══════════════════════════════════════════════════════════════════
// PERIOD_ENGINE.DART — Computed Schedule Period Generator
// Pure computation: takes a schedule config + date range and outputs
// period boundaries. Nothing is stored in the database.
// See SPEC.md §9 for full specification.
//
// Key design: Periods are computed on-the-fly because:
//  1. Open-ended schedules would create infinite rows
//  2. Dynamic prayer times change daily based on location
//  3. Schedule versioning requires recomputation anyway
// ═══════════════════════════════════════════════════════════════════

/// A single computed period with start and end boundaries (UTC).
class ComputedPeriod {
  final DateTime start;
  final DateTime end;

  const ComputedPeriod({required this.start, required this.end});

  /// Whether a given timestamp falls within this period.
  bool contains(DateTime dt) => !dt.isBefore(start) && dt.isBefore(end);

  /// Duration of this period.
  Duration get duration => end.difference(start);

  @override
  String toString() => 'Period($start → $end)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComputedPeriod && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// Parsed schedule configuration for a single version.
class ScheduleConfig {
  final String frequency; // 'daily', 'weekly', 'monthly', 'yearly', 'custom'
  final String calendar; // 'gregorian', 'hijri'
  final DateTime startDate;
  final DateTime? endDate;

  // ─── Frequency-specific fields ───
  final List<int> selectedDays; // For weekly (1-7), monthly (1-31), yearly
  final String? selectedMonth; // For yearly (month name or number)
  final bool consecutiveAsOnePeriod; // Whether consecutive days form one period
  final int? customInterval; // For custom: every X...
  final String? customUnit; // 'days', 'weeks', 'months', 'years'

  // ─── Time Window ───
  final bool hasTimeWindow;
  final String? timeType; // 'specific', 'dynamic'
  final String? windowStart; // HH:mm for specific, prayer name for dynamic
  final int windowStartOffset; // Minutes offset for dynamic
  final String? windowEnd;
  final int windowEndOffset;

  // ─── Week start (from user settings) ───
  final int weekStartDay; // 0=Sunday, 1=Monday, 6=Saturday

  const ScheduleConfig({
    required this.frequency,
    this.calendar = 'gregorian',
    required this.startDate,
    this.endDate,
    this.selectedDays = const [],
    this.selectedMonth,
    this.consecutiveAsOnePeriod = false,
    this.customInterval,
    this.customUnit,
    this.hasTimeWindow = false,
    this.timeType,
    this.windowStart,
    this.windowStartOffset = 0,
    this.windowEnd,
    this.windowEndOffset = 0,
    this.weekStartDay = 0,
  });

  /// Parse from the JSONB schedule config map.
  factory ScheduleConfig.fromJson(
    Map<String, dynamic> json, {
    int weekStartDay = 0,
  }) {
    return ScheduleConfig(
      frequency: json['frequency'] as String? ?? 'daily',
      calendar: json['calendar'] as String? ?? 'gregorian',
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      selectedDays: (json['selected_days'] as List<dynamic>?)
              ?.map((d) => d as int)
              .toList() ??
          [],
      selectedMonth: json['selected_month'] as String?,
      consecutiveAsOnePeriod:
          json['consecutive_as_one_period'] as bool? ?? false,
      customInterval: json['custom_interval'] as int?,
      customUnit: json['custom_unit'] as String?,
      hasTimeWindow: json['has_time_window'] as bool? ?? false,
      timeType: json['time_type'] as String?,
      windowStart: json['window_start'] as String?,
      windowStartOffset: json['window_start_offset'] as int? ?? 0,
      windowEnd: json['window_end'] as String?,
      windowEndOffset: json['window_end_offset'] as int? ?? 0,
      weekStartDay: weekStartDay,
    );
  }
}

/// The Period Engine: computes schedule periods on-the-fly.
///
/// Usage:
/// ```dart
/// final engine = PeriodEngine();
/// final periods = engine.computePeriods(
///   scheduleJson: activity.schedule,
///   queryStart: todayStart,
///   queryEnd: todayEnd,
///   weekStartDay: userSettings.weekStartDay,
/// );
/// ```
class PeriodEngine {
  const PeriodEngine();

  /// Compute all periods for a schedule within a date range.
  ///
  /// [scheduleJson] — the activity's schedule JSONB (versioned).
  /// [queryStart] / [queryEnd] — the date range to generate periods for.
  /// [weekStartDay] — user's global week start day (0=Sunday).
  /// [prayerTimeResolver] — optional function to resolve dynamic prayer times
  ///   for a given date. Returns a map of prayer name → DateTime (UTC).
  List<ComputedPeriod> computePeriods({
    required Map<String, dynamic>? scheduleJson,
    required DateTime queryStart,
    required DateTime queryEnd,
    int weekStartDay = 0,
    Map<String, DateTime> Function(DateTime date)? prayerTimeResolver,
  }) {
    if (scheduleJson == null) return [];

    // ─── Resolve the correct schedule version for the query range ───
    final versions = _parseVersions(scheduleJson, weekStartDay);
    if (versions.isEmpty) return [];

    final periods = <ComputedPeriod>[];

    for (final version in versions) {
      // Determine the effective range for this version within the query
      final effectiveStart = _latest(version.startDate, queryStart);
      final effectiveEnd = version.endDate != null
          ? _earliest(version.endDate!, queryEnd)
          : queryEnd;

      if (effectiveEnd.isBefore(effectiveStart) ||
          effectiveEnd == effectiveStart) {
        continue;
      }

      final config = version.config;

      switch (config.frequency) {
        case 'daily':
          periods.addAll(_computeDaily(config, effectiveStart, effectiveEnd));
        case 'weekly':
          periods.addAll(_computeWeekly(config, effectiveStart, effectiveEnd));
        case 'monthly':
          periods.addAll(_computeMonthly(config, effectiveStart, effectiveEnd));
        case 'yearly':
          periods.addAll(_computeYearly(config, effectiveStart, effectiveEnd));
        case 'custom':
          periods.addAll(_computeCustom(config, effectiveStart, effectiveEnd));
      }
    }

    // Sort by start time and deduplicate
    periods.sort((a, b) => a.start.compareTo(b.start));
    return periods;
  }

  /// Compute periods for a single day (convenience method for Home screen).
  List<ComputedPeriod> computePeriodsForDate({
    required Map<String, dynamic>? scheduleJson,
    required DateTime date,
    int weekStartDay = 0,
    Map<String, DateTime> Function(DateTime date)? prayerTimeResolver,
  }) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return computePeriods(
      scheduleJson: scheduleJson,
      queryStart: dayStart,
      queryEnd: dayEnd,
      weekStartDay: weekStartDay,
    );
  }

  /// Find which period a given timestamp belongs to.
  /// Returns null if the timestamp doesn't fall in any period.
  ComputedPeriod? findPeriodForTimestamp({
    required Map<String, dynamic>? scheduleJson,
    required DateTime timestamp,
    int weekStartDay = 0,
    Map<String, DateTime> Function(DateTime date)? prayerTimeResolver,
  }) {
    // Search a window around the timestamp (±2 days covers cross-midnight)
    final searchStart = timestamp.subtract(const Duration(days: 2));
    final searchEnd = timestamp.add(const Duration(days: 2));
    final periods = computePeriods(
      scheduleJson: scheduleJson,
      queryStart: searchStart,
      queryEnd: searchEnd,
      weekStartDay: weekStartDay,
    );
    for (final period in periods) {
      if (period.contains(timestamp)) return period;
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════
  // PUBLIC STATIC: Time Window Resolution (for entry presets)
  // ═══════════════════════════════════════════════════════════════════

  /// Compute the expected start and end times for an activity's time window
  /// on a specific date, using the provided prayer time resolver for dynamic
  /// windows. Returns expected start/end as DateTime values, or null if
  /// the schedule has no time window or times can't be computed.
  ///
  /// This extracts the old time-window resolution logic so that time windows
  /// are surfaced as entry preset fields, NOT as period boundaries.
  static ({DateTime? start, DateTime? end}) resolveExpectedTimes({
    required Map<String, dynamic>? scheduleJson,
    required DateTime date,
    Map<String, DateTime> Function(DateTime)? prayerTimeResolver,
  }) {
    if (scheduleJson == null) return (start: null, end: null);

    // Find the active schedule version for the given date
    final config = _resolveConfigForDate(scheduleJson, date);
    if (config == null) return (start: null, end: null);

    if (!config.hasTimeWindow) return (start: null, end: null);

    final startTime = _resolveTimeWindowBoundary(
      date: date,
      config: config,
      isStart: true,
      prayerTimeResolver: prayerTimeResolver,
    );
    final endTime = _resolveTimeWindowBoundary(
      date: date,
      config: config,
      isStart: false,
      prayerTimeResolver: prayerTimeResolver,
    );

    return (start: startTime, end: endTime);
  }

  /// Resolve a single time window boundary (start or end) for a date.
  static DateTime? _resolveTimeWindowBoundary({
    required DateTime date,
    required ScheduleConfig config,
    required bool isStart,
    Map<String, DateTime> Function(DateTime)? prayerTimeResolver,
  }) {
    final timeStr = isStart ? config.windowStart : config.windowEnd;
    final offset = isStart ? config.windowStartOffset : config.windowEndOffset;

    if (config.timeType == 'dynamic') {
      if (prayerTimeResolver == null) return null;
      final prayerTimes = prayerTimeResolver(date);
      final prayerTime = prayerTimes[timeStr];
      if (prayerTime == null) return null;
      return prayerTime.add(Duration(minutes: offset));
    }

    if (config.timeType == 'specific' && timeStr != null) {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        var result = DateTime(date.year, date.month, date.day, hour, minute);

        // Handle midnight crossover: if end ≤ start, end is next day
        if (!isStart && config.windowStart != null) {
          final startParts = config.windowStart!.split(':');
          final startHour = int.tryParse(startParts[0]) ?? 0;
          final startMin = int.tryParse(startParts[1]) ?? 0;
          if (hour < startHour || (hour == startHour && minute <= startMin)) {
            result = result.add(const Duration(days: 1));
          }
        }

        return result;
      }
    }

    return null;
  }

  /// Resolve the active ScheduleConfig for a given date from schedule JSON.
  static ScheduleConfig? _resolveConfigForDate(
    Map<String, dynamic> json,
    DateTime date,
  ) {
    final versionsJson = json['versions'] as List<dynamic>?;

    if (versionsJson == null || versionsJson.isEmpty) {
      // Legacy: non-versioned schedule
      final configJson =
          json['config'] as Map<String, dynamic>? ?? json;
      return ScheduleConfig.fromJson(configJson);
    }

    // Find the version whose effective range contains the date
    for (final v in versionsJson) {
      final vMap = v as Map<String, dynamic>;
      final from = DateTime.parse(vMap['effective_from'] as String);
      final to = vMap['effective_to'] != null
          ? DateTime.parse(vMap['effective_to'] as String)
          : null;

      if (!date.isBefore(from) && (to == null || date.isBefore(to))) {
        return ScheduleConfig.fromJson(
            vMap['config'] as Map<String, dynamic>);
      }
    }

    return null;
  }

  // ═══════════════════════════════════════════════════════════════════
  // PRIVATE: Version Parsing
  // ═══════════════════════════════════════════════════════════════════

  List<_ScheduleVersion> _parseVersions(
      Map<String, dynamic> json, int weekStartDay) {
    final versionsJson = json['versions'] as List<dynamic>?;
    if (versionsJson == null || versionsJson.isEmpty) {
      // Legacy: non-versioned schedule — treat as single version
      return [
        _ScheduleVersion(
          startDate: DateTime.tryParse(
                  json['config']?['start_date'] as String? ?? '') ??
              DateTime(2020),
          endDate: json['config']?['end_date'] != null
              ? DateTime.tryParse(json['config']['end_date'] as String)
              : null,
          config: ScheduleConfig.fromJson(
            json['config'] as Map<String, dynamic>? ?? json,
            weekStartDay: weekStartDay,
          ),
        ),
      ];
    }

    return versionsJson.map((v) {
      final vMap = v as Map<String, dynamic>;
      return _ScheduleVersion(
        startDate: DateTime.parse(vMap['effective_from'] as String),
        endDate: vMap['effective_to'] != null
            ? DateTime.parse(vMap['effective_to'] as String)
            : null,
        config: ScheduleConfig.fromJson(
          vMap['config'] as Map<String, dynamic>,
          weekStartDay: weekStartDay,
        ),
      );
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════
  // PRIVATE: Daily Periods
  // ═══════════════════════════════════════════════════════════════════

  List<ComputedPeriod> _computeDaily(
    ScheduleConfig config,
    DateTime rangeStart,
    DateTime rangeEnd, [
    Map<String, DateTime> Function(DateTime)? prayerResolver,
  ]) {
    final periods = <ComputedPeriod>[];
    var current = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
    final end = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);

    // Don't generate periods before the schedule start date
    final scheduleDay = DateTime(
        config.startDate.year, config.startDate.month, config.startDate.day);
    if (current.isBefore(scheduleDay)) current = scheduleDay;

    while (!current.isAfter(end)) {
      final period = _dayPeriod(current, config);
      if (period != null) periods.add(period);
      current = current.add(const Duration(days: 1));
    }
    return periods;
  }

  // ═══════════════════════════════════════════════════════════════════
  // PRIVATE: Weekly Periods
  // ═══════════════════════════════════════════════════════════════════

  List<ComputedPeriod> _computeWeekly(
    ScheduleConfig config,
    DateTime rangeStart,
    DateTime rangeEnd, [
    Map<String, DateTime> Function(DateTime)? prayerResolver,
  ]) {
    final periods = <ComputedPeriod>[];

    if (config.selectedDays.isEmpty) return periods;

    // Convert Dart's weekday (1=Monday..7=Sunday) to match user's week
    // selectedDays uses 1=Mon, 2=Tue, ..., 7=Sun

    // If "entire week" or consecutive days as one period
    if (config.consecutiveAsOnePeriod && config.selectedDays.length > 1) {
      // Find week boundaries and create spanning period
      var current = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
      final end = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);

      while (!current.isAfter(end)) {
        // Find the start of the current week
        final weekStart = _weekStartDate(current, config.weekStartDay);

        // Find first and last selected days in this week
        final sortedDays = List<int>.from(config.selectedDays)..sort();
        final firstDay = weekStart
            .add(Duration(days: _dayOffset(sortedDays.first, config.weekStartDay)));
        final lastDay = weekStart
            .add(Duration(days: _dayOffset(sortedDays.last, config.weekStartDay)));

        if (!firstDay.isAfter(end) && !lastDay.isBefore(rangeStart)) {
          final periodStart = _applyTimeWindow(firstDay, config, true, null);
          final periodEnd = _applyTimeWindow(lastDay, config, false, null);
          if (periodStart != null && periodEnd != null) {
            periods.add(ComputedPeriod(start: periodStart, end: periodEnd));
          }
        }

        // Move to next week
        current = weekStart.add(const Duration(days: 7));
      }
    } else {
      // Separate period per selected day
      var current = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
      final end = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);

      while (!current.isAfter(end)) {
        if (config.selectedDays.contains(current.weekday)) {
          final period = _dayPeriod(current, config);
          if (period != null) periods.add(period);
        }
        current = current.add(const Duration(days: 1));
      }
    }

    return periods;
  }

  // ═══════════════════════════════════════════════════════════════════
  // PRIVATE: Monthly Periods
  // ═══════════════════════════════════════════════════════════════════

  List<ComputedPeriod> _computeMonthly(
    ScheduleConfig config,
    DateTime rangeStart,
    DateTime rangeEnd, [
    Map<String, DateTime> Function(DateTime)? prayerResolver,
  ]) {
    final periods = <ComputedPeriod>[];
    if (config.selectedDays.isEmpty) return periods;

    // Iterate through each month in the range
    var year = rangeStart.year;
    var month = rangeStart.month;

    while (DateTime(year, month) .isBefore(rangeEnd) ||
        (DateTime(year, month).year == rangeEnd.year &&
            DateTime(year, month).month == rangeEnd.month)) {
      final daysInMonth = _daysInMonth(year, month);
      final sortedDays = List<int>.from(config.selectedDays)..sort();

      if (config.consecutiveAsOnePeriod && sortedDays.length > 1) {
        // One spanning period from first to last selected day
        final firstDay = sortedDays.first.clamp(1, daysInMonth);
        final lastDay = sortedDays.last.clamp(1, daysInMonth);
        final start = DateTime(year, month, firstDay);
        final end = DateTime(year, month, lastDay);

        final periodStart = _applyTimeWindow(start, config, true, null);
        final periodEnd = _applyTimeWindow(end, config, false, null);
        if (periodStart != null && periodEnd != null) {
          if (!end.isBefore(rangeStart) && !start.isAfter(rangeEnd)) {
            periods.add(ComputedPeriod(start: periodStart, end: periodEnd));
          }
        }
      } else {
        // Separate period per selected day
        for (final day in sortedDays) {
          final actualDay = day.clamp(1, daysInMonth);
          final date = DateTime(year, month, actualDay);

          if (!date.isBefore(rangeStart) && date.isBefore(rangeEnd)) {
            final period = _dayPeriod(date, config);
            if (period != null) periods.add(period);
          }
        }
      }

      // Next month
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
    }

    return periods;
  }

  // ═══════════════════════════════════════════════════════════════════
  // PRIVATE: Yearly Periods
  // ═══════════════════════════════════════════════════════════════════

  List<ComputedPeriod> _computeYearly(
    ScheduleConfig config,
    DateTime rangeStart,
    DateTime rangeEnd, [
    Map<String, DateTime> Function(DateTime)? prayerResolver,
  ]) {
    // For Gregorian yearly, it's like monthly but only for one specific month
    // For Hijri yearly, we need the Hijri calendar service (deferred to Step 2.4)
    if (config.calendar == 'hijri') {
      // TODO: Hijri yearly computation requires prayer time / Hijri service
      // Will be implemented in Step 2.4
      return [];
    }

    // Gregorian yearly: specific month + days
    final targetMonth = _parseMonth(config.selectedMonth);
    if (targetMonth == null) return [];

    final periods = <ComputedPeriod>[];

    for (var year = rangeStart.year; year <= rangeEnd.year; year++) {
      final daysInMonth = _daysInMonth(year, targetMonth);
      final sortedDays = List<int>.from(config.selectedDays)..sort();

      if (config.consecutiveAsOnePeriod && sortedDays.length > 1) {
        final firstDay = sortedDays.first.clamp(1, daysInMonth);
        final lastDay = sortedDays.last.clamp(1, daysInMonth);
        final start = DateTime(year, targetMonth, firstDay);
        final end = DateTime(year, targetMonth, lastDay);

        if (!end.isBefore(rangeStart) && !start.isAfter(rangeEnd)) {
          final periodStart = _applyTimeWindow(start, config, true, null);
          final periodEnd = _applyTimeWindow(end, config, false, null);
          if (periodStart != null && periodEnd != null) {
            periods.add(ComputedPeriod(start: periodStart, end: periodEnd));
          }
        }
      } else {
        for (final day in sortedDays) {
          final actualDay = day.clamp(1, daysInMonth);
          final date = DateTime(year, targetMonth, actualDay);

          if (!date.isBefore(rangeStart) && date.isBefore(rangeEnd)) {
            final period = _dayPeriod(date, config);
            if (period != null) periods.add(period);
          }
        }
      }
    }

    return periods;
  }

  // ═══════════════════════════════════════════════════════════════════
  // PRIVATE: Custom Interval Periods
  // ═══════════════════════════════════════════════════════════════════

  List<ComputedPeriod> _computeCustom(
    ScheduleConfig config,
    DateTime rangeStart,
    DateTime rangeEnd, [
    Map<String, DateTime> Function(DateTime)? prayerResolver,
  ]) {
    final periods = <ComputedPeriod>[];
    final interval = config.customInterval ?? 1;
    final unit = config.customUnit ?? 'days';
    final anchor = DateTime(
        config.startDate.year, config.startDate.month, config.startDate.day);

    var current = anchor;

    // Fast-forward to near the range start
    if (current.isBefore(rangeStart)) {
      final daysDiff = rangeStart.difference(current).inDays;
      switch (unit) {
        case 'days':
          final steps = daysDiff ~/ interval;
          current = current.add(Duration(days: steps * interval));
        case 'weeks':
          final steps = daysDiff ~/ (interval * 7);
          current = current.add(Duration(days: steps * interval * 7));
        case 'months':
          // Approximate fast-forward
          final monthsDiff =
              (rangeStart.year - current.year) * 12 +
              (rangeStart.month - current.month);
          final steps = monthsDiff ~/ interval;
          current = _addMonths(current, steps * interval);
        case 'years':
          final yearsDiff = rangeStart.year - current.year;
          final steps = yearsDiff ~/ interval;
          current = DateTime(
              current.year + steps * interval, current.month, current.day);
      }
    }

    // Generate periods
    while (!current.isAfter(rangeEnd)) {
      if (!current.isBefore(rangeStart)) {
        final period = _dayPeriod(current, config);
        if (period != null) periods.add(period);
      }

      // Advance by interval
      switch (unit) {
        case 'days':
          current = current.add(Duration(days: interval));
        case 'weeks':
          current = current.add(Duration(days: interval * 7));
        case 'months':
          current = _addMonths(current, interval);
        case 'years':
          current =
              DateTime(current.year + interval, current.month, current.day);
        default:
          current = current.add(Duration(days: interval));
      }
    }

    return periods;
  }

  // ═══════════════════════════════════════════════════════════════════
  // PRIVATE: Helpers
  // ═══════════════════════════════════════════════════════════════════

  /// Create a period for a single day, applying time windows.
  ComputedPeriod? _dayPeriod(
    DateTime date,
    ScheduleConfig config, [
    Map<String, DateTime> Function(DateTime)? prayerResolver,
  ]) {
    final dayStart = _applyTimeWindow(date, config, true, null);
    final dayEnd = _applyTimeWindow(date, config, false, null);
    if (dayStart == null || dayEnd == null) return null;
    return ComputedPeriod(start: dayStart, end: dayEnd);
  }

  /// Apply time window to a date, returning the start or end time.
  ///
  /// Periods are ALWAYS full calendar days (midnight to midnight),
  /// regardless of any time window configuration. Time windows are now
  /// resolved separately via [PeriodEngine.resolveExpectedTimes] and
  /// stored as entry preset fields, not period boundaries.
  DateTime? _applyTimeWindow(
    DateTime date,
    ScheduleConfig config,
    bool isStart,
    Map<String, DateTime> Function(DateTime)? prayerResolver,
  ) {
    // Always return full-day boundaries (midnight to midnight).
    if (isStart) {
      return DateTime(date.year, date.month, date.day);
    } else {
      return DateTime(date.year, date.month, date.day)
          .add(const Duration(days: 1));
    }
  }

  /// Get the start of the week containing [date].
  DateTime _weekStartDate(DateTime date, int weekStartDay) {
    // Dart weekday: 1=Mon, 2=Tue, ..., 7=Sun
    // weekStartDay: 0=Sun, 1=Mon, ..., 6=Sat
    final dartWeekStart = weekStartDay == 0 ? 7 : weekStartDay;
    var diff = date.weekday - dartWeekStart;
    if (diff < 0) diff += 7;
    return DateTime(date.year, date.month, date.day - diff);
  }

  /// Calculate the day offset from week start for a given weekday.
  int _dayOffset(int weekday, int weekStartDay) {
    final dartWeekStart = weekStartDay == 0 ? 7 : weekStartDay;
    var offset = weekday - dartWeekStart;
    if (offset < 0) offset += 7;
    return offset;
  }

  /// Number of days in a month.
  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// Parse a month name or number to int.
  int? _parseMonth(String? month) {
    if (month == null) return null;
    final asInt = int.tryParse(month);
    if (asInt != null && asInt >= 1 && asInt <= 12) return asInt;

    const months = {
      'january': 1, 'february': 2, 'march': 3, 'april': 4,
      'may': 5, 'june': 6, 'july': 7, 'august': 8,
      'september': 9, 'october': 10, 'november': 11, 'december': 12,
    };
    return months[month.toLowerCase()];
  }

  /// Add months to a date, clamping to last day of month.
  DateTime _addMonths(DateTime date, int months) {
    var year = date.year;
    var month = date.month + months;
    while (month > 12) {
      month -= 12;
      year++;
    }
    while (month < 1) {
      month += 12;
      year--;
    }
    final maxDay = _daysInMonth(year, month);
    return DateTime(year, month, date.day.clamp(1, maxDay));
  }

  /// Return the later of two dates.
  DateTime _latest(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

  /// Return the earlier of two dates.
  DateTime _earliest(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
}

/// Internal: a parsed schedule version with its effective date range.
class _ScheduleVersion {
  final DateTime startDate;
  final DateTime? endDate;
  final ScheduleConfig config;

  const _ScheduleVersion({
    required this.startDate,
    this.endDate,
    required this.config,
  });
}
