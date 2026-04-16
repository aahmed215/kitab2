// ═══════════════════════════════════════════════════════════════════
// GEOCODING_SERVICE.DART — Address ↔ Coordinates Conversion
// Forward geocoding: address/name → coordinates
// Reverse geocoding: coordinates → friendly address name
// Uses the `geocoding` package on native, Nominatim API on web.
// ═══════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class GeocodingService {
  const GeocodingService._();

  /// Convert coordinates to a friendly address string.
  static Future<String> reverseGeocode(double lat, double lng) async {
    try {
      if (kIsWeb) return _reverseGeocodeWeb(lat, lng);

      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return _coordsFallback(lat, lng);

      final p = placemarks.first;
      final parts = <String>[];
      if (p.name != null && p.name!.isNotEmpty && p.name != p.street) parts.add(p.name!);
      if (p.street != null && p.street!.isNotEmpty) parts.add(p.street!);
      if (p.locality != null && p.locality!.isNotEmpty) parts.add(p.locality!);
      if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) parts.add(p.administrativeArea!);
      if (p.country != null && p.country!.isNotEmpty) parts.add(p.country!);

      if (parts.isEmpty) return _coordsFallback(lat, lng);

      if (parts.length >= 3) {
        return '${parts[0]}, ${parts[parts.length - 2]}, ${parts.last}';
      }
      return parts.join(', ');
    } catch (_) {
      // Native geocoder failed — try web fallback
      try {
        return await _reverseGeocodeWeb(lat, lng);
      } catch (_) {
        return _coordsFallback(lat, lng);
      }
    }
  }

  /// Convert coordinates to a concise location: City, State, Country.
  /// If no state, returns City, Country. Falls back to coordinates.
  static Future<String> reverseGeocodeCity(double lat, double lng) async {
    try {
      if (kIsWeb) return _reverseGeocodeCityWeb(lat, lng);

      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return _reverseGeocodeCityWeb(lat, lng);

      final p = placemarks.first;
      final city = p.locality;
      final state = p.administrativeArea;
      final country = p.country;

      final parts = <String>[];
      if (city != null && city.isNotEmpty) parts.add(city);
      if (state != null && state.isNotEmpty && state != city) parts.add(state);
      if (country != null && country.isNotEmpty) parts.add(country);

      if (parts.isEmpty) return _reverseGeocodeCityWeb(lat, lng);
      return parts.join(', ');
    } catch (_) {
      // Native geocoder failed — try web fallback
      try {
        return await _reverseGeocodeCityWeb(lat, lng);
      } catch (_) {
        return _coordsFallback(lat, lng);
      }
    }
  }

  /// Web-compatible reverse geocoding using Nominatim (OpenStreetMap).
  static Future<String> _reverseGeocodeWeb(double lat, double lng) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=14&addressdetails=1',
    );
    final response = await http.get(url, headers: {
      'User-Agent': 'Kitab-App/1.0',
    });
    if (response.statusCode != 200) return _coordsFallback(lat, lng);

    final data = json.decode(response.body) as Map<String, dynamic>;
    return data['display_name'] as String? ?? _coordsFallback(lat, lng);
  }

  /// Web-compatible City, State, Country from Nominatim.
  static Future<String> _reverseGeocodeCityWeb(double lat, double lng) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=10&addressdetails=1',
    );
    final response = await http.get(url, headers: {
      'User-Agent': 'Kitab-App/1.0',
    });
    if (response.statusCode != 200) return _coordsFallback(lat, lng);

    final data = json.decode(response.body) as Map<String, dynamic>;
    final address = data['address'] as Map<String, dynamic>?;
    if (address == null) return _coordsFallback(lat, lng);

    final city = address['city'] ?? address['town'] ?? address['village'];
    final state = address['state'];
    final country = address['country'];

    final parts = <String>[];
    if (city != null && '$city'.isNotEmpty) parts.add('$city');
    if (state != null && '$state'.isNotEmpty && state != city) parts.add('$state');
    if (country != null && '$country'.isNotEmpty) parts.add('$country');

    if (parts.isEmpty) return _coordsFallback(lat, lng);
    return parts.join(', ');
  }

  static String _coordsFallback(double lat, double lng) =>
      '${lat.toStringAsFixed(4)}°, ${lng.toStringAsFixed(4)}°';

  /// Search for a place by name/address. Returns list of results.
  static Future<List<LocationResult>> searchPlace(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      if (kIsWeb) return _searchPlaceWeb(query);

      final locations = await locationFromAddress(query);
      final results = <LocationResult>[];
      for (final loc in locations) {
        final name = await reverseGeocode(loc.latitude, loc.longitude);
        results.add(LocationResult(
          latitude: loc.latitude,
          longitude: loc.longitude,
          displayName: name,
        ));
      }
      return results;
    } catch (_) {
      // Native geocoder failed — try web fallback
      try {
        return await _searchPlaceWeb(query);
      } catch (_) {
        return [];
      }
    }
  }

  /// Web-compatible forward geocoding using Nominatim.
  static Future<List<LocationResult>> _searchPlaceWeb(String query) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&limit=5&addressdetails=1',
    );
    final response = await http.get(url, headers: {
      'User-Agent': 'Kitab-App/1.0',
    });
    if (response.statusCode != 200) return [];

    final data = json.decode(response.body) as List<dynamic>;
    return data.map((item) {
      final map = item as Map<String, dynamic>;
      return LocationResult(
        latitude: double.parse(map['lat'] as String),
        longitude: double.parse(map['lon'] as String),
        displayName: map['display_name'] as String? ?? '',
      );
    }).toList();
  }
}

class LocationResult {
  final double latitude;
  final double longitude;
  final String displayName;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
  });
}
