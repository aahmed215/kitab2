// ═══════════════════════════════════════════════════════════════════
// MAP_LOCATION_PICKER.DART — Reusable Location Picker
// 3 modes: current GPS, pin on map, search by address/name.
// Uses flutter_map + OpenStreetMap (free, no API key).
// Returns coordinates + friendly display name.
// ═══════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../services/geocoding_service.dart';
import '../theme/kitab_theme.dart';
import 'kitab_toast.dart';

/// The result of a location pick.
class PickedLocation {
  final double latitude;
  final double longitude;
  final String displayName;

  const PickedLocation({
    required this.latitude,
    required this.longitude,
    required this.displayName,
  });
}

/// Shows a full-screen location picker dialog.
/// Returns [PickedLocation] or null if cancelled.
Future<PickedLocation?> showMapLocationPicker({
  required BuildContext context,
  double? initialLat,
  double? initialLng,
}) {
  return Navigator.push<PickedLocation>(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _MapLocationPickerScreen(
        initialLat: initialLat,
        initialLng: initialLng,
      ),
    ),
  );
}

class _MapLocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const _MapLocationPickerScreen({this.initialLat, this.initialLng});

  @override
  State<_MapLocationPickerScreen> createState() => _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<_MapLocationPickerScreen> {
  final _mapController = MapController();
  final _searchController = TextEditingController();

  LatLng? _selectedPoint;
  String _displayName = '';
  bool _loading = false;
  bool _searching = false;
  List<LocationResult> _searchResults = [];
  Timer? _searchDebounce;

  // Default center: roughly center of the world
  LatLng get _center => _selectedPoint ??
      LatLng(widget.initialLat ?? 25.0, widget.initialLng ?? 45.0);

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedPoint = LatLng(widget.initialLat!, widget.initialLng!);
      _resolveAddress();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  /// Reverse geocode the selected point to get a display name.
  Future<void> _resolveAddress() async {
    if (_selectedPoint == null) return;
    final name = await GeocodingService.reverseGeocode(
        _selectedPoint!.latitude, _selectedPoint!.longitude);
    if (mounted) setState(() => _displayName = name);
  }

  /// Mode 1: Use current GPS location.
  Future<void> _useCurrentLocation() async {
    setState(() => _loading = true);
    try {
      final hasPermission = await Geolocator.checkPermission();
      if (hasPermission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final point = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedPoint = point;
        _loading = false;
      });
      _mapController.move(point, 15);
      _resolveAddress();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        KitabToast.error(context, 'Could not get location: $e');
      }
    }
  }

  /// Mode 2: Tap on map to place pin.
  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedPoint = point;
      _displayName = 'Loading...';
      _searchResults = [];
      _searchController.clear();
    });
    _resolveAddress();
  }

  /// Mode 3: Search by address/name.
  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() { _searchResults = []; _searching = false; });
      return;
    }

    setState(() => _searching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 600), () async {
      final results = await GeocodingService.searchPlace(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _searching = false;
        });
      }
    });
  }

  void _selectSearchResult(LocationResult result) {
    final point = LatLng(result.latitude, result.longitude);
    setState(() {
      _selectedPoint = point;
      _displayName = result.displayName;
      _searchResults = [];
      _searchController.text = result.displayName;
    });
    _mapController.move(point, 15);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location', style: KitabTypography.h2),
        actions: [
          if (_selectedPoint != null)
            TextButton(
              onPressed: () => Navigator.pop(context, PickedLocation(
                latitude: _selectedPoint!.latitude,
                longitude: _selectedPoint!.longitude,
                displayName: _displayName,
              )),
              child: const Text('Confirm'),
            ),
        ],
      ),
      body: Column(
        children: [
          // ─── Search bar ───
          Padding(
            padding: const EdgeInsets.all(KitabSpacing.sm),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for a place or address',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2)))
                    : _searchController.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchResults = []);
                            })
                        : null,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // ─── Search results ───
          if (_searchResults.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              margin: const EdgeInsets.symmetric(horizontal: KitabSpacing.sm),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(8),
                boxShadow: KitabShadows.level2,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on, color: KitabColors.primary, size: 20),
                    title: Text(result.displayName, style: KitabTypography.bodySmall),
                    dense: true,
                    onTap: () => _selectSearchResult(result),
                  );
                },
              ),
            ),

          // ─── Map ───
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: _selectedPoint != null ? 15 : 3,
                    onTap: _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.mykitab.kitab',
                      tileProvider: kIsWeb ? CancellableNetworkTileProvider() : null,
                    ),
                    if (_selectedPoint != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedPoint!,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.location_pin, color: KitabColors.error, size: 40),
                          ),
                        ],
                      ),
                  ],
                ),

                // Current location FAB
                Positioned(
                  right: 16,
                  bottom: 100,
                  child: FloatingActionButton.small(
                    heroTag: 'location_gps',
                    onPressed: _loading ? null : _useCurrentLocation,
                    backgroundColor: Colors.white,
                    child: _loading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location, color: KitabColors.primary),
                  ),
                ),
              ],
            ),
          ),

          // ─── Selected location info ───
          if (_selectedPoint != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(KitabSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                border: Border(top: BorderSide(color: KitabColors.gray200)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: KitabColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_displayName,
                            style: KitabTypography.body.copyWith(fontWeight: FontWeight.w500),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_selectedPoint!.latitude.toStringAsFixed(6)}, ${_selectedPoint!.longitude.toStringAsFixed(6)}',
                    style: KitabTypography.caption.copyWith(color: KitabColors.gray400),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A compact map preview widget showing a pinned location.
/// Used inline in forms and cards to show a selected location.
class MapPreview extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? displayName;
  final double height;
  final VoidCallback? onTap;

  const MapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    this.displayName,
    this.height = 150,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: IgnorePointer(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(latitude, longitude),
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.mykitab.kitab',
                      tileProvider: kIsWeb ? CancellableNetworkTileProvider() : null,
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(latitude, longitude),
                          width: 30,
                          height: 30,
                          child: const Icon(Icons.location_pin, color: KitabColors.error, size: 30),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (displayName != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: KitabColors.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(displayName!, style: KitabTypography.caption,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
