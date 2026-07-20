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
  bool _isSelectingRouteFromNav = false;
  bool _pendingRecenter = false;
  int _routeVersion = 0;
  int _fetchGeneration = 0;
  String? _routeError;
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
  bool get isSelectingRouteFromNav => _isSelectingRouteFromNav;
  bool get pendingRecenter => _pendingRecenter;
  int get routeVersion => _routeVersion;
  String? get routeError => _routeError;

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

      final status = _navigationViewModel.navigationStatus;
      if (status != NavigationStatus.navigating &&
          status != NavigationStatus.rerouting) {
        return;
      }

      // Off-route check only when actively navigating — skip during rerouting
      // to avoid triggering a second reroute while the first is in flight.
      if (status == NavigationStatus.navigating) {
        final route = _navigationViewModel.currentRoute;
        if (route != null && _isOffRoute(location, route)) {
          final now = DateTime.now();
          final cooldownElapsed = _lastRerouteTime == null ||
              now.difference(_lastRerouteTime!) >= const Duration(seconds: 30);
          if (cooldownElapsed) {
            _lastRerouteTime = now;
            _navigationViewModel.recalculateRoute(from: location);
          }
        }
      }

      if (_navigationViewModel.navigationStatus == NavigationStatus.rerouting) {
        return;
      }
      _arViewModel.updateAROverlay(location);
      _navigationViewModel.updateRemainingPolyline(location);
      _navigationViewModel.checkIfArrived(location);
    });

    // Heartbeat: force-refresh the AR overlay every 2 s so the screen stays
    // current after the app returns from background (GPS stream may stall
    // briefly after resume).
    _navRefreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      final loc = _currentLocation;
      if (loc != null &&
          _navigationViewModel.navigationStatus == NavigationStatus.navigating) {
        _arViewModel.updateAROverlay(loc);
      }
    });
  }

  Future<void> stopLocationTracking() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    _navRefreshTimer?.cancel();
    _navRefreshTimer = null;
    _trackingStarted = false;
    _locationService.stopLocationStream();
  }

  Future<void> restartLocationTracking() async {
    await stopLocationTracking();
    await startLocationTracking();
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
    final int generation = ++_fetchGeneration;
    _isFetchingRoute = true;
    _routeError = null;
    notifyListeners();

    try {
      final origin =
          _currentLocation ?? await _locationService.getCurrentLocation();
      final routes = await _routeRepository.getRoute(
        origin: origin,
        destination: _selectedDestination!.coordinates,
      );
      if (generation != _fetchGeneration) return;

      // Capture the route currently shown to the user before replacing the list.
      final previousRoute = _previewRoutes.isNotEmpty &&
              _selectedRouteIndex < _previewRoutes.length
          ? _previewRoutes[_selectedRouteIndex]
          : null;

      _previewRoutes = routes;

      // Re-match the previously selected route by distance+duration so that
      // API reordering (different origin, different alternatives order) does
      // not silently switch the user to a different route.
      if (previousRoute != null) {
        final matchIndex = _previewRoutes.indexWhere(
          (r) =>
              (r.totalDistance - previousRoute.totalDistance).abs() < 500 &&
              (r.estimatedDuration - previousRoute.estimatedDuration).abs() < 60,
        );
        _selectedRouteIndex = matchIndex >= 0 ? matchIndex : 0;
      } else {
        _selectedRouteIndex = 0;
      }
    } catch (_) {
      if (generation != _fetchGeneration) return;
      await Future.delayed(const Duration(seconds: 1));
      if (generation != _fetchGeneration) return;
      try {
        final retryOrigin =
            _currentLocation ?? await _locationService.getCurrentLocation();
        final retryRoutes = await _routeRepository.getRoute(
          origin: retryOrigin,
          destination: _selectedDestination!.coordinates,
        );
        if (generation != _fetchGeneration) return;
        _previewRoutes = retryRoutes;
        _selectedRouteIndex = 0;
      } catch (_) {
        if (generation != _fetchGeneration) return;
        _previewRoutes = [];
        _routeError = 'Could not load route. Tap to retry.';
      }
    } finally {
      if (generation == _fetchGeneration) {
        _isFetchingRoute = false;
        notifyListeners();
      }
    }
  }

  Future<void> refreshPreviewRoute() async {
    if (_selectedDestination == null) return;
    _isSelectingRouteFromNav = true;
    _routeVersion++;
    await _fetchPreviewRoute();
    notifyListeners();
  }

  void setSelectingRouteFromNav(bool value) {
    _isSelectingRouteFromNav = value;
    notifyListeners();
  }

  void requestRecenter() {
    _pendingRecenter = true;
    notifyListeners();
  }

  void consumeRecenter() {
    _pendingRecenter = false;
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
    _isSelectingRouteFromNav = false;
    _routeError = null;
    _searchResults = [];
    notifyListeners();
  }

  bool _isOffRoute(LatLng location, RouteModel route) {
    final points = route.polylinePoints;
    if (points.isEmpty) return false;

    double closestDist = double.infinity;
    for (int i = 0; i < points.length - 1; i++) {
      final d = _distanceToSegment(location, points[i], points[i + 1]);
      if (d < closestDist) closestDist = d;
    }

    return closestDist > 50.0;
  }

  // Shortest distance from [p] to the finite line segment [a]→[b].
  // Uses a flat-earth lat/lng projection — accurate enough for the short
  // segment lengths (< ~200 m) that appear in navigation polylines.
  double _distanceToSegment(LatLng p, LatLng a, LatLng b) {
    final dx = b.latitude  - a.latitude;
    final dy = b.longitude - a.longitude;
    final lenSq = dx * dx + dy * dy;
    if (lenSq == 0) return calculateDistance(p, a);
    final t = (((p.latitude  - a.latitude)  * dx +
                (p.longitude - a.longitude) * dy) / lenSq)
        .clamp(0.0, 1.0);
    return calculateDistance(
      p,
      LatLng(a.latitude + t * dx, a.longitude + t * dy),
    );
  }
}
