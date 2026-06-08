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
  bool _trackingStarted = false;
  DateTime? _lastRerouteTime;
  List<PlaceModel> _searchResults = [];
  PlaceModel? _selectedDestination;
  List<RouteModel> _previewRoutes = [];
  int _selectedRouteIndex = 0;
  bool _isFetchingRoute = false;
  int _routeVersion = 0;
  StreamSubscription<LatLng>? _locationSubscription;
  Timer? _searchDebounce;
  Timer? _navRefreshTimer;

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
  int get routeVersion => _routeVersion;

  Future<void> startLocationTracking() async {
    if (_trackingStarted) return;
    _trackingStarted = true;
    // Use the OS-cached last-known position for an instant first fix, then
    // let the live stream replace it as GPS warms up. This avoids blocking
    // on getCurrentPosition() which can take 15–30 s on a cold start.
    final lastKnown = await _locationService.getLastKnownLocation();
    if (lastKnown != null) {
      _currentLocation = lastKnown;
      _currentHeading = _locationService.currentHeading;
      _currentAccuracy = _locationService.currentAccuracy;
      _currentSpeed = _locationService.currentSpeed;
      notifyListeners();
    }

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
      _navigationViewModel.updateRemainingPolyline(location);
      _arViewModel.updateAROverlay(location);

      final route = _navigationViewModel.currentRoute;
      if (route != null && _isOffRoute(location, route)) {
        final now = DateTime.now();
        final cooldownElapsed = _lastRerouteTime == null ||
            now.difference(_lastRerouteTime!) >= const Duration(seconds: 15);
        if (cooldownElapsed) {
          _lastRerouteTime = now;
          _navigationViewModel.recalculateRoute(from: location);
        }
      }
    });

    // Heartbeat: force-refresh the AR overlay every 5 s so the screen stays
    // current after the app returns from background (GPS stream may stall
    // briefly after resume).
    _navRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final loc = _currentLocation;
      if (loc != null &&
          _navigationViewModel.navigationStatus == NavigationStatus.navigating) {
        _arViewModel.updateAROverlay(loc);
      }
    });
  }

  void stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _navRefreshTimer?.cancel();
    _navRefreshTimer = null;
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

  Future<void> refreshPreviewRoute() async {
    if (_selectedDestination == null) return;
    _routeVersion++;
    await _fetchPreviewRoute();
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
