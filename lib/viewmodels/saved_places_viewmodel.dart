import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_ar_navigation/models/place_model.dart';
import 'package:smart_ar_navigation/repositories/places_repository.dart';

enum SavedPlaceType { home, work, favourite }

class SavedPlacesViewModel extends ChangeNotifier {
  static const _keyHome = 'saved_place_home';
  static const _keyWork = 'saved_place_work';
  static const _keyFavourite = 'saved_place_favourite';

  final PlacesRepository _placesRepository;

  PlaceModel? _home;
  PlaceModel? _work;
  PlaceModel? _favourite;
  List<PlaceModel> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounce;

  PlaceModel? get home => _home;
  PlaceModel? get work => _work;
  PlaceModel? get favourite => _favourite;
  List<PlaceModel> get searchResults => _searchResults;
  bool get isSearching => _isSearching;

  PlaceModel? getPlace(SavedPlaceType type) => switch (type) {
        SavedPlaceType.home => _home,
        SavedPlaceType.work => _work,
        SavedPlaceType.favourite => _favourite,
      };

  SavedPlacesViewModel({required PlacesRepository placesRepository})
      : _placesRepository = placesRepository {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _home = _decode(prefs.getString(_keyHome));
    _work = _decode(prefs.getString(_keyWork));
    _favourite = _decode(prefs.getString(_keyFavourite));
    notifyListeners();
  }

  void searchPlace(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }
    _isSearching = true;
    notifyListeners();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        _searchResults = await _placesRepository.searchPlaces(query);
      } finally {
        _isSearching = false;
        notifyListeners();
      }
    });
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> selectAndSavePlace(SavedPlaceType type, PlaceModel place) async {
    await _savePlace(type, place);
  }

  Future<void> _savePlace(SavedPlaceType type, PlaceModel place) async {
    switch (type) {
      case SavedPlaceType.home:
        _home = place;
      case SavedPlaceType.work:
        _work = place;
      case SavedPlaceType.favourite:
        _favourite = place;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFor(type), _encode(place));
  }

  Future<void> clearPlace(SavedPlaceType type) async {
    switch (type) {
      case SavedPlaceType.home:
        _home = null;
      case SavedPlaceType.work:
        _work = null;
      case SavedPlaceType.favourite:
        _favourite = null;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(type));
  }

  String _keyFor(SavedPlaceType type) => switch (type) {
        SavedPlaceType.home => _keyHome,
        SavedPlaceType.work => _keyWork,
        SavedPlaceType.favourite => _keyFavourite,
      };

  PlaceModel? _decode(String? json) {
    if (json == null) return null;
    try {
      final m = jsonDecode(json) as Map<String, dynamic>;
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

  String _encode(PlaceModel p) => jsonEncode({
        'placeId': p.placeId,
        'name': p.name,
        'address': p.address,
        'lat': p.coordinates.latitude,
        'lng': p.coordinates.longitude,
      });
}
