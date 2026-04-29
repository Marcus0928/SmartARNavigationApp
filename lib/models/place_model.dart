import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlaceModel {
  final String placeId;
  final String name;
  final String address;
  final LatLng coordinates;

  const PlaceModel({
    required this.placeId,
    required this.name,
    required this.address,
    required this.coordinates,
  });
}
