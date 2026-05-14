import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ar_navigation/models/place_model.dart';

class RecentPlacesRepository {
  static const _key = 'recent_places';
  static const _maxCount = 8;

  Future<List<PlaceModel>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? [])
        .map(_decode)
        .whereType<PlaceModel>()
        .toList();
  }

  Future<void> add(PlaceModel place) async {
    final prefs = await SharedPreferences.getInstance();
    var list = (prefs.getStringList(_key) ?? [])
        .map(_decode)
        .whereType<PlaceModel>()
        .toList();
    list.removeWhere((p) => p.placeId == place.placeId);
    list.insert(0, place);
    if (list.length > _maxCount) list = list.sublist(0, _maxCount);
    await prefs.setStringList(_key, list.map(_encode).toList());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  String _encode(PlaceModel p) => jsonEncode({
        'placeId': p.placeId,
        'name': p.name,
        'address': p.address,
        'lat': p.coordinates.latitude,
        'lng': p.coordinates.longitude,
      });

  PlaceModel? _decode(String raw) {
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return PlaceModel(
        placeId: m['placeId'] as String,
        name: m['name'] as String,
        address: m['address'] as String,
        coordinates: LatLng(
          (m['lat'] as num).toDouble(),
          (m['lng'] as num).toDouble(),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
