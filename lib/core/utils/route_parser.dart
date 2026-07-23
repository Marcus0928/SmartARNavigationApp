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

    final steps = leg['steps'] as List<dynamic>;
    for (var i = 0; i < steps.length; i++) {
      final step = steps[i] as Map<String, dynamic>;
      final startLoc = step['start_location'];
      final position = LatLng(
        (startLoc['lat'] as num).toDouble(),
        (startLoc['lng'] as num).toDouble(),
      );
      waypoints.add(position);
      final htmlInstructions = step['html_instructions'] as String;
      final rawManeuver = step['maneuver'] as String? ?? 'straight';
      final direction = _parseManeuver(rawManeuver);
      final stepDistance = (step['distance']['value'] as num).toDouble();
      // The last step is never filtered, even when short — Google often
      // emits a short final "turn onto X; destination is on the Y" step
      // when the destination sits close to the last turn, and dropping it
      // would leave the final turn without an arrow or voice announcement.
      final isLastStep = i == steps.length - 1;
      if (stepDistance >= 15.0 || isLastStep) {
        turns.add(TurnInstruction(
          direction: direction,
          distanceFromPrev: stepDistance,
          streetName: _extractStreetName(htmlInstructions),
          position: position,
          maneuver: rawManeuver,
          exitNumber: rawManeuver.contains('roundabout')
              ? _parseRoundaboutExit(step)
              : null,
        ));
      }
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
    'turn-sharp-left':  TurnDirection.left,
    'turn-sharp-right': TurnDirection.right,
    'turn-slight-left': TurnDirection.keepLeft,
    'turn-slight-right':TurnDirection.keepRight,
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
// Returns the full name untouched — any visual truncation for layout must be
// applied at the widget/display layer (Text(overflow: TextOverflow.ellipsis)),
// not here, since this value also feeds voice guidance.
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
  return name;
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
