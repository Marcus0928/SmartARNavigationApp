import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/viewmodels/map_viewmodel.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/location_indicator.dart';

class HomeMapLayer extends StatelessWidget {
  const HomeMapLayer({
    super.key,
    required this.mapController,
    required this.smoothedLoc,
    required this.smoothedHeading,
    required this.currentAccuracy,
    required this.mapVM,
    this.navigationPolyline,
    required this.onTap,
    required this.onMapEvent,
  });

  final MapController mapController;
  final LatLng? smoothedLoc;
  final double smoothedHeading;
  final double? currentAccuracy;
  final MapViewModel mapVM;
  final List<LatLng>? navigationPolyline;
  final void Function(TapPosition, LatLng) onTap;
  final void Function(MapEvent) onMapEvent;

  static const _defaultCenter = LatLng(3.0738, 101.5077);

  @override
  Widget build(BuildContext context) {
    // Use the last-known location as the initial center so the map opens
    // already on the user's position instead of flying from the default.
    final loc = mapVM.currentLocation;
    final initialCenter = loc != null
        ? LatLng(loc.latitude, loc.longitude)
        : _defaultCenter;

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 16,
        onTap: onTap,
        onMapEvent: onMapEvent,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.sunway.smart_ar_navigation',
        ),
        if (smoothedLoc != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: smoothedLoc!,
                radius: (currentAccuracy ?? 30).clamp(10, 300).toDouble(),
                useRadiusInMeter: true,
                color: const Color(0x201A73E8),
                borderColor: const Color(0x601A73E8),
                borderStrokeWidth: 1.5,
              ),
            ],
          ),
        if (smoothedLoc != null)
          MarkerLayer(
            markers: [
              Marker(
                point: smoothedLoc!,
                width: 44,
                height: 44,
                child: LocationIndicator(heading: smoothedHeading),
              ),
            ],
          ),
        if (navigationPolyline != null && navigationPolyline!.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: navigationPolyline!,
                color: primaryColor,
                strokeWidth: 6.0,
                borderColor: Colors.white,
                borderStrokeWidth: 2.0,
              ),
            ],
          )
        else if (mapVM.previewRoutes.isNotEmpty)
          PolylineLayer(
            polylines: [
              // Transparent hit-buffer on unselected routes (wider tap target)
              ...mapVM.previewRoutes.asMap().entries
                  .where((e) => e.key != mapVM.selectedRouteIndex)
                  .map(
                    (e) => Polyline(
                      points: e.value.polylinePoints
                          .map((p) => LatLng(p.latitude, p.longitude))
                          .toList(),
                      color: Colors.transparent,
                      strokeWidth: 20.0,
                    ),
                  ),
              // Unselected routes — visible grey
              ...mapVM.previewRoutes.asMap().entries
                  .where((e) => e.key != mapVM.selectedRouteIndex)
                  .map(
                    (e) => Polyline(
                      points: e.value.polylinePoints
                          .map((p) => LatLng(p.latitude, p.longitude))
                          .toList(),
                      color: const Color(0xFFB0BEC5),
                      strokeWidth: 4.5,
                    ),
                  ),
              // Selected route — highlighted on top
              Polyline(
                points: mapVM.previewRoutes[mapVM.selectedRouteIndex]
                    .polylinePoints
                    .map((p) => LatLng(p.latitude, p.longitude))
                    .toList(),
                color: primaryColor,
                strokeWidth: 6.0,
                borderColor: Colors.white,
                borderStrokeWidth: 2.0,
              ),
            ],
          ),
        if (mapVM.selectedDestination != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(
                  mapVM.selectedDestination!.coordinates.latitude,
                  mapVM.selectedDestination!.coordinates.longitude,
                ),
                width: 40,
                height: 48,
                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
              ),
            ],
          ),
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
            TextSourceAttribution('CARTO'),
          ],
        ),
      ],
    );
  }
}
