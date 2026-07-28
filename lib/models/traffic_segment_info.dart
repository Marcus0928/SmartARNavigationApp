import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_ar_navigation/core/enums/traffic_severity.dart';

class TrafficSegmentInfo {
  final int delayMinutes;
  final LatLng segmentStartPosition;
  final LatLng segmentEndPosition;
  final TrafficSeverity severity;

  const TrafficSegmentInfo({
    required this.delayMinutes,
    required this.segmentStartPosition,
    required this.segmentEndPosition,
    required this.severity,
  });
}
