import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:smart_ar_navigation/core/enums/navigation_status.dart';
import 'package:smart_ar_navigation/core/utils/location_utils.dart';
import 'package:smart_ar_navigation/models/place_model.dart';
import 'package:smart_ar_navigation/models/route_model.dart';
import 'package:smart_ar_navigation/repositories/places_repository.dart';
import 'package:smart_ar_navigation/services/location_service.dart';
import 'package:smart_ar_navigation/viewmodels/ar_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/navigation_viewmodel.dart';

class MapViewModel extends ChangeNotifier {
  final LocationService _locationService;
  final PlacesRepository _placesRepository;
  final NavigationViewModel _navigationViewModel;
  final ARViewModel _arViewModel;

  MapViewModel({
    required LocationService locationService,
    required PlacesRepository placesRepository,
    required NavigationViewModel navigationViewModel,
    required ARViewModel arViewModel,
  })  : _locationService = locationService,
        _placesRepository = placesRepository,
        _navigationViewModel = navigationViewModel,
        _arViewModel = arViewModel;

  LatLng? _currentLocation;
  List<PlaceModel> _searchResults = [];
  PlaceModel? _selectedDestination;
  StreamSubscription<LatLng>? _locationSubscription;

  LatLng? get currentLocation => _currentLocation;
  List<PlaceModel> get searchResults => _searchResults;
  PlaceModel? get selectedDestination => _selectedDestination;

  void startLocationTracking() {
    _locationSubscription =
        _locationService.getLocationStream().listen((location) {
      _currentLocation = location;
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

  Future<void> searchDestination(String query) async {
    _searchResults = await _placesRepository.searchPlaces(query);
    notifyListeners();
  }

  Future<void> selectDestination(PlaceModel place) async {
    final detailed = await _placesRepository.getPlaceDetails(place.placeId);
    _selectedDestination = detailed;
    _searchResults = [];
    notifyListeners();
  }

  void clearDestination() {
    _selectedDestination = null;
    _searchResults = [];
    notifyListeners();
  }

  /// Returns true if the user is more than 30m away from every waypoint on the route.
  bool _isOffRoute(LatLng location, RouteModel route) {
    for (final waypoint in route.waypoints) {
      if (calculateDistance(location, waypoint) <= 30.0) return false;
    }
    return true;
  }
}
