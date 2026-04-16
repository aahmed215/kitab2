// ═══════════════════════════════════════════════════════════════════
// DATE_FORMATTER.DART — Centralized Date & Time Formatting
// Reads the user's dateFormat and timeFormat settings and provides
// consistent formatting across the entire app.
// Never use raw DateFormat() in widgets — always use KitabDateFormat.
// ═══════════════════════════════════════════════════════════════════

import 'package:intl/intl.dart';

/// Centralized date/time formatter that respects user settings.
///
/// Date format options:
///   - written_short: Apr 6, 2026
///   - written_long:  April 6, 2026
///   - MM/DD/YYYY:    04/06/2026
///   - DD/MM/YYYY:    06/04/2026
///   - YYYY-MM-DD:    2026-04-06
///
/// Time format options:
///   - 12hr: 3:00 PM
///   - 24hr: 15:00
class KitabDateFormat {
  final String _dateFormat;
  final String _timeFormat;

  const KitabDateFormat({
    String dateFormat = 'written_short',
    String timeFormat = '12hr',
  })  : _dateFormat = dateFormat,
        _timeFormat = timeFormat;

  // ─── Full Date (with year) ───
  // "Apr 6, 2026" / "April 6, 2026" / "04/06/2026" etc.

  String fullDate(DateTime dt) => DateFormat(_fullDatePattern).format(dt);

  // ─── Full Date with Day Name ───
  // "Monday, April 6, 2026" / "Mon, Apr 6, 2026" etc.

  String fullDateWithDay(DateTime dt) =>
      DateFormat('EEEE, ${_fullDatePattern}').format(dt);

  String shortDateWithDay(DateTime dt) =>
      DateFormat('EEE, ${_fullDatePattern}').format(dt);

  // ─── Short Date (no year) ───
  // "Apr 6" / "April 6" / "04/06" etc.

  String shortDate(DateTime dt) => DateFormat(_shortDatePattern).format(dt);

  // ─── Short Date with Day Name ───
  // "Mon, Apr 6" / "Monday, April 6" etc.

  String shortDateWithDayName(DateTime dt) =>
      DateFormat('EEE, ${_shortDatePattern}').format(dt);

  String longDateWithDayName(DateTime dt) =>
      DateFormat('EEEE, ${_shortDatePattern}').format(dt);

  // ─── Month + Day (for day separators, labels) ───
  // "April 6" / "Apr 6" etc.

  String monthDay(DateTime dt) => DateFormat(_monthDayPattern).format(dt);

  // ─── Month + Year ───
  // "Apr 2026" / "April 2026" etc.

  String monthYear(DateTime dt) {
    switch (_dateFormat) {
      case 'written_long':
        return DateFormat('MMMM yyyy').format(dt);
      default:
        return DateFormat('MMM yyyy').format(dt);
    }
  }

  // ─── Time ───
  // "3:00 PM" / "15:00"

  String time(DateTime dt) => DateFormat(_timePattern).format(dt);

  // ─── Time with Seconds ───
  // "3:00:45 PM" / "15:00:45"

  String timeWithSeconds(DateTime dt) =>
      DateFormat(_timeWithSecondsPattern).format(dt);

  // ─── Date + Time Combos ───
  // "Mon, Apr 6 — 3:00 PM"

  String shortDateWithTime(DateTime dt) =>
      '${shortDateWithDayName(dt)} — ${time(dt)}';

  // "Mon, Apr 6, 2026 — 3:00 PM"
  String fullDateWithTime(DateTime dt) =>
      '${shortDateWithDay(dt)} — ${time(dt)}';

  // ─── Time Range ───
  // "3:00 PM — 4:00 PM" / "15:00 — 16:00"

  String timeRange(DateTime start, DateTime end) =>
      '${time(start)} – ${time(end)}';

  // ─── Private: Pattern Builders ───

  String get _fullDatePattern {
    switch (_dateFormat) {
      case 'written_long':
        return 'MMMM d, yyyy';
      case 'MM/DD/YYYY':
        return 'MM/dd/yyyy';
      case 'DD/MM/YYYY':
        return 'dd/MM/yyyy';
      case 'YYYY-MM-DD':
        return 'yyyy-MM-dd';
      case 'written_short':
      default:
        return 'MMM d, yyyy';
    }
  }

  String get _shortDatePattern {
    switch (_dateFormat) {
      case 'written_long':
        return 'MMMM d';
      case 'MM/DD/YYYY':
        return 'MM/dd';
      case 'DD/MM/YYYY':
        return 'dd/MM';
      case 'YYYY-MM-DD':
        return 'MM-dd';
      case 'written_short':
      default:
        return 'MMM d';
    }
  }

  String get _monthDayPattern {
    switch (_dateFormat) {
      case 'written_long':
        return 'MMMM d';
      case 'MM/DD/YYYY':
      case 'DD/MM/YYYY':
      case 'YYYY-MM-DD':
        return 'MMM d'; // Always readable for labels
      case 'written_short':
      default:
        return 'MMM d';
    }
  }

  String get _timePattern {
    switch (_timeFormat) {
      case '24hr':
        return 'HH:mm';
      case '12hr':
      default:
        return 'h:mm a';
    }
  }

  String get _timeWithSecondsPattern {
    switch (_timeFormat) {
      case '24hr':
        return 'HH:mm:ss';
      case '12hr':
      default:
        return 'h:mm:ss a';
    }
  }
}
