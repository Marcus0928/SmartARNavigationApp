import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  StreamSubscription<Position>? _streamSubscription;
  final StreamController<LatLng> _locationController =
      StreamController<LatLng>.broadcast();

  /// Latest heading in degrees (0 = North, clockwise). Null when unavailable.
  double? currentHeading;

  /// Latest GPS accuracy in metres.
  double? currentAccuracy;

  Future<bool> checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<LatLng> getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    currentHeading = position.heading >= 0 ? position.heading : null;
    currentAccuracy = position.accuracy;
    return LatLng(position.latitude, position.longitude);
  }

  Stream<LatLng> getLocationStream() {
    _streamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) {
      currentHeading = position.heading >= 0 ? position.heading : null;
      currentAccuracy = position.accuracy;
      _locationController.add(LatLng(position.latitude, position.longitude));
    });
    return _locationController.stream;
  }

  void stopLocationStream() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
  }
}
