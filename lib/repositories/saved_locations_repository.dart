import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_ar_navigation/models/place_model.dart';
import 'package:smart_ar_navigation/services/saved_locations_database.dart';

class SavedLocationsRepository {
  final SavedLocationsDatabase _db;

  SavedLocationsRepository({required SavedLocationsDatabase db}) : _db = db;

  Future<List<PlaceModel>> getAll() async {
    final rows = await _db.getAll();
    return rows
        .map((r) => PlaceModel(
              placeId: r['place_id'] as String,
              name: r['name'] as String,
              address: r['address'] as String,
              coordinates: LatLng(r['lat'] as double, r['lng'] as double),
            ))
        .toList();
  }

  Future<void> save(PlaceModel place) => _db.insert({
        'place_id': place.placeId,
        'name': place.name,
        'address': place.address,
        'lat': place.coordinates.latitude,
        'lng': place.coordinates.longitude,
        'saved_at': DateTime.now().millisecondsSinceEpoch,
      });

  Future<void> remove(String placeId) => _db.delete(placeId);

  Future<bool> isSaved(String placeId) => _db.exists(placeId);
}
