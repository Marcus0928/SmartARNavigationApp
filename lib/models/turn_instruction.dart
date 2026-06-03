import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_ar_navigation/core/enums/turn_direction.dart';

class TurnInstruction {
  final TurnDirection direction;
  final double distanceFromPrev;
  final String? streetName;
  final LatLng position;
  final String maneuver;
  final int? exitNumber;

  const TurnInstruction({
    required this.direction,
    required this.distanceFromPrev,
    this.streetName,
    required this.position,
    required this.maneuver,
    this.exitNumber,
  });
}
