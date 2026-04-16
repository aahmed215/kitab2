// ═══════════════════════════════════════════════════════════════════
// GREETING_SERVICE.DART — 8-Level Priority Greeting
// Priority: Birthday > Eid > New Year > Hijri New Year > Jumu'ah >
// Ramadan > Assalamu Alaikum > Time-of-day.
// See SPEC.md §14.1 for specification.
// ═══════════════════════════════════════════════════════════════════

import '../services/prayer_time_service.dart';

class GreetingService {
  const GreetingService();

  /// Get the appropriate greeting based on 8-level priority.
  String getGreeting({
    DateTime? birthday,
    bool islamicPersonalization = false,
    HijriDate? hijriDate,
    String? userName,
  }) {
    final now = DateTime.now();
    final name = userName != null && userName.isNotEmpty ? ', $userName' : '';

    // 1. Birthday
    if (birthday != null &&
        birthday.month == now.month &&
        birthday.day == now.day) {
      return 'Happy Birthday$name! 🎂';
    }

    if (islamicPersonalization && hijriDate != null) {
      // 2. Eid al-Fitr (Shawwal 1)
      if (hijriDate.monthNumber == 10 && hijriDate.day == 1) {
        return 'Eid Mubarak$name! 🌙';
      }
      // 2. Eid al-Adha (Dhul Hijjah 10)
      if (hijriDate.monthNumber == 12 && hijriDate.day == 10) {
        return 'Eid Mubarak$name! 🐑';
      }

      // 3. Hijri New Year (Muharram 1)
      if (hijriDate.monthNumber == 1 && hijriDate.day == 1) {
        return 'Happy Hijri New Year$name!';
      }

      // 4. Jumu'ah (Friday)
      if (now.weekday == DateTime.friday) {
        return 'Jumu\'ah Mubarak$name!';
      }

      // 5. Ramadan
      if (hijriDate.monthNumber == 9) {
        return 'Ramadan Mubarak$name! 🌙';
      }

      // 6. Assalamu Alaikum
      return 'Assalamu Alaikum$name';
    }

    // 3. Gregorian New Year (Jan 1)
    if (now.month == 1 && now.day == 1) {
      return 'Happy New Year$name! 🎉';
    }

    // 7. Time-of-day
    final hour = now.hour;
    if (hour < 12) return 'Good Morning$name';
    if (hour < 17) return 'Good Afternoon$name';
    return 'Good Evening$name';
  }
}
