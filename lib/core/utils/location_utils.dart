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
