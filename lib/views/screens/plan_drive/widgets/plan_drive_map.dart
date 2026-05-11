import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/viewmodels/plan_drive_viewmodel.dart';

class PlanDriveMap extends StatelessWidget {
  const PlanDriveMap({
    super.key,
    required this.mapController,
    required this.vm,
  });

  final MapController mapController;
  final PlanDriveViewModel vm;

  static const _defaultCenter = LatLng(3.0738, 101.5077);

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: const MapOptions(
        initialCenter: _defaultCenter,
        initialZoom: 13,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.sunway.smart_ar_navigation',
        ),
        if (vm.routes.isNotEmpty)
          PolylineLayer(
            polylines: [
              // Unselected routes — grey
              ...vm.routes.asMap().entries
                  .where((e) => e.key != vm.selectedRouteIndex)
                  .map(
                    (e) => Polyline(
                      points: e.value.polylinePoints
                          .map((p) => LatLng(p.latitude, p.longitude))
                          .toList(),
                      color: const Color(0xFFB0BEC5),
                      strokeWidth: 4.5,
                    ),
                  ),
              // Selected route — blue with white border
              Polyline(
                points: vm.routes[vm.selectedRouteIndex]
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
        // Destination pin
        if (vm.destination != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(
                  vm.destination!.coordinates.latitude,
                  vm.destination!.coordinates.longitude,
                ),
                width: 40,
                height: 48,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        // Origin dot
        if (vm.fromLatLng != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(
                  vm.fromLatLng!.latitude,
                  vm.fromLatLng!.longitude,
                ),
                width: 22,
                height: 22,
                child: Container(
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
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
