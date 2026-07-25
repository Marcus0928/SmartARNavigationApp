import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_ar_navigation/models/turn_instruction.dart';

double calculateDistance(LatLng point1, LatLng point2) {
  return Geolocator.distanceBetween(
    point1.latitude,
    point1.longitude,
    point2.latitude,
    point2.longitude,
  );
}

// Bearing in degrees (-180 to 180, 0 = north, clockwise) from [from] to [to].
double calculateBearing(LatLng from, LatLng to) {
  return Geolocator.bearingBetween(
    from.latitude,
    from.longitude,
    to.latitude,
    to.longitude,
  );
}

// Smallest angle between two headings/bearings, normalized to 0-180 degrees
// (e.g. 350 vs 10 -> 20, not 340).
double angularDifference(double heading1, double heading2) {
  final diff = (heading1 - heading2).abs() % 360;
  return diff > 180 ? 360 - diff : diff;
}

TurnInstruction? findNextTurn(
  LatLng currentLocation,
  List<TurnInstruction> turns,
) {
  for (final turn in turns) {
    final distance = calculateDistance(currentLocation, turn.position);
    if (distance >= 10.0) return turn;
  }
  return null;
}
