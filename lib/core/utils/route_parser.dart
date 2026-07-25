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

// Extracts the road name from the <b>...</b> segment Google's Directions API
// puts right after "on"/"onto"/"stay on" — that bold tag is how the API
// visually distinguishes the actual road from any destination/signage list
// that follows (e.g. ", follow signs for Klang/Shah Alam" or "(signs for
// Klang)"), so matching against the raw HTML (before any tag-stripping)
// lets the capture stop cleanly at the closing </b> instead of running into
// that trailing text. Only inspects the main instruction text (before any
// supplementary <div> blocks that Google Maps appends, e.g. "Partial
// result", "Destination on the right"). Never returns an empty string.
//
// Instructions with no named road to leave (the first step of a route,
// or a same-road bearing change like "Slight left"/"Slight right") have no
// "on"/"onto" at all — Google instead writes "toward <b>Road</b>", e.g.
// "Head south toward <b>Jalan Tun Ismail</b>". When the primary match
// fails, _extractTowardFallback() below handles that case, but only when
// the toward-introduced bold text is a single road (optionally with a
// same-road alt-name joined by "/<wbr/>", e.g. "<b>Lebuhraya Damansara -
// Puchong</b>/<wbr/><b>E11</b>") — not a multi-item destination/signage
// list (e.g. "toward <b>E1</b>/<wbr/><b>Ipoh</b>/<wbr/><b>Klang</b>/<wbr/>
// <b>E2</b>/<wbr/><b>KLIA</b>"), which must keep returning null.
String? _extractStreetName(String html) {
  // The main instruction text always precedes the first supplementary <div>.
  final mainHtml = html.split(RegExp(r'<div')).first;
  final match = RegExp(
    r'\bon(?:to)?\b\s*<b>(.*?)</b>',
    caseSensitive: false,
  ).firstMatch(mainHtml);
  if (match != null) {
    final name = _stripHtml(match.group(1)!).trim();
    if (name.isNotEmpty) return name;
  }
  return _extractTowardFallback(mainHtml);
}

// Fallback for instructions with no "on"/"onto" (see _extractStreetName).
// Matches "toward <b>Road</b>" plus up to one immediately-chained
// "/<wbr/><b>...</b>" segment, plus (only to detect and reject) any further
// chained segments beyond that.
//
// A 3rd+ chained segment (e.g. "E1/Ipoh/Klang/E2/KLIA") always means a
// destination/signage list, not a road, and is rejected.
//
// A single chained segment is ambiguous — Google uses the exact same
// "Road</b>/<wbr/><b>X</b>" shape both for one road's route-code alt-name
// (e.g. "Jln Sungai Pusu</b>/<wbr/><b>B38", "Jalan Tambun</b>/<wbr/><b>A13")
// and for a genuine 2-item destination list (e.g. "Ipoh</b>/<wbr/><b>Klang",
// "Klang</b>/<wbr/><b>Shah Alam"). Tested against 926 real Directions API
// steps, blanket-accepting every 2-segment case produced 12 false-positive
// destination lists for only 3 true-positive route-code pairs — so it's
// only accepted when the second segment itself looks like a route code
// (letters+digits, e.g. "A13"/"B38"/"E1"/"AH141", or "Route 2") via
// _looksLikeRouteCode(); a plain place name (e.g. "Klang") is rejected.
String? _extractTowardFallback(String mainHtml) {
  final match = RegExp(
    r'\btoward\b\s*<b>(.*?)</b>((?:/<wbr/><b>.*?</b>)*)',
    caseSensitive: false,
  ).firstMatch(mainHtml);
  if (match == null) return null;

  final chainedSegments = RegExp(r'<b>(.*?)</b>')
      .allMatches(match.group(2)!)
      .map((m) => m.group(1)!)
      .toList();
  if (chainedSegments.length >= 2) return null; // 3+ total segments — a list.
  if (chainedSegments.length == 1 && !_looksLikeRouteCode(chainedSegments.first)) {
    return null; // 2 total segments, 2nd isn't a route code — a 2-item list.
  }

  final name = _stripHtml(match.group(1)!).trim();
  if (name.isEmpty) return null;
  return name;
}

// Malaysian road route codes are short and alphanumeric (e.g. "A13", "B38",
// "E1", "AH141") or the word "Route" followed by a number (e.g. "Route 2").
// Distinguishes a road's route-code alt-name from a second destination in a
// "toward <b>Road</b>/<wbr/><b>X</b>" chain — see _extractTowardFallback().
bool _looksLikeRouteCode(String html) {
  final text = _stripHtml(html).trim();
  return RegExp(
    r'^(?:Route\s*\d+|[A-Za-z]{1,3}\d+[A-Za-z]?)$',
    caseSensitive: false,
  ).hasMatch(text);
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
