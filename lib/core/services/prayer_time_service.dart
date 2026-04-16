// ═══════════════════════════════════════════════════════════════════
// PRAYER_TIME_SERVICE.DART — Aladhan API Integration
// Fetches prayer times and Hijri calendar data.
// Caches 1 month of data per location. Refreshes on >50km move.
// See SPEC.md §2.4 for specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'location_service.dart';

/// Prayer time data for a single day.
class PrayerTimes {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final DateTime midnight;

  const PrayerTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.midnight,
  });

  /// Convert to the map format expected by the Period Engine's prayerTimeResolver.
  Map<String, DateTime> toResolverMap() => {
        'Fajr': fajr,
        'Sunrise': sunrise,
        'Duha': sunrise.add(const Duration(minutes: 15)),
        'Dhuhr': dhuhr,
        'Asr': asr,
        'Maghrib': maghrib,
        'Sunset': maghrib,
        'Isha': isha,
        'Midnight': midnight,
        '1/3 of Night': _nightFraction(1 / 3),
        'Middle of Night': _nightFraction(0.5),
        '2/3 of Night': _nightFraction(2 / 3),
      };

  DateTime _nightFraction(double fraction) {
    final nightDuration = fajr.add(const Duration(days: 1)).difference(maghrib);
    return maghrib.add(nightDuration * fraction);
  }

  factory PrayerTimes.fromAladhan(Map<String, dynamic> timings, DateTime date) {
    DateTime parse(String timeStr) {
      final parts = timeStr.split(' ')[0].split(':');
      return DateTime(
        date.year, date.month, date.day,
        int.parse(parts[0]), int.parse(parts[1]),
      );
    }

    return PrayerTimes(
      fajr: parse(timings['Fajr'] as String),
      sunrise: parse(timings['Sunrise'] as String),
      dhuhr: parse(timings['Dhuhr'] as String),
      asr: parse(timings['Asr'] as String),
      maghrib: parse(timings['Maghrib'] as String),
      isha: parse(timings['Isha'] as String),
      midnight: parse(timings['Midnight'] as String),
    );
  }
}

/// Hijri date information.
class HijriDate {
  final int day;
  final String monthName;
  final int monthNumber;
  final int year;
  final String designation;

  const HijriDate({
    required this.day,
    required this.monthName,
    required this.monthNumber,
    required this.year,
    this.designation = 'AH',
  });

  String get formatted => '$day $monthName $year $designation';

  factory HijriDate.fromAladhan(Map<String, dynamic> hijri) {
    return HijriDate(
      day: int.parse(hijri['day'] as String),
      monthName: (hijri['month'] as Map)['en'] as String,
      monthNumber: (hijri['month'] as Map)['number'] as int,
      year: int.parse(hijri['year'] as String),
      designation: (hijri['designation'] as Map)['abbreviated'] as String,
    );
  }
}

/// Service for fetching prayer times and Hijri calendar.
class PrayerTimeService {
  final Dio _dio;
  final Map<String, PrayerTimes> _cache = {};
  final Map<String, HijriDate> _hijriCache = {};

  PrayerTimeService() : _dio = Dio(BaseOptions(
    baseUrl: 'https://api.aladhan.com/v1',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Get prayer times for a specific date and location.
  Future<PrayerTimes> getPrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    int method = 2, // ISNA
    int school = 0, // Shafi
  }) async {
    final cacheKey = '${date.year}-${date.month}-${date.day}_${latitude.toStringAsFixed(2)}_${longitude.toStringAsFixed(2)}';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final response = await _dio.get(
        '/timings/${date.day}-${date.month}-${date.year}',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'method': method,
          'school': school,
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final timings = data['timings'] as Map<String, dynamic>;
      final prayerTimes = PrayerTimes.fromAladhan(timings, date);

      // Also cache Hijri date
      final hijri = data['date']['hijri'] as Map<String, dynamic>;
      _hijriCache[cacheKey] = HijriDate.fromAladhan(hijri);

      _cache[cacheKey] = prayerTimes;
      return prayerTimes;
    } catch (e) {
      // Fallback: approximate times
      return _fallbackTimes(date);
    }
  }

  /// Get Hijri date for a specific Gregorian date.
  /// Tries Aladhan API first, falls back to local hijri package.
  Future<HijriDate> getHijriDate({
    required DateTime date,
    int adjustment = 0,
  }) async {
    final cacheKey = '${date.year}-${date.month}-${date.day}';

    if (_hijriCache.containsKey(cacheKey)) {
      return _hijriCache[cacheKey]!;
    }

    // Try API first
    try {
      final response = await _dio.get(
        '/gpiToH/${date.day}-${date.month}-${date.year}',
        queryParameters: adjustment != 0 ? {'adjustment': adjustment} : null,
      );

      final hijri = response.data['data']['hijri'] as Map<String, dynamic>;
      final result = HijriDate.fromAladhan(hijri);
      _hijriCache[cacheKey] = result;
      return result;
    } catch (_) {
      // Fallback: use local hijri package
      return _localHijriConversion(date, adjustment);
    }
  }

  /// Local Hijri date computation using the hijri package.
  /// No network needed — works offline.
  HijriDate _localHijriConversion(DateTime date, int adjustment) {
    final hijri = HijriCalendar.fromDate(date);

    final day = hijri.hDay + adjustment;
    final monthNames = [
      '', 'Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani',
      'Jumada al-Ula', 'Jumada al-Thani', 'Rajab', 'Shaban',
      'Ramadan', 'Shawwal', 'Dhul Qadah', 'Dhul Hijjah',
    ];

    final result = HijriDate(
      day: day,
      monthName: monthNames[hijri.hMonth],
      monthNumber: hijri.hMonth,
      year: hijri.hYear,
    );

    _hijriCache['${date.year}-${date.month}-${date.day}'] = result;
    return result;
  }

  /// Fetch and cache a full month of prayer times.
  Future<void> prefetchMonth({
    required double latitude,
    required double longitude,
    required int year,
    required int month,
    int method = 2,
    int school = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/calendar/$year/$month',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'method': method,
          'school': school,
        },
      );

      final days = response.data['data'] as List<dynamic>;
      for (final day in days) {
        final dayMap = day as Map<String, dynamic>;
        final dateMap = dayMap['date']['gregorian'] as Map<String, dynamic>;
        final dateStr = dateMap['date'] as String; // DD-MM-YYYY
        final parts = dateStr.split('-');
        final date = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );

        final timings = dayMap['timings'] as Map<String, dynamic>;
        final cacheKey = '${date.year}-${date.month}-${date.day}_${latitude.toStringAsFixed(2)}_${longitude.toStringAsFixed(2)}';

        _cache[cacheKey] = PrayerTimes.fromAladhan(timings, date);

        final hijri = dayMap['date']['hijri'] as Map<String, dynamic>;
        _hijriCache[cacheKey] = HijriDate.fromAladhan(hijri);
      }
    } catch (e) {
      // Silently fail — individual day requests will be attempted later
    }
  }

  /// Create a prayer time resolver function for the Period Engine.
  Map<String, DateTime> Function(DateTime) createResolver({
    required double latitude,
    required double longitude,
    int method = 2,
    int school = 0,
  }) {
    return (DateTime date) {
      final cacheKey = '${date.year}-${date.month}-${date.day}_${latitude.toStringAsFixed(2)}_${longitude.toStringAsFixed(2)}';
      final cached = _cache[cacheKey];
      if (cached != null) return cached.toResolverMap();

      // Synchronous fallback — async prefetch should have populated cache
      return _fallbackTimes(date).toResolverMap();
    };
  }

  PrayerTimes _fallbackTimes(DateTime date) {
    return PrayerTimes(
      fajr: DateTime(date.year, date.month, date.day, 5, 0),
      sunrise: DateTime(date.year, date.month, date.day, 6, 30),
      dhuhr: DateTime(date.year, date.month, date.day, 12, 30),
      asr: DateTime(date.year, date.month, date.day, 15, 45),
      maghrib: DateTime(date.year, date.month, date.day, 18, 30),
      isha: DateTime(date.year, date.month, date.day, 20, 0),
      midnight: DateTime(date.year, date.month, date.day, 0, 0).add(const Duration(days: 1)),
    );
  }

  void clearCache() {
    _cache.clear();
    _hijriCache.clear();
  }
}

/// Global prayer time service provider.
final prayerTimeServiceProvider = Provider<PrayerTimeService>((ref) {
  return PrayerTimeService();
});

/// Today's Hijri date provider.
final todayHijriDateProvider = FutureProvider<HijriDate?>((ref) async {
  final service = ref.watch(prayerTimeServiceProvider);
  try {
    return await service.getHijriDate(date: DateTime.now());
  } catch (e) {
    return null;
  }
});

/// Today's prayer times using the user's actual location.
/// Returns a map of prayer name → formatted time string.
final todayPrayerTimesProvider = FutureProvider<Map<String, String>>((ref) async {
  final service = ref.watch(prayerTimeServiceProvider);
  final location = ref.watch(userLocationProvider).valueOrNull;

  final now = DateTime.now();
  PrayerTimes times;

  if (location != null) {
    // Use real location
    times = await service.getPrayerTimes(
      latitude: location.latitude,
      longitude: location.longitude,
      date: now,
    );
  } else {
    // Fallback to approximate times
    times = service._fallbackTimes(now);
  }

  String format(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $period';
  }

  return {
    for (final entry in times.toResolverMap().entries) entry.key: format(entry.value),
  };
});
