import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_ar_navigation/core/constants/api_keys.dart';
import 'package:smart_ar_navigation/models/place_model.dart';

class PlacesRepository {
  static const String _autocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const String _detailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';

  Future<List<PlaceModel>> searchPlaces(String query) async {
    if (query.length < 3) return [];

    final uri = Uri.parse(_autocompleteUrl).replace(queryParameters: {
      'input': query,
      'key': googleMapsApiKey,
    });

    final response = await http.get(uri);
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (json['status'] != 'OK') return [];

    final predictions = json['predictions'] as List<dynamic>;
    return predictions.take(5).map((p) {
      final formatted = p['structured_formatting'];
      return PlaceModel(
        placeId: p['place_id'] as String,
        name: formatted?['main_text'] as String? ?? p['description'] as String,
        address: p['description'] as String,
        coordinates: const LatLng(0, 0),
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
