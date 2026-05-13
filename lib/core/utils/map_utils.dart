import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart';

import 'package:smart_ar_navigation/core/utils/location_utils.dart';
import 'package:smart_ar_navigation/viewmodels/map_viewmodel.dart';

void handleRouteTap(LatLng tapPoint, MapViewModel mapVM) {
  if (mapVM.previewRoutes.length <= 1) return;
  final tap = gm.LatLng(tapPoint.latitude, tapPoint.longitude);
  double minDist = double.infinity;
  int closestIndex = -1;

  for (int i = 0; i < mapVM.previewRoutes.length; i++) {
    if (i == mapVM.selectedRouteIndex) continue;
    final d = _minDistToPolyline(tap, mapVM.previewRoutes[i].polylinePoints);
    if (d < minDist) {
      minDist = d;
      closestIndex = i;
    }
  }

  if (closestIndex != -1 && minDist < 40.0) mapVM.selectRoute(closestIndex);
}

double _minDistToPolyline(gm.LatLng p, List<gm.LatLng> pts) {
  double min = double.infinity;
  for (int i = 0; i < pts.length - 1; i++) {
    final d = _distToSegment(p, pts[i], pts[i + 1]);
    if (d < min) min = d;
  }
  return min;
}

double _distToSegment(gm.LatLng p, gm.LatLng a, gm.LatLng b) {
  final dab = calculateDistance(a, b);
  if (dab < 1.0) return calculateDistance(p, a);
  final t = (((p.latitude - a.latitude) * (b.latitude - a.latitude) +
              (p.longitude - a.longitude) * (b.longitude - a.longitude)) /
             ((b.latitude - a.latitude) * (b.latitude - a.latitude) +
              (b.longitude - a.longitude) * (b.longitude - a.longitude)))
      .clamp(0.0, 1.0);
  final proj = gm.LatLng(
    a.latitude + t * (b.latitude - a.latitude),
    a.longitude + t * (b.longitude - a.longitude),
  );
  return calculateDistance(p, proj);
}
