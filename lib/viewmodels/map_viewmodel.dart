import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:smart_ar_navigation/core/enums/navigation_status.dart';
import 'package:smart_ar_navigation/models/place_model.dart';
import 'package:smart_ar_navigation/models/route_model.dart';
import 'package:smart_ar_navigation/repositories/places_repository.dart';
import 'package:smart_ar_navigation/repositories/route_repository.dart';
import 'package:smart_ar_navigation/services/location_service.dart';
import 'package:smart_ar_navigation/viewmodels/ar_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/navigation_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/settings_viewmodel.dart';

class MapViewModel extends ChangeNotifier {
  final LocationService _locationService;
  final PlacesRepository _placesRepository;
  final RouteRepository _routeRepository;
  final NavigationViewModel _navigationViewModel;
  final ARViewModel _arViewModel;
  final SettingsViewModel _settingsViewModel;

  MapViewModel({
    required LocationService locationService,
    required PlacesRepository placesRepository,
    required RouteRepository routeRepository,
    required NavigationViewModel navigationViewModel,
    required ARViewModel arViewModel,
    required SettingsViewModel settingsViewModel,
  })  : _locationService = locationService,
        _placesRepository = placesRepository,
        _routeRepository = routeRepository,
        _navigationViewModel = navigationViewModel,
        _arViewModel = arViewModel,
        _settingsViewModel = settingsViewModel;

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
  bool _isRefreshingPreviewRoute = false;
  bool _pendingRecenter = false;
  int _routeVersion = 0;
  int _fetchGeneration = 0;
  String? _routeError;
  StreamSubscription<LatLng>? _locationSubscription;
  Timer? _searchDebounce;
  Timer? _navRefreshTimer;
  int _lastClosestSegmentIndex = 0;
  bool _isAppInForeground = true;

  // Bug 37: _isOffRoute() used to trigger recalculateRoute() off a single
  // GPS tick reading >50m from the route polyline — no smoothing, no
  // confirmation. A single noisy fix (multipath, urban canyon, bridge/
  // underpass) was enough to discard a perfectly good route. Mirrors the
  // sustained-confirmation pattern already proven for the missed-turn
  // heuristic in ARViewModel (_missedTurnConfirmationTicks): require the
  // off-route reading to hold for several consecutive ticks before acting
  // on it. Reset to 0 the instant any tick reads back within the polyline,
  // so this only ever catches a sustained deviation, not noise.
  int _offRouteStreak = 0;
  static const int _offRouteConfirmationTicks = 3;

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

      // Off-route re-trigger check only when actively navigating — skip
      // during rerouting to avoid triggering a second reroute while the
      // first is in flight. The overlay/polyline/arrival/traffic updates
      // below stay outside this gate so they keep running off the
      // last-known route (stale-but-updating) while a reroute is in flight,
      // instead of freezing the on-screen distance entirely.
      if (status == NavigationStatus.navigating) {
        final route = _navigationViewModel.currentRoute;
        if (route != null && _isOffRoute(location, route)) {
          _offRouteStreak++;
          if (_offRouteStreak >= _offRouteConfirmationTicks) {
            final now = DateTime.now();
            final cooldownElapsed = _lastRerouteTime == null ||
                now.difference(_lastRerouteTime!) >= const Duration(seconds: 30);
            if (cooldownElapsed) {
              _lastRerouteTime = now;
              _lastClosestSegmentIndex = 0;
              _offRouteStreak = 0;
              _navigationViewModel.recalculateRoute(from: location);
            }
          }
        } else {
          _offRouteStreak = 0;
        }
      }

      _arViewModel.updateAROverlay(
        location,
        heading: _currentHeading,
        speed: _currentSpeed,
      );
      _navigationViewModel.updateRemainingPolyline(location);
      _navigationViewModel.checkIfArrived(location);
      _navigationViewModel.updateTrafficSegmentProgress(location);
    });

    // Heartbeat: force-refresh the AR overlay every 2 s so the screen stays
    // current after the app returns from background (GPS stream may stall
    // briefly after resume).
    _navRefreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_isAppInForeground) return;
      final loc = _currentLocation;
      if (loc != null &&
          _navigationViewModel.navigationStatus == NavigationStatus.navigating) {
        _arViewModel.updateAROverlay(
          loc,
          heading: _currentHeading,
          speed: _currentSpeed,
        );
      }
    });
  }

  Future<void> stopLocationTracking() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    _navRefreshTimer?.cancel();
    _navRefreshTimer = null;
    _trackingStarted = false;
    _lastClosestSegmentIndex = 0;
    _offRouteStreak = 0;
    _locationService.stopLocationStream();
    _currentSpeed = null;
    notifyListeners();
  }

  void setAppForegroundState(bool inForeground) {
    _isAppInForeground = inForeground;
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
        avoidTolls: _settingsViewModel.avoidTolls,
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
          avoidTolls: _settingsViewModel.avoidTolls,
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
    if (_isRefreshingPreviewRoute) return;
    _isRefreshingPreviewRoute = true;
    _isSelectingRouteFromNav = true;
    _routeVersion++;
    try {
      await _fetchPreviewRoute();
      notifyListeners();
    } finally {
      _isRefreshingPreviewRoute = false;
      notifyListeners();
    }
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

  // Beyond this, the windowed search result is untrustworthy — the user's
  // real position has drifted outside the search window entirely (e.g. after
  // a GPS gap) rather than just being off-route, so the index needs
  // re-anchoring via a full scan instead of being left to lag behind
  // indefinitely.
  static const double _segmentSearchFallbackThreshold = 300.0;

  bool _isOffRoute(LatLng location, RouteModel route) {
    final points = route.polylinePoints;
    if (points.length < 2) return false;

    // Only scan a window of segments around the last known position — not
    // the full route. Look 20 segments behind and 50 segments ahead of the
    // last known index, since the driver only progresses forward along it.
    final start = (_lastClosestSegmentIndex - 20).clamp(0, points.length - 2);
    final end = (_lastClosestSegmentIndex + 50).clamp(0, points.length - 2);

    double closestDist = double.infinity;
    int closestIdx = _lastClosestSegmentIndex;

    for (int i = start; i <= end; i++) {
      final d = _distanceToSegment(
        location,
        LatLng(points[i].latitude, points[i].longitude),
        LatLng(points[i + 1].latitude, points[i + 1].longitude),
      );
      if (d < closestDist) {
        closestDist = d;
        closestIdx = i;
      }
    }

    if (closestDist > _segmentSearchFallbackThreshold) {
      for (int i = 0; i < points.length - 1; i++) {
        final d = _distanceToSegment(
          location,
          LatLng(points[i].latitude, points[i].longitude),
          LatLng(points[i + 1].latitude, points[i + 1].longitude),
        );
        if (d < closestDist) {
          closestDist = d;
          closestIdx = i;
        }
      }
    }

    _lastClosestSegmentIndex = closestIdx;

    return closestDist > 50.0;
  }

  // Perpendicular distance in metres from [location] to the segment
  // [segStart]→[segEnd], via a local flat-earth projection (accurate enough
  // for segments a few metres to tens of metres long).
  double _distanceToSegment(LatLng location, LatLng segStart, LatLng segEnd) {
    const metersPerDegLat = 111320.0;
    final avgLatRad = (segStart.latitude + segEnd.latitude) / 2 * (pi / 180);
    final metersPerDegLng = metersPerDegLat * cos(avgLatRad);

    final bx = (segEnd.longitude - segStart.longitude) * metersPerDegLng;
    final by = (segEnd.latitude - segStart.latitude) * metersPerDegLat;
    final px = (location.longitude - segStart.longitude) * metersPerDegLng;
    final py = (location.latitude - segStart.latitude) * metersPerDegLat;

    final lengthSquared = bx * bx + by * by;
    final t = lengthSquared == 0
        ? 0.0
        : ((px * bx + py * by) / lengthSquared).clamp(0.0, 1.0);

    final closestX = t * bx;
    final closestY = t * by;
    final dx = px - closestX;
    final dy = py - closestY;
    return sqrt(dx * dx + dy * dy);
  }
}
