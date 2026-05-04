import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_ar_navigation/core/enums/turn_direction.dart';
import 'package:smart_ar_navigation/models/route_model.dart';
import 'package:smart_ar_navigation/models/turn_instruction.dart';

List<RouteModel> parseRouteResponse(Map<String, dynamic> json) {
  final routes = json['routes'] as List<dynamic>;
  return routes.asMap().entries.map((entry) {
    final index = entry.key;
    final route = entry.value as Map<String, dynamic>;
    final leg = route['legs'][0] as Map<String, dynamic>;

    final totalDistance = (leg['distance']['value'] as num).toDouble();
    // Prefer traffic-aware duration when available (requires departure_time=now)
    final durationField = leg.containsKey('duration_in_traffic')
        ? leg['duration_in_traffic']
        : leg['duration'];
    final estimatedDuration = durationField['value'] as int;

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
      final htmlInstructions = step['html_instructions'] as String;
      final direction = _parseManeuver(step['maneuver'] as String?);
      turns.add(TurnInstruction(
        direction: direction,
        distanceFromPrev: (step['distance']['value'] as num).toDouble(),
        streetName: _extractStreetName(htmlInstructions),
        position: position,
        exitNumber: direction == TurnDirection.roundabout
            ? _extractExitNumber(htmlInstructions)
            : null,
      ));
    }

    return RouteModel(
      label: index == 0 ? 'Fastest' : 'Alt $index',
      waypoints: waypoints,
      polylinePoints: polylinePoints,
      turns: turns,
      totalDistance: totalDistance,
      estimatedDuration: estimatedDuration,
    );
  }).toList();
}

TurnDirection _parseManeuver(String? maneuver) {
  switch (maneuver) {
    case 'turn-left':
    case 'turn-sharp-left':
      return TurnDirection.left;
    case 'turn-right':
    case 'turn-sharp-right':
      return TurnDirection.right;
    case 'turn-slight-left':
    case 'keep-left':
    case 'ramp-left':
    case 'fork-left':
      return TurnDirection.keepLeft;
    case 'turn-slight-right':
    case 'keep-right':
    case 'ramp-right':
    case 'fork-right':
      return TurnDirection.keepRight;
    case 'uturn-left':
    case 'uturn-right':
      return TurnDirection.uTurn;
    case 'roundabout-left':
    case 'roundabout-right':
      return TurnDirection.roundabout;
    default:
      return TurnDirection.forward;
  }
}

// Returns the road name from the first bold tag that isn't an ordinal or compass direction.
// Google Maps wraps both the compass word ("northwest") and the road name in <b> tags on
// "Head <b>northwest</b> on <b>Jalan ABC</b>" steps — we skip the direction word.
// Falls back to the full stripped text when no suitable bold tag exists.
String _extractStreetName(String html) {
  final ordinal = RegExp(r'^\d+(st|nd|rd|th)$', caseSensitive: false);
  const compassWords = {
    'north', 'south', 'east', 'west',
    'northeast', 'northwest', 'southeast', 'southwest',
  };
  for (final m in RegExp(r'<b>(.*?)</b>').allMatches(html)) {
    final text = _stripHtml(m.group(1)!); // strip nested tags like <wbr/>
    if (ordinal.hasMatch(text)) continue;
    if (compassWords.contains(text.toLowerCase())) continue;
    return text;
  }
  return _stripHtml(html);
}

int? _extractExitNumber(String html) {
  final text = _stripHtml(html);
  final match = RegExp(
    r'(\d+)(?:st|nd|rd|th)\s+exit',
    caseSensitive: false,
  ).firstMatch(text);
  return match != null ? int.tryParse(match.group(1)!) : null;
}

String _stripHtml(String html) =>
    html.replaceAll(RegExp(r'<[^>]*>'), '');
