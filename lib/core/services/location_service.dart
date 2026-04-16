// ═══════════════════════════════════════════════════════════════════
// LOCATION_SERVICE.DART — User Location Management
// Gets, caches, and provides the user's GPS coordinates.
// Used for prayer time calculations.
// Native: geolocator package. Web: browser geolocation API.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';

/// Cached user location (lat/lng).
class UserLocation {
  final double latitude;
  final double longitude;
  final DateTime fetchedAt;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    required this.fetchedAt,
  });

  /// Whether this location is stale (older than 24 hours).
  bool get isStale => DateTime.now().difference(fetchedAt).inHours > 24;

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'fetched_at': fetchedAt.toIso8601String(),
  };

  factory UserLocation.fromJson(Map<String, dynamic> json) => UserLocation(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    fetchedAt: DateTime.tryParse(json['fetched_at'] as String? ?? '') ?? DateTime.now(),
  );
}

/// Location service — handles permission, fetching, and caching.
class LocationService {
  UserLocation? _cached;

  /// Check if location permission is granted.
  Future<bool> isPermissionGranted() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
             permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  /// Request location permission. Returns true if granted.
  Future<bool> requestPermission() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return permission == LocationPermission.always ||
             permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  /// Get the user's current location.
  /// Returns cached location if available and not stale.
  /// Falls back to saved location from user settings.
  Future<UserLocation?> getLocation({bool forceRefresh = false}) async {
    // Return cache if fresh
    if (!forceRefresh && _cached != null && !_cached!.isStale) {
      return _cached;
    }

    try {
      final hasPermission = await isPermissionGranted();
      if (!hasPermission) return _cached;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low, // City-level is fine for prayer times
          timeLimit: Duration(seconds: 10),
        ),
      );

      _cached = UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        fetchedAt: DateTime.now(),
      );

      return _cached;
    } catch (_) {
      return _cached;
    }
  }

  /// Set location from saved settings (loaded on app start).
  void setCachedLocation(UserLocation? location) {
    _cached = location;
  }
}

/// Global location service provider.
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// The user's current location (async, cached).
/// Respects the user's locationMode setting: 'gps', 'manual', or 'off'.
final userLocationProvider = FutureProvider<UserLocation?>((ref) async {
  final settings = ref.watch(userSettingsProvider);
  final locationMode = settings.locationMode;

  // Off mode — no location
  if (locationMode == 'off') return null;

  // Manual mode — use saved city coordinates
  if (locationMode == 'manual') {
    final lat = settings.manualLatitude;
    final lng = settings.manualLongitude;
    if (lat != null && lng != null) {
      return UserLocation(
        latitude: lat,
        longitude: lng,
        fetchedAt: DateTime.now(),
      );
    }
    return null;
  }

  // GPS mode — try device location
  final service = ref.watch(locationServiceProvider);
  final userId = ref.watch(currentUserIdProvider);

  // Try to load saved location from user settings first
  if (userId != 'local-user') {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('settings')
          .eq('id', userId)
          .maybeSingle();

      final settingsData = response?['settings'] as Map<String, dynamic>?;
      if (settingsData != null && settingsData['location'] != null) {
        final saved = UserLocation.fromJson(
          Map<String, dynamic>.from(settingsData['location'] as Map),
        );
        service.setCachedLocation(saved);

        // If saved location is fresh enough, use it
        if (!saved.isStale) return saved;
      }
    } catch (_) {}
  }

  // Try to get fresh location
  final location = await service.getLocation();

  // Save to user settings for next time
  if (location != null && userId != 'local-user') {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('settings')
          .eq('id', userId)
          .maybeSingle();

      final currentSettings = response?['settings'] as Map<String, dynamic>? ?? {};
      currentSettings['location'] = location.toJson();

      await Supabase.instance.client
          .from('users')
          .update({
            'settings': currentSettings,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userId);
    } catch (_) {}
  }

  return location;
});
