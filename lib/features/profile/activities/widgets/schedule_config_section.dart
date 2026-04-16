// ═══════════════════════════════════════════════════════════════════
// SCHEDULE_CONFIG_SECTION.DART — Activity Schedule Configuration
// Calendar, date range, repeat frequency (daily/weekly/monthly/
// yearly/custom), expected entries, time window with offsets.
// See SPEC §5.3 for full specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../../../core/theme/kitab_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/kitab_toast.dart';
import '../../../../core/widgets/hijri_date_picker.dart';

// ═══════════════════════════════════════════════════════════════════
// HIJRI MONTH NAMES
// ═══════════════════════════════════════════════════════════════════

const _hijriMonths = [
  'Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani',
  'Jumada al-Ula', 'Jumada al-Thani', 'Rajab', 'Shaban',
  'Ramadan', 'Shawwal', 'Dhul Qadah', 'Dhul Hijjah',
];

const _gregorianMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

// ═══════════════════════════════════════════════════════════════════
// YEARLY DATE ENTRY (single day or range)
// ═══════════════════════════════════════════════════════════════════

class YearlyDateEntry {
  int startMonth;
  int startDay;
  int? endMonth; // null = single day
  int? endDay;

  YearlyDateEntry({required this.startMonth, required this.startDay, this.endMonth, this.endDay});

  bool get isRange => endMonth != null && endDay != null;

  /// Whether this range crosses the year boundary (e.g., Dec → Jan).
  bool get crossesYear => isRange && (endMonth! < startMonth ||
      (endMonth == startMonth && endDay! < startDay));

  String format(bool isHijri) {
    final months = isHijri ? _hijriMonths : _gregorianMonths;
    final start = '${months[startMonth - 1]} $startDay';
    if (!isRange) return start;
    final end = '${months[endMonth! - 1]} $endDay';
    return crossesYear ? '$start → $end (next year)' : '$start → $end';
  }

  Map<String, dynamic> toJson() => {
    'start_month': startMonth, 'start_day': startDay,
    if (endMonth != null) 'end_month': endMonth,
    if (endDay != null) 'end_day': endDay,
  };

  factory YearlyDateEntry.fromJson(Map<String, dynamic> json) => YearlyDateEntry(
    startMonth: json['start_month'] as int,
    startDay: json['start_day'] as int,
    endMonth: json['end_month'] as int?,
    endDay: json['end_day'] as int?,
  );
}

// ═══════════════════════════════════════════════════════════════════
// SCHEDULE STATE
// ═══════════════════════════════════════════════════════════════════

class ScheduleState {
  String calendar;
  DateTime startDate;
  DateTime? endDate;
  String frequency;

  // Weekly/Monthly/Yearly mode: 'specific' or 'any'
  String selectionMode;
  List<int> selectedDays; // weekdays 1-7 or month days 1-31
  bool consecutiveAsOne; // true = "together as one", false = "each day separately"

  // Yearly dates
  List<YearlyDateEntry> yearlyDates;

  String expectedEntries;
  bool hasTimeWindow;
  String timeType;
  String? windowStart;
  String? windowEnd;
  int windowStartOffset;
  int windowEndOffset;

  int customInterval;
  String customUnit;

  ScheduleState({
    this.calendar = 'gregorian',
    DateTime? startDate,
    this.endDate,
    this.frequency = 'daily',
    this.selectionMode = 'specific',
    this.selectedDays = const [],
    this.consecutiveAsOne = false,
    this.yearlyDates = const [],
    this.expectedEntries = 'once',
    this.hasTimeWindow = false,
    this.timeType = 'specific',
    this.windowStart,
    this.windowEnd,
    this.windowStartOffset = 0,
    this.windowEndOffset = 0,
    this.customInterval = 1,
    this.customUnit = 'days',
  }) : startDate = startDate ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'frequency': frequency,
    'calendar': calendar,
    'start_date': startDate.toIso8601String(),
    if (endDate != null) 'end_date': endDate!.toIso8601String(),
    'selection_mode': selectionMode,
    if (selectedDays.isNotEmpty) 'selected_days': selectedDays,
    if (consecutiveAsOne) 'consecutive_as_one_period': true,
    if (yearlyDates.isNotEmpty) 'yearly_dates': yearlyDates.map((d) => d.toJson()).toList(),
    'expected_entries': expectedEntries,
    if (hasTimeWindow) ...{
      'has_time_window': true,
      'time_type': timeType,
      if (windowStart != null) 'window_start': windowStart,
      if (windowEnd != null) 'window_end': windowEnd,
      if (windowStartOffset != 0) 'window_start_offset': windowStartOffset,
      if (windowEndOffset != 0) 'window_end_offset': windowEndOffset,
    },
    if (frequency == 'custom') ...{
      'custom_interval': customInterval,
      'custom_unit': customUnit,
    },
  };

  factory ScheduleState.fromJson(Map<String, dynamic> json) {
    return ScheduleState(
      frequency: json['frequency'] as String? ?? 'daily',
      calendar: json['calendar'] as String? ?? 'gregorian',
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'] as String) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      selectionMode: json['selection_mode'] as String? ?? 'specific',
      selectedDays: (json['selected_days'] as List<dynamic>?)?.cast<int>() ?? [],
      consecutiveAsOne: json['consecutive_as_one_period'] as bool? ?? false,
      yearlyDates: (json['yearly_dates'] as List<dynamic>?)
          ?.map((d) => YearlyDateEntry.fromJson(Map<String, dynamic>.from(d as Map)))
          .toList() ?? [],
      expectedEntries: json['expected_entries'] as String? ?? 'once',
      hasTimeWindow: json['has_time_window'] as bool? ?? false,
      timeType: json['time_type'] as String? ?? 'specific',
      windowStart: json['window_start'] as String?,
      windowEnd: json['window_end'] as String?,
      windowStartOffset: json['window_start_offset'] as int? ?? 0,
      windowEndOffset: json['window_end_offset'] as int? ?? 0,
      customInterval: json['custom_interval'] as int? ?? 1,
      customUnit: json['custom_unit'] as String? ?? 'days',
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SCHEDULE CONFIG SECTION WIDGET
// ═══════════════════════════════════════════════════════════════════

class ScheduleConfigSection extends StatelessWidget {
  final ScheduleState state;
  final bool hijriEnabled;
  final VoidCallback onChanged;
  /// Today's prayer times for preview. Keys: 'Fajr', 'Sunrise', etc.
  /// Values: formatted time strings like '5:12 AM'.
  final Map<String, String> todayPrayerTimes;
  final KitabDateFormat fmt;

  const ScheduleConfigSection({
    super.key,
    required this.state,
    required this.hijriEnabled,
    required this.onChanged,
    this.todayPrayerTimes = const {},
    required this.fmt,
  });

  bool get _isHijri => state.calendar == 'hijri';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Calendar Type ───
        if (hijriEnabled) ...[
          DropdownButtonFormField<String>(
            value: state.calendar,
            decoration: const InputDecoration(labelText: 'Calendar'),
            items: const [
              DropdownMenuItem(value: 'gregorian', child: Text('Gregorian (midnight start)')),
              DropdownMenuItem(value: 'hijri', child: Text('Hijri (sunset start)')),
            ],
            onChanged: (v) { state.calendar = v ?? 'gregorian'; onChanged(); },
          ),
          const SizedBox(height: KitabSpacing.md),
        ],

        // ─── Date Range ───
        Row(
          children: [
            Expanded(child: _DatePickerTile(
              label: 'Starts on',
              date: state.startDate,
              isHijri: _isHijri,
              onPicked: (d) { state.startDate = d; onChanged(); },
              fmt: fmt,
            )),
            const SizedBox(width: KitabSpacing.md),
            Expanded(child: state.endDate != null
                ? _DatePickerTile(
                    label: 'Ends on',
                    date: state.endDate!,
                    isHijri: _isHijri,
                    onPicked: (d) { state.endDate = d; onChanged(); },
                    onClear: () { state.endDate = null; onChanged(); },
                    fmt: fmt,
                  )
                : ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ends on'),
                    subtitle: const Text('Never'),
                    trailing: const Icon(Icons.calendar_today, size: 18, color: KitabColors.gray400),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: state.startDate.add(const Duration(days: 30)),
                        firstDate: state.startDate,
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) { state.endDate = picked; onChanged(); }
                    },
                  ),
            ),
          ],
        ),
        const SizedBox(height: KitabSpacing.md),

        // ─── Frequency ───
        DropdownButtonFormField<String>(
          value: state.frequency,
          decoration: const InputDecoration(labelText: 'Repeat'),
          items: const [
            DropdownMenuItem(value: 'daily', child: Text('Daily')),
            DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
            DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
            DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
            DropdownMenuItem(value: 'custom', child: Text('Custom Interval')),
          ],
          onChanged: (v) {
            state.frequency = v ?? 'daily';
            state.selectedDays = [];
            state.yearlyDates = [];
            state.selectionMode = 'specific';
            state.consecutiveAsOne = false;
            onChanged();
          },
        ),
        const SizedBox(height: KitabSpacing.md),

        // ─── Frequency-specific options ───
        if (state.frequency == 'weekly') _buildWeekly(context),
        if (state.frequency == 'monthly') _buildMonthly(context),
        if (state.frequency == 'yearly') _buildYearly(context),
        if (state.frequency == 'custom') _buildCustom(context),

        const SizedBox(height: KitabSpacing.md),

        // ─── Expected Entries ───
        Text('Expected entries per period:', style: KitabTypography.bodySmall),
        RadioListTile<String>(
          title: const Text('One'), value: 'once', groupValue: state.expectedEntries,
          onChanged: (v) { state.expectedEntries = v ?? 'once'; onChanged(); },
          dense: true, contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<String>(
          title: const Text('Multiple'), value: 'multiple', groupValue: state.expectedEntries,
          onChanged: (v) { state.expectedEntries = v ?? 'once'; onChanged(); },
          dense: true, contentPadding: EdgeInsets.zero,
        ),

        const Divider(),

        // ─── Time Window ───
        SwitchListTile(
          title: const Text('Time Window'),
          subtitle: const Text('Restrict to a specific time range'),
          value: state.hasTimeWindow,
          onChanged: (v) { state.hasTimeWindow = v; onChanged(); },
          contentPadding: EdgeInsets.zero,
        ),

        if (state.hasTimeWindow) _buildTimeWindow(context),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // WEEKLY
  // ═══════════════════════════════════════════════════════════════

  Widget _buildWeekly(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How do you want to track this?', style: KitabTypography.bodySmall.copyWith(color: KitabColors.gray500)),
        const SizedBox(height: KitabSpacing.xs),

        RadioListTile<String>(
          title: const Text('Specific days of the week'),
          value: 'specific', groupValue: state.selectionMode,
          onChanged: (v) { state.selectionMode = v!; onChanged(); },
          dense: true, contentPadding: EdgeInsets.zero,
        ),

        if (state.selectionMode == 'specific') ...[
          Wrap(
            spacing: 6,
            children: [(1, 'Mon'), (2, 'Tue'), (3, 'Wed'), (4, 'Thu'), (5, 'Fri'), (6, 'Sat'), (7, 'Sun')]
                .map((d) => FilterChip(
                      label: Text(d.$2),
                      selected: state.selectedDays.contains(d.$1),
                      onSelected: (sel) {
                        if (sel) state.selectedDays.add(d.$1);
                        else state.selectedDays.remove(d.$1);
                        state.selectedDays.sort();
                        onChanged();
                      },
                    ))
                .toList(),
          ),
          // Consecutive prompt
          if (_hasConsecutiveDays(state.selectedDays, 7)) _buildConsecutivePrompt(),
        ],

        RadioListTile<String>(
          title: const Text('Any day of the week'),
          subtitle: const Text('The whole week is one tracking window'),
          value: 'any', groupValue: state.selectionMode,
          onChanged: (v) { state.selectionMode = v!; state.selectedDays = []; onChanged(); },
          dense: true, contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MONTHLY
  // ═══════════════════════════════════════════════════════════════

  Widget _buildMonthly(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How do you want to track this?', style: KitabTypography.bodySmall.copyWith(color: KitabColors.gray500)),
        const SizedBox(height: KitabSpacing.xs),

        RadioListTile<String>(
          title: const Text('Specific days of the month'),
          value: 'specific', groupValue: state.selectionMode,
          onChanged: (v) { state.selectionMode = v!; onChanged(); },
          dense: true, contentPadding: EdgeInsets.zero,
        ),

        if (state.selectionMode == 'specific') ...[
          // Added days as chips
          if (state.selectedDays.isNotEmpty)
            Wrap(
              spacing: 6, runSpacing: 4,
              children: state.selectedDays.map((d) => Chip(
                label: Text('$d'),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () { state.selectedDays.remove(d); onChanged(); },
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),

          // Add day button
          OutlinedButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add day'),
            onPressed: () => _showDayPicker(context, 1, 31, state.selectedDays),
          ),

          if (state.selectedDays.length >= 2) ...[
            const SizedBox(height: KitabSpacing.xs),
            Text("If a day doesn't exist in a month, the last day is used.",
                style: KitabTypography.caption.copyWith(color: KitabColors.gray400, fontStyle: FontStyle.italic)),
          ],

          // Consecutive prompt
          if (_hasConsecutiveDays(state.selectedDays, 31)) _buildConsecutivePrompt(),
        ],

        RadioListTile<String>(
          title: const Text('Any day of the month'),
          subtitle: const Text('The whole month is one tracking window'),
          value: 'any', groupValue: state.selectionMode,
          onChanged: (v) { state.selectionMode = v!; state.selectedDays = []; onChanged(); },
          dense: true, contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // YEARLY
  // ═══════════════════════════════════════════════════════════════

  Widget _buildYearly(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How do you want to track this?', style: KitabTypography.bodySmall.copyWith(color: KitabColors.gray500)),
        const SizedBox(height: KitabSpacing.xs),

        RadioListTile<String>(
          title: const Text('Specific dates'),
          value: 'specific', groupValue: state.selectionMode,
          onChanged: (v) { state.selectionMode = v!; onChanged(); },
          dense: true, contentPadding: EdgeInsets.zero,
        ),

        if (state.selectionMode == 'specific') ...[
          // Date list
          if (state.yearlyDates.isNotEmpty) ...[
            ...state.yearlyDates.asMap().entries.map((e) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, size: 18, color: KitabColors.primary),
              title: Text(e.value.format(_isHijri), style: KitabTypography.body),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 16, color: KitabColors.error),
                onPressed: () { state.yearlyDates.removeAt(e.key); onChanged(); },
              ),
            )),
          ] else
            Padding(
              padding: const EdgeInsets.only(bottom: KitabSpacing.sm),
              child: Text(
                'No dates added — defaults to the anniversary of the start date each year.',
                style: KitabTypography.caption.copyWith(color: KitabColors.gray400, fontStyle: FontStyle.italic),
              ),
            ),

          // Add buttons
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Day'),
                onPressed: () => _showYearlyDayPicker(context, isRange: false),
              ),
              const SizedBox(width: KitabSpacing.sm),
              OutlinedButton.icon(
                icon: const Icon(Icons.date_range, size: 16),
                label: const Text('Add Range'),
                onPressed: () => _showYearlyDayPicker(context, isRange: true),
              ),
            ],
          ),
        ],

        RadioListTile<String>(
          title: const Text('Any day of the year'),
          subtitle: const Text('The whole year is one tracking window'),
          value: 'any', groupValue: state.selectionMode,
          onChanged: (v) { state.selectionMode = v!; state.yearlyDates = []; onChanged(); },
          dense: true, contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CUSTOM INTERVAL
  // ═══════════════════════════════════════════════════════════════

  Widget _buildCustom(BuildContext context) {
    return Row(
      children: [
        const Text('Every '),
        SizedBox(
          width: 60,
          child: TextField(
            decoration: const InputDecoration(isDense: true),
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: '${state.customInterval}'),
            onChanged: (v) { state.customInterval = int.tryParse(v) ?? 1; onChanged(); },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: state.customUnit,
            decoration: const InputDecoration(isDense: true),
            items: const [
              DropdownMenuItem(value: 'days', child: Text('days')),
              DropdownMenuItem(value: 'weeks', child: Text('weeks')),
              DropdownMenuItem(value: 'months', child: Text('months')),
              DropdownMenuItem(value: 'years', child: Text('years')),
            ],
            onChanged: (v) { state.customUnit = v ?? 'days'; onChanged(); },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TIME WINDOW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTimeWindow(BuildContext context) {
    // Detect midnight crossover
    final hasCrossover = _detectMidnightCrossover();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time type — reset selections when switching
        Row(
          children: [
            Expanded(child: RadioListTile<String>(
              title: const Text('Specific'), value: 'specific', groupValue: state.timeType,
              onChanged: (v) {
                state.timeType = v ?? 'specific';
                state.windowStart = null;
                state.windowEnd = null;
                state.windowStartOffset = 0;
                state.windowEndOffset = 0;
                onChanged();
              },
              dense: true, contentPadding: EdgeInsets.zero,
            )),
            Expanded(child: RadioListTile<String>(
              title: const Text('Dynamic'), value: 'dynamic', groupValue: state.timeType,
              onChanged: (v) {
                state.timeType = v ?? 'dynamic';
                state.windowStart = null;
                state.windowEnd = null;
                state.windowStartOffset = 0;
                state.windowEndOffset = 0;
                onChanged();
              },
              dense: true, contentPadding: EdgeInsets.zero,
            )),
          ],
        ),

        if (state.timeType == 'specific') ...[
          Row(
            children: [
              Expanded(child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Start'),
                subtitle: Text(state.windowStart ?? 'Set time'),
                onTap: () async {
                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (time != null) {
                    state.windowStart = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                    onChanged();
                  }
                },
              )),
              Expanded(child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('End'),
                subtitle: Text(state.windowEnd ?? 'Set time'),
                onTap: () async {
                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (time != null) {
                    state.windowEnd = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                    onChanged();
                  }
                },
              )),
            ],
          ),
        ] else ...[
          // Dynamic time dropdowns with offset
          _buildDynamicTimeRow('From', state.windowStart, state.windowStartOffset,
            (v) { state.windowStart = v; onChanged(); },
            (v) { state.windowStartOffset = v; onChanged(); },
          ),
          const SizedBox(height: KitabSpacing.sm),
          _buildDynamicTimeRow('To', state.windowEnd, state.windowEndOffset,
            (v) { state.windowEnd = v; onChanged(); },
            (v) { state.windowEndOffset = v; onChanged(); },
          ),
        ],

        // Midnight crossover warning
        if (hasCrossover)
          Container(
            margin: const EdgeInsets.only(top: KitabSpacing.sm),
            padding: const EdgeInsets.all(KitabSpacing.sm),
            decoration: BoxDecoration(
              color: KitabColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: KitabColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: KitabColors.warning, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  state.timeType == 'dynamic'
                      ? 'This crosses midnight — expected from ${state.windowStart ?? "start"} today to ${state.windowEnd ?? "end"} tomorrow.'
                      : 'This time window crosses midnight — the activity is expected from ${state.windowStart ?? "start"} today to ${state.windowEnd ?? "end"} tomorrow.',
                  style: KitabTypography.bodySmall.copyWith(color: KitabColors.warning),
                )),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDynamicTimeRow(String label, String? value, int offset,
      ValueChanged<String> onTimeChanged, ValueChanged<int> onOffsetChanged) {
    // Look up today's actual time for the selected prayer
    final todayTime = value != null ? todayPrayerTimes[value] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                value: value,
                decoration: InputDecoration(labelText: label),
                items: _dynamicTimeOptions,
                onChanged: (v) { if (v != null) onTimeChanged(v); },
              ),
            ),
            const SizedBox(width: KitabSpacing.sm),
            Expanded(
              flex: 2,
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Offset',
                  suffixText: 'min',
                  hintText: '0',
                  helperText: offset != 0 ? (offset > 0 ? '+$offset min' : '$offset min') : null,
                ),
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                controller: TextEditingController(text: offset != 0 ? '$offset' : ''),
                onChanged: (v) => onOffsetChanged(int.tryParse(v) ?? 0),
              ),
            ),
          ],
        ),
        // Today's time preview
        if (todayTime != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 2),
            child: Text(
              'Today: $todayTime${offset != 0 ? ' ${offset > 0 ? "+" : ""}${offset}min' : ''}',
              style: KitabTypography.caption.copyWith(color: KitabColors.primary),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// Check if a new yearly date entry overlaps with any existing entries.
  /// Returns an error message string if overlap found, null if OK.
  /// Handles cross-year ranges (e.g., Dhul Hijjah 20 → Muharram 10).
  String? _checkYearlyOverlap(YearlyDateEntry newEntry, List<YearlyDateEntry> existing) {
    final months = _isHijri ? _hijriMonths : _gregorianMonths;
    final newLabel = newEntry.format(_isHijri);

    // Convert to day-of-year integer: month * 100 + day
    final newStart = newEntry.startMonth * 100 + newEntry.startDay;
    final newEnd = newEntry.isRange
        ? newEntry.endMonth! * 100 + newEntry.endDay!
        : newStart;
    final newWraps = newEntry.isRange && newEnd < newStart; // crosses year boundary

    for (final e in existing) {
      final eStart = e.startMonth * 100 + e.startDay;
      final eEnd = e.isRange ? e.endMonth! * 100 + e.endDay! : eStart;
      final eWraps = e.isRange && eEnd < eStart;
      final eLabel = e.format(_isHijri);

      // Exact duplicate check
      if (newStart == eStart && newEnd == eEnd) {
        return '${newEntry.isRange ? "This range" : "This day"} is already added';
      }

      // Overlap check using _dayInRange helper
      // Check if any day of the new entry falls within the existing entry, or vice versa
      if (_rangesOverlap(newStart, newEnd, newWraps, eStart, eEnd, eWraps)) {
        if (!newEntry.isRange) {
          return '${months[newEntry.startMonth - 1]} ${newEntry.startDay} is already within $eLabel';
        } else {
          return '$newLabel overlaps with $eLabel';
        }
      }
    }

    return null;
  }

  /// Check if two yearly ranges overlap, handling cross-year wrap-around.
  bool _rangesOverlap(int aStart, int aEnd, bool aWraps, int bStart, int bEnd, bool bWraps) {
    // Check if a point is inside a range (handles wrap-around)
    bool contains(int point, int rStart, int rEnd, bool wraps) {
      if (wraps) {
        // Wrapping range: point is in range if >= start OR <= end
        return point >= rStart || point <= rEnd;
      } else {
        return point >= rStart && point <= rEnd;
      }
    }

    // Two ranges overlap if any endpoint of one falls inside the other
    if (contains(aStart, bStart, bEnd, bWraps)) return true;
    if (contains(aEnd, bStart, bEnd, bWraps)) return true;
    if (contains(bStart, aStart, aEnd, aWraps)) return true;
    if (contains(bEnd, aStart, aEnd, aWraps)) return true;

    return false;
  }

  /// Consecutive days prompt widget
  Widget _buildConsecutivePrompt() {
    return Container(
      margin: const EdgeInsets.only(top: KitabSpacing.sm),
      padding: const EdgeInsets.all(KitabSpacing.sm),
      decoration: BoxDecoration(
        color: KitabColors.info.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KitabColors.info.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('These days are consecutive. How should they be tracked?',
              style: KitabTypography.bodySmall.copyWith(fontWeight: FontWeight.w500)),
          RadioListTile<bool>(
            title: const Text('Each day separately'),
            value: false, groupValue: state.consecutiveAsOne,
            onChanged: (v) { state.consecutiveAsOne = v ?? false; onChanged(); },
            dense: true, contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<bool>(
            title: const Text('Together as one'),
            value: true, groupValue: state.consecutiveAsOne,
            onChanged: (v) { state.consecutiveAsOne = v ?? false; onChanged(); },
            dense: true, contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  /// Check if selected days contain a consecutive run of 2+ days.
  bool _hasConsecutiveDays(List<int> days, int max) {
    if (days.length < 2) return false;
    final sorted = [...days]..sort();
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i] == sorted[i - 1] + 1) return true;
    }
    return false;
  }

  /// Detect midnight crossover in time window.
  bool _detectMidnightCrossover() {
    if (!state.hasTimeWindow) return false;
    if (state.windowStart == null || state.windowEnd == null) return false;

    if (state.timeType == 'specific') {
      // Compare HH:MM strings
      return state.windowEnd!.compareTo(state.windowStart!) <= 0;
    } else {
      // Dynamic: check prayer time order
      const order = ['Fajr', 'Sunrise', 'Duha', 'Dhuhr', 'Asr', 'Maghrib', 'Isha',
                     '1/3 of Night', 'Middle of Night', '2/3 of Night'];
      final startIdx = order.indexOf(state.windowStart!);
      final endIdx = order.indexOf(state.windowEnd!);
      if (startIdx < 0 || endIdx < 0) return false;
      return endIdx <= startIdx;
    }
  }

  /// Show a simple day number picker dialog.
  void _showDayPicker(BuildContext context, int min, int max, List<int> current) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Day'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: 'Day ($min-$max)', hintText: 'e.g., 15'),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () {
            final day = int.tryParse(controller.text);
            if (day != null && day >= min && day <= max && !current.contains(day)) {
              current.add(day);
              current.sort();
              onChanged();
            }
            Navigator.pop(ctx);
          }, child: const Text('Add')),
        ],
      ),
    );
  }

  /// Show month+day picker for yearly dates.
  void _showYearlyDayPicker(BuildContext context, {required bool isRange}) {
    final months = _isHijri ? _hijriMonths : _gregorianMonths;
    int startMonth = 1, startDay = 1;
    int endMonth = 1, endDay = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isRange ? 'Add Date Range' : 'Add Single Day'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Start month + day
                if (isRange) Text('From:', style: KitabTypography.bodySmall.copyWith(fontWeight: FontWeight.w500)),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        value: startMonth,
                        decoration: const InputDecoration(labelText: 'Month', isDense: true),
                        items: months.asMap().entries.map((e) =>
                            DropdownMenuItem(value: e.key + 1, child: Text(e.value))).toList(),
                        onChanged: (v) => setDialogState(() => startMonth = v ?? 1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Day', isDense: true),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(text: '$startDay'),
                        onChanged: (v) => startDay = int.tryParse(v) ?? 1,
                      ),
                    ),
                  ],
                ),

                if (isRange) ...[
                  const SizedBox(height: KitabSpacing.md),
                  Text('To:', style: KitabTypography.bodySmall.copyWith(fontWeight: FontWeight.w500)),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int>(
                          value: endMonth,
                          decoration: const InputDecoration(labelText: 'Month', isDense: true),
                          items: months.asMap().entries.map((e) =>
                              DropdownMenuItem(value: e.key + 1, child: Text(e.value))).toList(),
                          onChanged: (v) => setDialogState(() => endMonth = v ?? 1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Day', isDense: true),
                          keyboardType: TextInputType.number,
                          controller: TextEditingController(text: '$endDay'),
                          onChanged: (v) { endDay = int.tryParse(v) ?? 1; setDialogState(() {}); },
                        ),
                      ),
                    ],
                  ),

                  // Cross-year warning
                  if (endMonth < startMonth || (endMonth == startMonth && endDay < startDay))
                    Container(
                      margin: const EdgeInsets.only(top: KitabSpacing.sm),
                      padding: const EdgeInsets.all(KitabSpacing.sm),
                      decoration: BoxDecoration(
                        color: KitabColors.info.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: KitabColors.info.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: KitabColors.info, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                            'This range crosses into the next year — from ${months[startMonth - 1]} $startDay to ${months[endMonth - 1]} $endDay of the following year.',
                            style: KitabTypography.caption.copyWith(color: KitabColors.info),
                          )),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(onPressed: () {
              final newEntry = YearlyDateEntry(
                startMonth: startMonth, startDay: startDay,
                endMonth: isRange ? endMonth : null,
                endDay: isRange ? endDay : null,
              );

              // Check for overlaps
              final overlap = _checkYearlyOverlap(newEntry, state.yearlyDates);
              if (overlap != null) {
                KitabToast.error(context, overlap);
                return;
              }

              state.yearlyDates.add(newEntry);
              onChanged();
              Navigator.pop(ctx);
            }, child: const Text('Add')),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> get _dynamicTimeOptions => const [
    DropdownMenuItem(value: 'Fajr', child: Text('Fajr')),
    DropdownMenuItem(value: 'Sunrise', child: Text('Sunrise')),
    DropdownMenuItem(value: 'Duha', child: Text('Duha')),
    DropdownMenuItem(value: 'Dhuhr', child: Text('Dhuhr')),
    DropdownMenuItem(value: 'Asr', child: Text('Asr')),
    DropdownMenuItem(value: 'Maghrib', child: Text('Maghrib / Sunset')),
    DropdownMenuItem(value: 'Isha', child: Text('Isha')),
    DropdownMenuItem(value: '1/3 of Night', child: Text('1/3 of Night')),
    DropdownMenuItem(value: 'Middle of Night', child: Text('Middle of Night')),
    DropdownMenuItem(value: '2/3 of Night', child: Text('2/3 of Night')),
  ];
}

// ═══════════════════════════════════════════════════════════════════
// DATE PICKER TILE (shows Hijri equivalent when in Hijri mode)
// ═══════════════════════════════════════════════════════════════════

class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final bool isHijri;
  final ValueChanged<DateTime> onPicked;
  final VoidCallback? onClear;
  final KitabDateFormat fmt;

  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.isHijri,
    required this.onPicked,
    this.onClear,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final gregorianStr = fmt.fullDate(date);
    String? hijriStr;
    if (isHijri) {
      try {
        final h = HijriCalendar.fromDate(date);
        hijriStr = '${h.hDay} ${_hijriMonths[h.hMonth - 1]} ${h.hYear} AH';
      } catch (_) {
        hijriStr = 'Hijri date unavailable';
      }
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(gregorianStr),
          if (hijriStr != null)
            Text('≈ $hijriStr', style: KitabTypography.caption.copyWith(color: KitabColors.primary)),
        ],
      ),
      trailing: onClear != null
          ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onClear)
          : const Icon(Icons.calendar_today, size: 18, color: KitabColors.gray400),
      onTap: () async {
        DateTime? picked;
        if (isHijri) {
          // Use custom Hijri date picker
          picked = await showHijriDatePicker(
            context: context,
            initialDate: date,
          );
        } else {
          // Standard Gregorian picker
          picked = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
        }
        if (picked != null) onPicked(picked);
      },
    );
  }
}
