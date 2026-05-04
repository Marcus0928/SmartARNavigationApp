import 'package:flutter/foundation.dart';
import 'package:smart_ar_navigation/models/place_model.dart';
import 'package:smart_ar_navigation/repositories/saved_locations_repository.dart';

class SavedLocationsViewModel extends ChangeNotifier {
  final SavedLocationsRepository _repo;

  List<PlaceModel> _locations = [];
  final Set<String> _savedIds = {};

  List<PlaceModel> get locations => List.unmodifiable(_locations);
  int get count => _locations.length;

  bool isSaved(String placeId) => _savedIds.contains(placeId);

  SavedLocationsViewModel({required SavedLocationsRepository repo})
      : _repo = repo {
    _load();
  }

  Future<void> _load() async {
    _locations = await _repo.getAll();
    _savedIds
      ..clear()
      ..addAll(_locations.map((p) => p.placeId));
    notifyListeners();
  }

  Future<void> toggle(PlaceModel place) async {
    if (_savedIds.contains(place.placeId)) {
      await _repo.remove(place.placeId);
      _locations.removeWhere((p) => p.placeId == place.placeId);
      _savedIds.remove(place.placeId);
    } else {
      await _repo.save(place);
      _locations.insert(0, place);
      _savedIds.add(place.placeId);
    }
    notifyListeners();
  }

  Future<void> remove(String placeId) async {
    await _repo.remove(placeId);
    _locations.removeWhere((p) => p.placeId == placeId);
    _savedIds.remove(placeId);
    notifyListeners();
  }
}
