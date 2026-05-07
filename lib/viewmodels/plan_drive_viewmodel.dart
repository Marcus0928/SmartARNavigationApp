import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:smart_ar_navigation/models/place_model.dart';
import 'package:smart_ar_navigation/models/route_model.dart';
import 'package:smart_ar_navigation/repositories/places_repository.dart';
import 'package:smart_ar_navigation/repositories/route_repository.dart';
import 'package:smart_ar_navigation/services/location_service.dart';

class PlanDriveViewModel extends ChangeNotifier {
  final PlacesRepository _placesRepository;
  final RouteRepository _routeRepository;
  final LocationService _locationService;

  PlanDriveViewModel({
    required PlacesRepository placesRepository,
    required RouteRepository routeRepository,
    required LocationService locationService,
  })  : _placesRepository = placesRepository,
        _routeRepository = routeRepository,
        _locationService = locationService;

  // ── From ──────────────────────────────────────────────────────────────────
  LatLng? _fromLatLng;
  String _fromLabel = 'Your location';
  List<PlaceModel> _fromResults = [];

  // ── To ────────────────────────────────────────────────────────────────────
  PlaceModel? _destination;
  List<PlaceModel> _toResults = [];

  // ── Route ─────────────────────────────────────────────────────────────────
  List<RouteModel> _routes = [];
  int _selectedRouteIndex = 0;
  bool _isFetching = false;
  String? _error;

  // ── Options ───────────────────────────────────────────────────────────────
  bool _avoidTolls = false;
  bool _avoidHighways = false;

  // ── Getters ───────────────────────────────────────────────────────────────
  LatLng? get fromLatLng => _fromLatLng;
  String get fromLabel => _fromLabel;
  List<PlaceModel> get fromResults => _fromResults;

  PlaceModel? get destination => _destination;
  List<PlaceModel> get toResults => _toResults;

  List<RouteModel> get routes => _routes;
  int get selectedRouteIndex => _selectedRouteIndex;
  RouteModel? get selectedRoute =>
      _routes.isNotEmpty ? _routes[_selectedRouteIndex] : null;
  bool get isFetching => _isFetching;
  String? get error => _error;

  bool get avoidTolls => _avoidTolls;
  bool get avoidHighways => _avoidHighways;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> init() async {
    try {
      _fromLatLng = await _locationService.getCurrentLocation();
      notifyListeners();
    } catch (_) {}
  }

  // ── From field ────────────────────────────────────────────────────────────

  Future<void> searchFrom(String query) async {
    if (query.trim().isEmpty) {
      _fromResults = [];
      notifyListeners();
      return;
    }
    _fromResults = await _placesRepository.searchPlaces(
      query,
      location: _fromLatLng,
    );
    notifyListeners();
  }

  Future<void> selectFrom(PlaceModel place) async {
    _fromLatLng = place.coordinates;
    _fromLabel = place.name;
    _fromResults = [];
    notifyListeners();
    await _maybeFetchRoute();
  }

  void useCurrentLocationFrom(LatLng location) {
    _fromLatLng = location;
    _fromLabel = 'Your location';
    _fromResults = [];
    notifyListeners();
    _maybeFetchRoute();
  }

  void clearFromResults() {
    _fromResults = [];
    notifyListeners();
  }

  // ── To field ──────────────────────────────────────────────────────────────

  Future<void> searchTo(String query) async {
    if (query.trim().isEmpty) {
      _toResults = [];
      notifyListeners();
      return;
    }
    _toResults = await _placesRepository.searchPlaces(
      query,
      location: _fromLatLng,
    );
    notifyListeners();
  }

  Future<void> selectTo(PlaceModel place) async {
    _isFetching = true;
    _toResults = [];
    notifyListeners();

    try {
      _destination = await _placesRepository.getPlaceDetails(place.placeId);
    } catch (_) {
      _destination = place;
    }
    await _maybeFetchRoute();
  }

  void clearTo() {
    _destination = null;
    _routes = [];
    _selectedRouteIndex = 0;
    _isFetching = false;
    _toResults = [];
    _error = null;
    notifyListeners();
  }

  void clearToResults() {
    _toResults = [];
    notifyListeners();
  }

  // ── Route selection ───────────────────────────────────────────────────────

  void selectRoute(int index) {
    if (index < 0 || index >= _routes.length) return;
    _selectedRouteIndex = index;
    notifyListeners();
  }

  // ── Options ───────────────────────────────────────────────────────────────

  void toggleAvoidTolls() {
    _avoidTolls = !_avoidTolls;
    notifyListeners();
    _maybeFetchRoute();
  }

  void toggleAvoidHighways() {
    _avoidHighways = !_avoidHighways;
    notifyListeners();
    _maybeFetchRoute();
  }

  // ── Swap ──────────────────────────────────────────────────────────────────

  Future<void> swapLocations() async {
    if (_destination == null || _fromLatLng == null) return;

    final newFromCoords = _destination!.coordinates;
    final newFromLabel = _destination!.name;
    final newDest = PlaceModel(
      placeId: '',
      name: _fromLabel,
      address: '',
      coordinates: _fromLatLng!,
    );

    _fromLatLng = newFromCoords;
    _fromLabel = newFromLabel;
    _destination = newDest;
    _routes = [];
    _selectedRouteIndex = 0;
    _fromResults = [];
    _toResults = [];
    notifyListeners();

    await _maybeFetchRoute();
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _maybeFetchRoute() async {
    if (_fromLatLng == null || _destination == null) {
      _isFetching = false;
      notifyListeners();
      return;
    }

    _isFetching = true;
    _routes = [];
    _selectedRouteIndex = 0;
    _error = null;
    notifyListeners();

    try {
      _routes = await _routeRepository.getRoute(
        origin: _fromLatLng!,
        destination: _destination!.coordinates,
        avoidTolls: _avoidTolls,
        avoidHighways: _avoidHighways,
      );
    } catch (_) {
      _error = 'Could not find a route.';
      _routes = [];
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }
}
