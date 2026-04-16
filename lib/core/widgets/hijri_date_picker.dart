// ═══════════════════════════════════════════════════════════════════
// HIJRI_DATE_PICKER.DART — Custom Hijri Calendar Date Picker
// Browse by Hijri year/month, tap a day, see Gregorian equivalent.
// Returns a Gregorian DateTime for storage.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import '../theme/kitab_theme.dart';

const _hijriMonthNames = [
  'Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani',
  'Jumada al-Ula', 'Jumada al-Thani', 'Rajab', 'Shaban',
  'Ramadan', 'Shawwal', 'Dhul Qadah', 'Dhul Hijjah',
];

/// Shows a Hijri calendar date picker dialog.
/// Returns the selected date as a Gregorian [DateTime], or null if cancelled.
Future<DateTime?> showHijriDatePicker({
  required BuildContext context,
  DateTime? initialDate,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (ctx) => _HijriDatePickerDialog(initialDate: initialDate),
  );
}

class _HijriDatePickerDialog extends StatefulWidget {
  final DateTime? initialDate;
  const _HijriDatePickerDialog({this.initialDate});

  @override
  State<_HijriDatePickerDialog> createState() => _HijriDatePickerDialogState();
}

class _HijriDatePickerDialogState extends State<_HijriDatePickerDialog> {
  late int _hijriYear;
  late int _hijriMonth;
  int? _selectedDay;
  DateTime? _selectedGregorian;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate ?? DateTime.now();
    final hijri = HijriCalendar.fromDate(initial);
    _hijriYear = hijri.hYear;
    _hijriMonth = hijri.hMonth;
    _selectedDay = hijri.hDay;
    _selectedGregorian = initial;
  }

  /// Get the number of days in a Hijri month.
  int _daysInMonth(int year, int month) {
    try {
      // Convert 1st of this month and 1st of next month to Gregorian
      // The difference gives us the month length
      final thisMonth = HijriCalendar().hijriToGregorian(year, month, 1);
      int nextMonth = month + 1;
      int nextYear = year;
      if (nextMonth > 12) { nextMonth = 1; nextYear++; }
      final nextMonthFirst = HijriCalendar().hijriToGregorian(nextYear, nextMonth, 1);
      return nextMonthFirst.difference(thisMonth).inDays;
    } catch (_) {
      return 30; // Hijri months are 29 or 30 days
    }
  }

  /// Convert a Hijri date to Gregorian.
  DateTime? _hijriToGregorian(int year, int month, int day) {
    try {
      return HijriCalendar().hijriToGregorian(year, month, day);
    } catch (_) {
      return null;
    }
  }

  /// Get the weekday (1=Mon..7=Sun) of the 1st of the current Hijri month.
  int _firstDayWeekday() {
    final greg = _hijriToGregorian(_hijriYear, _hijriMonth, 1);
    if (greg == null) return 1;
    return greg.weekday; // 1=Monday, 7=Sunday
  }

  void _selectDay(int day) {
    final greg = _hijriToGregorian(_hijriYear, _hijriMonth, day);
    setState(() {
      _selectedDay = day;
      _selectedGregorian = greg;
    });
  }

  void _previousMonth() {
    setState(() {
      _hijriMonth--;
      if (_hijriMonth < 1) {
        _hijriMonth = 12;
        _hijriYear--;
      }
      _selectedDay = null;
      _selectedGregorian = null;
    });
  }

  void _nextMonth() {
    setState(() {
      _hijriMonth++;
      if (_hijriMonth > 12) {
        _hijriMonth = 1;
        _hijriYear++;
      }
      _selectedDay = null;
      _selectedGregorian = null;
    });
  }

  void _previousYear() {
    setState(() {
      _hijriYear--;
      _selectedDay = null;
      _selectedGregorian = null;
    });
  }

  void _nextYear() {
    setState(() {
      _hijriYear++;
      _selectedDay = null;
      _selectedGregorian = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = _daysInMonth(_hijriYear, _hijriMonth);
    final firstWeekday = _firstDayWeekday();
    // Adjust so Sunday = 0 for grid alignment
    final startOffset = (firstWeekday % 7); // Sun=0, Mon=1, ..., Sat=6

    return AlertDialog(
      title: const Text('Select Hijri Date'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Year selector ───
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousYear,
                ),
                Text(
                  '$_hijriYear AH',
                  style: KitabTypography.h3.copyWith(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextYear,
                ),
              ],
            ),

            // ─── Month selector ───
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: _previousMonth,
                ),
                Expanded(
                  child: DropdownButton<int>(
                    value: _hijriMonth,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: List.generate(12, (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text(_hijriMonthNames[i], textAlign: TextAlign.center),
                    )),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _hijriMonth = v;
                          _selectedDay = null;
                          _selectedGregorian = null;
                        });
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: _nextMonth,
                ),
              ],
            ),
            const SizedBox(height: KitabSpacing.sm),

            // ─── Day headers ───
            Row(
              children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(d,
                              style: KitabTypography.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: d == 'Fr' ? KitabColors.primary : null)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: KitabSpacing.xs),

            // ─── Day grid ───
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: startOffset + daysInMonth,
              itemBuilder: (context, index) {
                if (index < startOffset) {
                  return const SizedBox.shrink(); // Empty cells before 1st
                }
                final day = index - startOffset + 1;
                final isSelected = day == _selectedDay;

                return GestureDetector(
                  onTap: () => _selectDay(day),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? KitabColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? Colors.white : null,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: KitabSpacing.md),

            // ─── Gregorian equivalent ───
            if (_selectedGregorian != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: KitabColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('≈ ', style: TextStyle(color: KitabColors.primary)),
                    Text(
                      DateFormat('MMMM d, yyyy').format(_selectedGregorian!),
                      style: KitabTypography.body.copyWith(color: KitabColors.primary),
                    ),
                    const Text(' (Gregorian)', style: TextStyle(color: KitabColors.gray500, fontSize: 12)),
                  ],
                ),
              )
            else
              Text(
                'Tap a day to select',
                style: KitabTypography.bodySmall.copyWith(color: KitabColors.gray400),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedGregorian != null
              ? () => Navigator.pop(context, _selectedGregorian)
              : null,
          child: const Text('Select'),
        ),
      ],
    );
  }
}
