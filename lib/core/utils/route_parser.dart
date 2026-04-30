import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_ar_navigation/core/enums/turn_direction.dart';
import 'package:smart_ar_navigation/models/route_model.dart';
import 'package:smart_ar_navigation/models/turn_instruction.dart';

RouteModel parseRouteResponse(Map<String, dynamic> json) {
  final route = json['routes'][0];
  final leg = route['legs'][0];

  final totalDistance = (leg['distance']['value'] as num).toDouble();
  final estimatedDuration = leg['duration']['value'] as int;

  // Decode the full route geometry from the overview polyline.
  final encoded = route['overview_polyline']['points'] as String;
  final polylinePoints = PolylinePoints()
      .decodePolyline(encoded)
      .map((p) => LatLng(p.latitude, p.longitude))
      .toList();

  final List<TurnInstruction> turns = [];
  final List<LatLng> waypoints = [];

  for (final step in leg['steps']) {
    final endLoc = step['end_location'];
    final position = LatLng(
      (endLoc['lat'] as num).toDouble(),
      (endLoc['lng'] as num).toDouble(),
    );

    waypoints.add(position);

    turns.add(TurnInstruction(
      direction: _parseManeuver(step['maneuver'] as String?),
      distanceFromPrev: (step['distance']['value'] as num).toDouble(),
      streetName: _stripHtml(step['html_instructions'] as String),
      position: position,
    ));
  }

  return RouteModel(
    waypoints: waypoints,
    polylinePoints: polylinePoints,
    turns: turns,
    totalDistance: totalDistance,
    estimatedDuration: estimatedDuration,
  );
}

TurnDirection _parseManeuver(String? maneuver) {
  switch (maneuver) {
    case 'turn-left':
      return TurnDirection.left;
    case 'turn-right':
      return TurnDirection.right;
    case 'keep-left':
      return TurnDirection.keepLeft;
    case 'keep-right':
      return TurnDirection.keepRight;
    case 'uturn-left':
    case 'uturn-right':
      return TurnDirection.uTurn;
    default:
      return TurnDirection.forward;
  }
}

String _stripHtml(String html) =>
    html.replaceAll(RegExp(r'<[^>]*>'), '');
