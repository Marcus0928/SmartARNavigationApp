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

class NavigationViewModel extends ChangeNotifier {
  final RouteRepository _routeRepository;
  final LocationService _locationService;
  final ARService _arService;
  final ARViewModel _arViewModel;

  NavigationViewModel({
    required RouteRepository routeRepository,
    required LocationService locationService,
    required ARService arService,
    required ARViewModel arViewModel,
  })  : _routeRepository = routeRepository,
        _locationService = locationService,
        _arService = arService,
        _arViewModel = arViewModel;

  PlaceModel? _currentDestination;
  RouteModel? _currentRoute;
  NavigationStatus _navigationStatus = NavigationStatus.idle;
  String? _errorMessage;

  PlaceModel? get currentDestination => _currentDestination;
  RouteModel? get currentRoute => _currentRoute;
  NavigationStatus get navigationStatus => _navigationStatus;
  String? get errorMessage => _errorMessage;

  Future<void> startNavigation(
    PlaceModel destination, {
    RouteModel? route,
  }) async {
    _navigationStatus = NavigationStatus.loading;
    _currentDestination = destination;
    _errorMessage = null;
    notifyListeners();

    try {
      if (route != null) {
        _currentRoute = route;
      } else {
        final origin = await _locationService.getCurrentLocation();
        final routes = await _routeRepository.getRoute(
          origin: origin,
          destination: destination.coordinates,
        );
        _currentRoute = routes.first;
      }
      await _arViewModel.initializeOverlay(_currentRoute!);
      _navigationStatus = NavigationStatus.navigating;
    } catch (e) {
      _errorMessage = e.toString();
      _navigationStatus = NavigationStatus.idle;
    }
    notifyListeners();
  }

  void stopNavigation() {
    _locationService.stopLocationStream();
    _arService.clearOverlays();
    _arViewModel.resetOverlay();
    _currentRoute = null;
    _currentDestination = null;
    _navigationStatus = NavigationStatus.idle;
    notifyListeners();
  }

  Future<void> recalculateRoute() async {
    if (_currentDestination == null) return;
    _navigationStatus = NavigationStatus.rerouting;
    notifyListeners();

    try {
      final origin = await _locationService.getCurrentLocation();
      final routes = await _routeRepository.getRoute(
        origin: origin,
        destination: _currentDestination!.coordinates,
      );
      _currentRoute = routes.first;
      await _arViewModel.initializeOverlay(_currentRoute!);
      _navigationStatus = NavigationStatus.navigating;
    } catch (e) {
      _errorMessage = e.toString();
      _navigationStatus = NavigationStatus.navigating;
    }
    notifyListeners();
  }

  void checkIfArrived(LatLng currentLocation) {
    if (_currentDestination == null ||
        _navigationStatus != NavigationStatus.navigating) return;

    final distance =
        calculateDistance(currentLocation, _currentDestination!.coordinates);

    if (distance < 20.0) {
      _arService.clearOverlays();
      _arViewModel.resetOverlay();
      _navigationStatus = NavigationStatus.arrived;
      notifyListeners();
    }
  }
}
