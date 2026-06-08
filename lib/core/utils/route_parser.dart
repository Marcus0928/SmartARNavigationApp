import 'dart:developer' as dev;

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
      final rawManeuver = step['maneuver'] as String? ?? 'straight';
      final direction = _parseManeuver(rawManeuver);
      turns.add(TurnInstruction(
        direction: direction,
        distanceFromPrev: (step['distance']['value'] as num).toDouble(),
        streetName: _extractStreetName(htmlInstructions),
        position: position,
        maneuver: rawManeuver,
        exitNumber: rawManeuver.contains('roundabout')
            ? _parseRoundaboutExit(step)
            : null,
      ));
    }

    final warnings = (route['warnings'] as List<dynamic>?)
            ?.map((w) => w.toString().toLowerCase())
            .toList() ??
        [];
    dev.log('Route $index warnings: $warnings', name: 'RouteParser');

    // Check warnings array first, then fall back to scanning step instructions
    // (Malaysian highway steps often include "Toll" in html_instructions)
    final stepInstructions = (leg['steps'] as List<dynamic>)
        .map((s) => (s['html_instructions'] as String).toLowerCase())
        .toList();
    dev.log('Route $index step instructions: $stepInstructions', name: 'RouteParser');

    final hasTolls = warnings.any((w) => w.contains('toll')) ||
        stepInstructions.any((s) => s.contains('toll'));

    return RouteModel(
      label: index == 0 ? 'Fastest' : 'Alt $index',
      waypoints: waypoints,
      polylinePoints: polylinePoints,
      turns: turns,
      totalDistance: totalDistance,
      estimatedDuration: estimatedDuration,
      hasTolls: hasTolls,
    );
  }).toList();
}

TurnDirection _parseManeuver(String maneuver) {
  const map = <String, TurnDirection>{
    'turn-left':        TurnDirection.left,
    'turn-right':       TurnDirection.right,
    'keep-left':        TurnDirection.keepLeft,
    'keep-right':       TurnDirection.keepRight,
    'straight':         TurnDirection.forward,
    'uturn-left':       TurnDirection.uTurn,
    'uturn-right':      TurnDirection.uTurn,
    'roundabout-left':  TurnDirection.roundabout,
    'roundabout-right': TurnDirection.roundabout,
    'merge':            TurnDirection.forward,
    'fork-left':        TurnDirection.keepLeft,
    'fork-right':       TurnDirection.keepRight,
    'ramp-left':        TurnDirection.keepLeft,
    'ramp-right':       TurnDirection.keepRight,
  };
  return map[maneuver] ?? TurnDirection.forward;
}

// Strips HTML then extracts the road name that follows "onto", "on", or "toward".
// Only inspects the main instruction text (before any supplementary <div> blocks
// that Google Maps appends, e.g. "Partial result", "Destination on the right").
// Returns null when no keyword is found. Never returns an empty string.
// Truncates to 25 characters with "..." if the name is longer.
String? _extractStreetName(String html) {
  // The main instruction text always precedes the first supplementary <div>.
  final mainHtml = html.split(RegExp(r'<div')).first;
  final text = _stripHtml(mainHtml).trim();
  final match = RegExp(
    r'(?:onto|on|toward)\s+(.+)',
    caseSensitive: false,
  ).firstMatch(text);
  if (match == null) return null;
  final name = match.group(1)!.trim();
  if (name.isEmpty) return null;
  if (name.length <= 25) return name;
  return '${name.substring(0, 25)}...';
}

// Reads the roundabout exit number from the step JSON.
// Prefers the structured 'exit' field; falls back to parsing the ordinal from
// html_instructions (e.g. "take the 3rd exit") when the field is absent —
// common in Malaysian API responses where Google omits the structured field.
int? _parseRoundaboutExit(dynamic step) {
  final direct = step['exit'] as int?;
  if (direct != null) return direct;

  final html = step['html_instructions'] as String? ?? '';
  final text = _stripHtml(html);
  final match = RegExp(
    r'\b(\d+)(?:st|nd|rd|th)\s+exit',
    caseSensitive: false,
  ).firstMatch(text);
  return match != null ? int.tryParse(match.group(1)!) : null;
}

// Replace tags with a space so adjacent words don't merge (e.g. </b><b> → " ").
String _stripHtml(String html) =>
    html.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
