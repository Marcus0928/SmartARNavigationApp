import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_ar_navigation/core/constants/api_keys.dart';
import 'package:smart_ar_navigation/core/enums/traffic_severity.dart';
import 'package:smart_ar_navigation/core/utils/location_utils.dart';
import 'package:smart_ar_navigation/core/utils/route_parser.dart';
import 'package:smart_ar_navigation/models/route_model.dart';
import 'package:smart_ar_navigation/models/traffic_segment_info.dart';

class RouteNotFoundException implements Exception {
  final String message;
  const RouteNotFoundException(this.message);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
}

class RouteRepository {
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  // Delay-ratio thresholds for classifying traffic severity over the
  // lookahead segment checked by getTrafficSeverityAhead().
  static const double _moderateDelayRatio = 0.2;
  static const double _heavyDelayRatio = 0.5;

  // How far ahead along the route getTrafficSeverityAhead() checks.
  static const double _lookaheadMetres = 2000.0;

  Future<List<RouteModel>> getRoute({
    required LatLng origin,
    required LatLng destination,
    bool avoidTolls = false,
    bool avoidHighways = false,
    double? heading,
  }) async {
    final params = <String, String>{
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'mode': 'driving',
      'alternatives': 'true',
      'departure_time': 'now',
      'key': googleMapsApiKey,
      if (heading != null) 'heading': heading.round().toString(),
    };

    final avoid = <String>[
      if (avoidTolls) 'tolls',
      if (avoidHighways) 'highways',
    ];
    if (avoid.isNotEmpty) params['avoid'] = avoid.join('|');

    final uri = Uri.parse(_baseUrl).replace(queryParameters: params);

    late http.Response response;
    try {
      response = await http.get(uri);
    } catch (_) {
      throw const NetworkException('No internet connection.');
    }

    if (response.statusCode != 200) {
      throw NetworkException('HTTP error ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (json['status'] != 'OK') {
      throw RouteNotFoundException('No route found: ${json['status']}');
    }

    return parseRouteResponse(json);
  }

  /// Checks live traffic conditions over the next ~2 km of the active route.
  ///
  /// Walks [remainingPolyline] forward from [currentLocation] to find the
  /// point approximately 2 km ahead, then asks the Directions API for that
  /// short segment's traffic-aware duration (duration_in_traffic) versus its
  /// free-flow duration (duration), and classifies the delay.
  ///
  /// Best-effort, like the existing faster-route background check in
  /// NavigationViewModel: returns null on any network/parsing failure, and
  /// also returns null when the delay isn't significant (delayRatio < 0.2)
  /// rather than throwing — callers aren't meant to treat "no traffic info"
  /// as an error.
  Future<TrafficSegmentInfo?> getTrafficSeverityAhead({
    required LatLng currentLocation,
    required List<LatLng> remainingPolyline,
  }) async {
    final segmentEnd = _pointAhead(
      currentLocation,
      remainingPolyline,
      _lookaheadMetres,
    );
    if (segmentEnd == null) return null;

    final params = <String, String>{
      'origin': '${currentLocation.latitude},${currentLocation.longitude}',
      'destination': '${segmentEnd.latitude},${segmentEnd.longitude}',
      'mode': 'driving',
      'departure_time': 'now',
      'key': googleMapsApiKey,
    };
    final uri = Uri.parse(_baseUrl).replace(queryParameters: params);

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['status'] != 'OK') return null;

      final routes = json['routes'] as List<dynamic>;
      if (routes.isEmpty) return null;
      final leg = (routes.first as Map<String, dynamic>)['legs'][0]
          as Map<String, dynamic>;

      final duration = (leg['duration']['value'] as num).toDouble();
      final durationInTraffic = leg.containsKey('duration_in_traffic')
          ? (leg['duration_in_traffic']['value'] as num).toDouble()
          : duration;
      if (duration <= 0) return null;

      final delayRatio = (durationInTraffic - duration) / duration;
      if (delayRatio < _moderateDelayRatio) return null;

      final delayMinutes = ((durationInTraffic - duration) / 60).round();
      final severity = delayRatio > _heavyDelayRatio
          ? TrafficSeverity.heavy
          : TrafficSeverity.moderate;

      return TrafficSegmentInfo(
        delayMinutes: delayMinutes,
        segmentStartPosition: currentLocation,
        segmentEndPosition: segmentEnd,
        severity: severity,
      );
    } catch (_) {
      // Best-effort — silently ignore network/parsing errors.
      return null;
    }
  }

  // Walks [polyline] forward from [start], accumulating distance, and
  // returns the first point at which cumulative distance reaches
  // [targetDistance]. Clamps to the last polyline point when the remaining
  // route is shorter than [targetDistance]. Returns null for an empty
  // polyline (nothing to check ahead).
  LatLng? _pointAhead(
    LatLng start,
    List<LatLng> polyline,
    double targetDistance,
  ) {
    if (polyline.isEmpty) return null;

    double cumulative = 0.0;
    LatLng previous = start;
    for (final point in polyline) {
      cumulative += calculateDistance(previous, point);
      if (cumulative >= targetDistance) return point;
      previous = point;
    }
    return polyline.last;
  }
}
