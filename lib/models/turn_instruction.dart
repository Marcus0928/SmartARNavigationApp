import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_ar_navigation/core/enums/turn_direction.dart';

class TurnInstruction {
  final TurnDirection direction;
  final double distanceFromPrev;
  final String streetName;
  final LatLng position;

  const TurnInstruction({
    required this.direction,
    required this.distanceFromPrev,
    required this.streetName,
    required this.position,
  });
}
