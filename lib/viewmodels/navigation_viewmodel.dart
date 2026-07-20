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
  int _lastRemainingPolylineIndex = 0;

  PlaceModel? get currentDestination => _currentDestination;
  RouteModel? get currentRoute => _currentRoute;
  NavigationStatus get navigationStatus => _navigationStatus;
  String? get errorMessage => _errorMessage;
  int? get activeRouteIndex => _activeRouteIndex;
  List<LatLng> get remainingPolyline => _remainingPolyline;

  Future<void> startNavigation(
    PlaceModel destination, {
    RouteModel? route,
    int? routeIndex,
  }) async {
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
        );
        _currentRoute = routes.first;
        _activeRouteIndex = 0; // fallback fetch always yields index 0
      }
      await _arViewModel.initializeOverlay(_currentRoute!);
      _remainingPolyline = List.from(_currentRoute!.polylinePoints);
      NavigationForegroundService.startService(
        destination: _currentDestination?.name ?? '',
        eta: '${(_currentRoute!.estimatedDuration / 60).ceil()} min',
      );
      _navigationStatus = NavigationStatus.navigating;
    } catch (e) {
      _errorMessage = e.toString();
      _navigationStatus = NavigationStatus.idle;
    }
    notifyListeners();
  }

  Future<void> stopNavigation({bool stopService = true}) async {
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
    notifyListeners();

    try {
      final routes = await _routeRepository.getRoute(
        origin: from,
        destination: _currentDestination!.coordinates,
      );
      _currentRoute = routes.first;
      await _arViewModel.initializeOverlay(_currentRoute!);
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
