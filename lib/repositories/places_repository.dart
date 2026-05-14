import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_ar_navigation/core/constants/api_keys.dart';
import 'package:smart_ar_navigation/models/place_model.dart';

class PlacesRepository {
  static const String _textSearchUrl =
      'https://maps.googleapis.com/maps/api/place/textsearch/json';
  static const String _detailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';

  Future<List<PlaceModel>> searchPlaces(
    String query, {
    LatLng? location,
  }) async {
    if (query.trim().isEmpty) return [];

    final params = <String, String>{
      'query': query,
      'key': googleMapsApiKey,
    };
    if (location != null) {
      params['location'] = '${location.latitude},${location.longitude}';
      params['radius'] = '50000'; // 50 km bias radius
    }

    final uri = Uri.parse(_textSearchUrl).replace(queryParameters: params);

    final response = await http.get(uri);
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (json['status'] != 'OK') return [];

    final results = json['results'] as List<dynamic>;
    return results.take(5).map((r) {
      final loc = r['geometry']['location'];
      return PlaceModel(
        placeId: r['place_id'] as String,
        name: r['name'] as String,
        address: r['formatted_address'] as String? ??
            r['vicinity'] as String? ?? '',
        coordinates: LatLng(
          (loc['lat'] as num).toDouble(),
          (loc['lng'] as num).toDouble(),
        ),
      );
    }).toList();
  }

  Future<PlaceModel> getPlaceDetails(String placeId) async {
    final uri = Uri.parse(_detailsUrl).replace(queryParameters: {
      'place_id': placeId,
      'fields': 'name,formatted_address,geometry',
      'key': googleMapsApiKey,
    });

    final response = await http.get(uri);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final result = json['result'] as Map<String, dynamic>;
    final location = result['geometry']['location'];

    return PlaceModel(
      placeId: placeId,
      name: result['name'] as String,
      address: result['formatted_address'] as String,
      coordinates: LatLng(
        (location['lat'] as num).toDouble(),
        (location['lng'] as num).toDouble(),
      ),
    );
  }
}
