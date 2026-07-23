import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:smart_ar_navigation/core/enums/navigation_status.dart';
import 'package:smart_ar_navigation/core/utils/location_utils.dart';
import 'package:smart_ar_navigation/models/place_model.dart';
import 'package:smart_ar_navigation/models/route_model.dart';
import 'package:smart_ar_navigation/repositories/route_repository.dart';
import 'package:smart_ar_navigation/services/ar_service.dart';
import 'package:smart_ar_navigation/services/location_service.dart';
import 'package:smart_ar_navigation/viewmodels/ar_viewmodel.dart';
import 'package:smart_ar_navigation/services/navigation_foreground_service.dart';
import 'package:smart_ar_navigation/viewmodels/profile_viewmodel.dart';

class NavigationViewModel extends ChangeNotifier {
  final RouteRepository _routeRepository;
  final LocationService _locationService;
  final ARService _arService;
  final ARViewModel _arViewModel;
  final ProfileViewModel _profileViewModel;

  static NavigationViewModel? _instance;
  static NavigationViewModel? get instance => _instance;

  NavigationViewModel({
    required RouteRepository routeRepository,
    required LocationService locationService,
    required ARService arService,
    required ARViewModel arViewModel,
    required ProfileViewModel profileViewModel,
  })  : _routeRepository = routeRepository,
        _locationService = locationService,
        _arService = arService,
        _arViewModel = arViewModel,
        _profileViewModel = profileViewModel {
    _instance = this;
  }

  @override
  void dispose() {
    _instance = null;
    super.dispose();
  }

  PlaceModel? _currentDestination;
  RouteModel? _currentRoute;
  NavigationStatus _navigationStatus = NavigationStatus.idle;
  String? _errorMessage;
  int? _activeRouteIndex;
  List<LatLng> _remainingPolyline = const [];
  RouteModel? _suggestedFasterRoute;
  Timer? _fasterRouteTimer;
  bool _showFasterRouteMap = false;
  int? _dismissedRouteDuration;
  bool _isStartingNavigation = false;
  int _lastRemainingPolylineIndex = 0;

  PlaceModel? get currentDestination => _currentDestination;
  RouteModel? get currentRoute => _currentRoute;
  NavigationStatus get navigationStatus => _navigationStatus;
  String? get errorMessage => _errorMessage;
  int? get activeRouteIndex => _activeRouteIndex;
  List<LatLng> get remainingPolyline => _remainingPolyline;

  /// Estimates the remaining travel time on the current route by scaling
  /// the original estimated duration by how much of the polyline is left,
  /// so faster-route comparisons aren't made against the full trip duration.
  int get remainingDuration {
    if (_currentRoute == null) return 0;
    final fullLen = _currentRoute!.polylinePoints.length;
    if (fullLen == 0) return 0;
    final remainLen = _remainingPolyline.length;
    final ratio = remainLen / fullLen;
    return (_currentRoute!.estimatedDuration * ratio).round();
  }

  /// Estimates the remaining distance on the current route using the same
  /// polyline-ratio approach as [remainingDuration], so the bottom bar's
  /// distance figure shrinks in step with its ETA figure.
  double get remainingDistance {
    if (_currentRoute == null) return 0;
    final fullLen = _currentRoute!.polylinePoints.length;
    if (fullLen == 0) return 0;
    final remainLen = _remainingPolyline.length;
    final ratio = remainLen / fullLen;
    return _currentRoute!.totalDistance * ratio;
  }

  RouteModel? get suggestedFasterRoute => _suggestedFasterRoute;
  bool get showFasterRouteMap => _showFasterRouteMap;
  bool get isStartingNavigation => _isStartingNavigation;

  Future<void> startNavigation(
    PlaceModel destination, {
    RouteModel? route,
    int? routeIndex,
  }) async {
    if (_isStartingNavigation) return;
    _isStartingNavigation = true;
    if (_navigationStatus == NavigationStatus.navigating) {
      await stopNavigation(stopService: false);
    }
    _navigationStatus = NavigationStatus.loading;
    _currentDestination = destination;
    _errorMessage = null;
    notifyListeners();

    try {
      if (route != null) {
        _currentRoute = route;
        _activeRouteIndex = routeIndex;
      } else {
        final origin = await _locationService.getCurrentLocation();
        final routes = await _routeRepository.getRoute(
          origin: origin,
          destination: destination.coordinates,
          heading: _locationService.currentHeading,
        );
        _currentRoute = routes.first;
        _activeRouteIndex = 0; // fallback fetch always yields index 0
      }
      _arViewModel.setDestination(_currentDestination?.coordinates);
      _remainingPolyline = List.from(_currentRoute!.polylinePoints);
      await Future.wait<void>([
        _arViewModel.initializeOverlay(
          _currentRoute!,
          heading: _locationService.currentHeading,
        ),
        NavigationForegroundService.startService(
          destination: _currentDestination?.name ?? '',
          eta: '${(_currentRoute!.estimatedDuration / 60).ceil()} min',
        ).then((ok) {
          if (!ok) {
            debugPrint(
              'Warning: foreground service did not start — '
              'app may be killed in background',
            );
          }
        }),
      ]);
      _navigationStatus = NavigationStatus.navigating;
      _fasterRouteTimer?.cancel();
      _fasterRouteTimer = Timer.periodic(
        const Duration(minutes: 5),
        (_) => _checkForFasterRoute(),
      );
    } catch (e) {
      _errorMessage = e.toString();
      _navigationStatus = NavigationStatus.idle;
    } finally {
      _isStartingNavigation = false;
      notifyListeners();
    }
  }

  // Does not touch _isStartingNavigation — that guard is owned exclusively
  // by startNavigation(), including when this runs as its internal
  // "stop the old session first" sub-step. Resetting it here would
  // re-enable the Start/Go button mid-switch and let a second tap start a
  // second, concurrent startNavigation() call — which creates a second
  // ArView/ARCore Session and fatally crashes when both sessions' frame
  // loops contend for the camera.
  Future<void> stopNavigation({bool stopService = true}) async {
    _fasterRouteTimer?.cancel();
    _fasterRouteTimer = null;
    _suggestedFasterRoute = null;
    _showFasterRouteMap = false;
    _dismissedRouteDuration = null;
    _arService.clearOverlays();
    _arViewModel.resetOverlay();
    _currentRoute = null;
    _currentDestination = null;
    _activeRouteIndex = null;
    _remainingPolyline = const [];
    _lastRemainingPolylineIndex = 0;
    _navigationStatus = NavigationStatus.idle;
    notifyListeners();
    if (stopService) {
      await NavigationForegroundService.stopService();
    }
  }

  /// Recalculates the route from [from] (the live GPS position already known
  /// by the caller) so we never stall waiting for a fresh GPS fix.
  Future<void> recalculateRoute({required LatLng from}) async {
    if (_currentDestination == null) return;
    _navigationStatus = NavigationStatus.rerouting;
    _dismissedRouteDuration = null;
    notifyListeners();

    try {
      final routes = await _routeRepository.getRoute(
        origin: from,
        destination: _currentDestination!.coordinates,
        heading: _locationService.currentHeading,
      );
      _currentRoute = routes.first;
      await _arViewModel.initializeOverlay(
        _currentRoute!,
        heading: _locationService.currentHeading,
      );
      _arViewModel.setDestination(_currentDestination?.coordinates);
      _remainingPolyline = List.from(_currentRoute!.polylinePoints);
      _lastRemainingPolylineIndex = 0;
      _navigationStatus = NavigationStatus.navigating;
    } catch (e) {
      _errorMessage = e.toString();
      _navigationStatus = NavigationStatus.navigating;
    }
    notifyListeners();
  }

  void updateRemainingPolyline(LatLng location) {
    if (_currentRoute == null) return;
    final points = _currentRoute!.polylinePoints;
    if (points.isEmpty) return;

    // Search forward from the last known index with a small backward
    // buffer for GPS jitter, instead of scanning the full route every tick.
    final start =
        (_lastRemainingPolylineIndex - 5).clamp(0, points.length - 1);
    final end =
        (_lastRemainingPolylineIndex + 100).clamp(0, points.length - 1);

    double closestDist = double.infinity;
    int closestIndex = _lastRemainingPolylineIndex;

    for (int i = start; i <= end; i++) {
      final d = calculateDistance(
        location,
        LatLng(points[i].latitude, points[i].longitude),
      );
      if (d < closestDist) {
        closestDist = d;
        closestIndex = i;
      }
    }

    _lastRemainingPolylineIndex = closestIndex;
    _remainingPolyline = points.sublist(closestIndex);
    notifyListeners();
  }

  Future<void> acceptFasterRoute() async {
    if (_suggestedFasterRoute == null) return;
    _showFasterRouteMap = false;
    _dismissedRouteDuration = null;
    _currentRoute = _suggestedFasterRoute;
    _suggestedFasterRoute = null;
    await _arViewModel.initializeOverlay(
      _currentRoute!,
      heading: _locationService.currentHeading,
    );
    _remainingPolyline = List.from(_currentRoute!.polylinePoints);
    notifyListeners();
  }

  void dismissFasterRoute() {
    _dismissedRouteDuration = _suggestedFasterRoute?.estimatedDuration;
    _showFasterRouteMap = false;
    _suggestedFasterRoute = null;
    notifyListeners();
  }

  Future<void> _checkForFasterRoute() async {
    if (_currentDestination == null ||
        _navigationStatus != NavigationStatus.navigating ||
        _currentRoute == null) {
      return;
    }

    // Don't interrupt when a turn is imminent
    final distToTurn = _arViewModel.distanceToNextTurn;
    if (distToTurn != null && distToTurn < 500) return;

    try {
      final origin = await _locationService.getLastKnownLocation();
      if (origin == null) return;
      final routes = await _routeRepository.getRoute(
        origin: origin,
        destination: _currentDestination!.coordinates,
        heading: _locationService.currentHeading,
      );
      if (routes.isEmpty) return;
      final fastest = routes.reduce(
        (a, b) => a.estimatedDuration < b.estimatedDuration ? a : b,
      );
      final remaining = remainingDuration;
      final timeSaved = remaining - fastest.estimatedDuration;
      // Skip if this is the same route the user already dismissed
      if (_dismissedRouteDuration != null &&
          fastest.estimatedDuration >= _dismissedRouteDuration!) {
        return;
      }
      if (timeSaved >= 300 &&
          remaining > 0 &&
          timeSaved / remaining >= 0.10) {
        _suggestedFasterRoute = fastest;
        _showFasterRouteMap = true;
        notifyListeners();
      }
    } catch (_) {
      // Best-effort — silently ignore network/API errors
    }
  }

  void checkIfArrived(LatLng currentLocation) {
    if (_currentDestination == null ||
        _navigationStatus != NavigationStatus.navigating) {
      return;
    }

    final distance =
        calculateDistance(currentLocation, _currentDestination!.coordinates);

    if (distance < 20.0) {
      _arService.clearOverlays();
      _arViewModel.resetOverlay();
      NavigationForegroundService.stopService();
      _navigationStatus = NavigationStatus.arrived;
      notifyListeners();
      _profileViewModel.incrementDriveCount();
      if (_currentRoute != null) {
        _profileViewModel.addDistance(_currentRoute!.totalDistance / 1000);
      }
    }
  }
}
