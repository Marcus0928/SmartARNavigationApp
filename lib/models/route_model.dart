import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_ar_navigation/models/turn_instruction.dart';

class RouteModel {
  final String label;
  final List<LatLng> waypoints;
  final List<LatLng> polylinePoints;
  final List<TurnInstruction> turns;
  final double totalDistance;
  final int estimatedDuration;
  final bool hasTolls;

  const RouteModel({
    required this.label,
    required this.waypoints,
    required this.polylinePoints,
    required this.turns,
    required this.totalDistance,
    required this.estimatedDuration,
    this.hasTolls = false,
  });
}
