import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_ar_navigation/core/constants/api_keys.dart';
import 'package:smart_ar_navigation/core/utils/route_parser.dart';
import 'package:smart_ar_navigation/models/route_model.dart';

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
}
