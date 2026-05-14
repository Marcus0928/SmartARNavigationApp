import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:smart_ar_navigation/core/enums/navigation_status.dart';
import 'package:smart_ar_navigation/core/utils/location_utils.dart';
import 'package:smart_ar_navigation/models/place_model.dart';
import 'package:smart_ar_navigation/models/route_model.dart';
import 'package:smart_ar_navigation/repositories/places_repository.dart';
import 'package:smart_ar_navigation/repositories/route_repository.dart';
import 'package:smart_ar_navigation/services/location_service.dart';
import 'package:smart_ar_navigation/viewmodels/ar_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/navigation_viewmodel.dart';

class MapViewModel extends ChangeNotifier {
  final LocationService _locationService;
  final PlacesRepository _placesRepository;
  final RouteRepository _routeRepository;
  final NavigationViewModel _navigationViewModel;
  final ARViewModel _arViewModel;

  MapViewModel({
    required LocationService locationService,
    required PlacesRepository placesRepository,
    required RouteRepository routeRepository,
    required NavigationViewModel navigationViewModel,
    required ARViewModel arViewModel,
  })  : _locationService = locationService,
        _placesRepository = placesRepository,
        _routeRepository = routeRepository,
        _navigationViewModel = navigationViewModel,
        _arViewModel = arViewModel;

  LatLng? _currentLocation;
  double? _currentHeading;
  double? _currentAccuracy;
  double? _currentSpeed;
  List<PlaceModel> _searchResults = [];
  PlaceModel? _selectedDestination;
  List<RouteModel> _previewRoutes = [];
  int _selectedRouteIndex = 0;
  bool _isFetchingRoute = false;
  StreamSubscription<LatLng>? _locationSubscription;
  Timer? _searchDebounce;

  LatLng? get currentLocation => _currentLocation;
  double? get currentHeading => _currentHeading;
  double? get currentAccuracy => _currentAccuracy;
  double? get currentSpeed => _currentSpeed;
  List<PlaceModel> get searchResults => _searchResults;
  PlaceModel? get selectedDestination => _selectedDestination;
  List<RouteModel> get previewRoutes => _previewRoutes;
  int get selectedRouteIndex => _selectedRouteIndex;
  RouteModel? get selectedRoute =>
      _previewRoutes.isNotEmpty ? _previewRoutes[_selectedRouteIndex] : null;
  bool get isFetchingRoute => _isFetchingRoute;

  Future<void> startLocationTracking() async {
    try {
      _currentLocation = await _locationService.getCurrentLocation();
      _currentHeading = _locationService.currentHeading;
      _currentAccuracy = _locationService.currentAccuracy;
      _currentSpeed = _locationService.currentSpeed;
      notifyListeners();
    } catch (_) {}

    _locationSubscription =
        _locationService.getLocationStream().listen((location) {
      _currentLocation = location;
      _currentHeading = _locationService.currentHeading;
      _currentAccuracy = _locationService.currentAccuracy;
      _currentSpeed = _locationService.currentSpeed;
      notifyListeners();

      if (_navigationViewModel.navigationStatus != NavigationStatus.navigating) {
        return;
      }

      _navigationViewModel.checkIfArrived(location);
      _arViewModel.updateAROverlay(location);

      final route = _navigationViewModel.currentRoute;
      if (route != null && _isOffRoute(location, route)) {
        _navigationViewModel.recalculateRoute();
      }

    });
  }

  void stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _locationService.stopLocationStream();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    stopLocationTracking();
    super.dispose();
  }

  void searchDestination(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      final results = await _placesRepository.searchPlaces(
        query,
        location: _currentLocation,
      );
      _searchResults = results;
      notifyListeners();
    });
  }

  Future<void> selectDestination(PlaceModel place) async {
    _isFetchingRoute = true;
    _previewRoutes = [];
    _searchResults = [];
    notifyListeners();

    try {
      final detailed = await _placesRepository.getPlaceDetails(place.placeId);
      _selectedDestination = detailed;
      notifyListeners();
      await _fetchPreviewRoute();
    } catch (_) {
      _isFetchingRoute = false;
      notifyListeners();
    }
  }

  // Sets a fully-resolved place (coordinates already present) as destination.
  void setSelectedDestination(PlaceModel place) {
    _selectedDestination = place;
    _previewRoutes = [];
    _searchResults = [];
    notifyListeners();
    _fetchPreviewRoute();
  }

  Future<void> _fetchPreviewRoute() async {
    if (_selectedDestination == null) return;
    _isFetchingRoute = true;
    _selectedRouteIndex = 0;
    notifyListeners();

    try {
      final origin =
          _currentLocation ?? await _locationService.getCurrentLocation();
      _previewRoutes = await _routeRepository.getRoute(
        origin: origin,
        destination: _selectedDestination!.coordinates,
      );
    } catch (_) {
      // Route fetch failure is non-critical — destination stays selected.
    } finally {
      _isFetchingRoute = false;
      notifyListeners();
    }
  }

  void selectRoute(int index) {
    if (index < 0 || index >= _previewRoutes.length) return;
    _selectedRouteIndex = index;
    notifyListeners();
  }

  void clearDestination() {
    _selectedDestination = null;
    _previewRoutes = [];
    _selectedRouteIndex = 0;
    _isFetchingRoute = false;
    _searchResults = [];
    notifyListeners();
  }

  bool _isOffRoute(LatLng location, RouteModel route) {
    for (final waypoint in route.waypoints) {
      if (calculateDistance(location, waypoint) <= 30.0) return false;
    }
    return true;
  }
}
