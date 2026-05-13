import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:smart_ar_navigation/models/place_model.dart';
import 'package:smart_ar_navigation/viewmodels/plan_drive_viewmodel.dart';

class PlanDriveController {
  PlaceModel? _lastDestination;
  bool _routeFitted = false;

  void checkDestinationChanged(PlaceModel? destination) {
    if (destination != _lastDestination) {
      _lastDestination = destination;
      _routeFitted = false;
    }
  }

  bool shouldFitRoute(PlanDriveViewModel vm) {
    if (!_routeFitted && vm.routes.isNotEmpty) {
      _routeFitted = true;
      return true;
    }
    return false;
  }

  void resetFit() => _routeFitted = false;

  void fitRoute(MapController mapController, PlanDriveViewModel vm) {
    if (vm.routes.isEmpty) return;
    final points = vm.routes[vm.selectedRouteIndex]
        .polylinePoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();
    if (points.length < 2) return;

    mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.fromLTRB(40, 40, 40, 300),
        maxZoom: 16,
      ),
    );
    if (mapController.camera.zoom < 12) {
      mapController.move(mapController.camera.center, 12.0);
    }
  }
}
