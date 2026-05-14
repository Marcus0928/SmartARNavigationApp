import 'package:flutter/foundation.dart';
import 'package:smart_ar_navigation/models/place_model.dart';
import 'package:smart_ar_navigation/repositories/recent_places_repository.dart';

class RecentPlacesViewModel extends ChangeNotifier {
  final RecentPlacesRepository _repo;

  RecentPlacesViewModel(this._repo);

  List<PlaceModel> _places = [];
  List<PlaceModel> get places => _places;

  Future<void> load() async {
    _places = await _repo.getAll();
    notifyListeners();
  }

  Future<void> add(PlaceModel place) async {
    await _repo.add(place);
    _places = await _repo.getAll();
    notifyListeners();
  }

  Future<void> clear() async {
    await _repo.clear();
    _places = [];
    notifyListeners();
  }
}
