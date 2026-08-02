import 'dart:math';

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

    final bounds = LatLngBounds.fromPoints(points);

    // Bottom padding must stay well clear of the map's real rendered
    // height, or CameraFit.bounds' internal size calculation goes
    // degenerate (size≈0) and corrupts both zoom and center.
    final availableHeight = mapController.camera.nonRotatedSize.y;
    final bottomPadding = min(300.0, availableHeight * 0.4);

    mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: EdgeInsets.fromLTRB(40, 40, 40, bottomPadding),
        maxZoom: 16,
      ),
    );
    if (mapController.camera.zoom < 12) {
      // Recompute center from the real route bounds rather than reusing
      // camera.center, which may have been corrupted by the degenerate
      // fit above.
      mapController.move(bounds.center, 12.0);
    }
  }
}
