import 'dart:async';
import 'dart:io' show Platform;

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

  /// Latest speed in metres per second. Null or negative when unavailable.
  double? currentSpeed;

  Future<bool> checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Returns the OS-cached last-known position instantly (< 100 ms).
  /// Returns null on first-ever launch when no cache exists.
  Future<LatLng?> getLastKnownLocation() async {
    final position = await Geolocator.getLastKnownPosition();
    if (position == null) return null;
    currentHeading = position.heading >= 0 ? position.heading : null;
    currentAccuracy = position.accuracy;
    currentSpeed = position.speed >= 0 ? position.speed : null;
    return LatLng(position.latitude, position.longitude);
  }

  /// Forces a fresh GPS fix. Use only when a current position is strictly
  /// required and the stream has not yet delivered one (e.g. route fetch
  /// fallback). Times out after 10 s to avoid indefinite blocking.
  Future<LatLng> getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition()
        .timeout(const Duration(seconds: 10));
    currentHeading = position.heading >= 0 ? position.heading : null;
    currentAccuracy = position.accuracy;
    currentSpeed = position.speed >= 0 ? position.speed : null;
    return LatLng(position.latitude, position.longitude);
  }

  Stream<LatLng> getLocationStream() {
    _streamSubscription?.cancel();
    final settings = Platform.isAndroid
        ? AndroidSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 3,
            intervalDuration: const Duration(milliseconds: 500),
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationText: 'Smart AR Navigate is running',
              notificationTitle: 'Navigation Active',
              enableWakeLock: true,
            ),
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 3,
          );

    _streamSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen((position) {
      currentHeading = position.heading >= 0 ? position.heading : null;
      currentAccuracy = position.accuracy;
      currentSpeed = position.speed >= 0 ? position.speed : null;
      _locationController.add(LatLng(position.latitude, position.longitude));
    });
    return _locationController.stream;
  }

  void stopLocationStream() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
  }
}
