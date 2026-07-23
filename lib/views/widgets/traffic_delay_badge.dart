import 'package:flutter/material.dart';

import 'package:smart_ar_navigation/core/enums/traffic_severity.dart';
import 'package:smart_ar_navigation/models/traffic_segment_info.dart';

class TrafficDelayBadge extends StatelessWidget {
  final TrafficSegmentInfo segmentInfo;

  const TrafficDelayBadge({super.key, required this.segmentInfo});

  // Matches TrafficProgressBar's saturated fill colors, so the badge and
  // the in-jam progress bar read as the same severity language.
  Color get _backgroundColor {
    switch (segmentInfo.severity) {
      case TrafficSeverity.moderate:
        return const Color(0xFFFFA726);
      case TrafficSeverity.heavy:
        return const Color(0xFFE53935);
    }
  }

  // Near-black shades from the same amber/red family as _backgroundColor —
  // picked for luminance contrast (~7:1 and ~4.6:1 respectively against
  // their background), not just a different hue. The previous mid-tone
  // shades (0xFF7A4A00 / 0xFF7A0000) were too close in brightness to the
  // saturated pill background to read clearly.
  Color get _foregroundColor {
    switch (segmentInfo.severity) {
      case TrafficSeverity.moderate:
        return const Color(0xFF3D2400);
      case TrafficSeverity.heavy:
        return const Color(0xFF260000);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_car,
              color: _foregroundColor,
              size: 26,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${segmentInfo.delayMinutes} min delay',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _foregroundColor,
                  ),
                ),
                Text(
                  '~2 km ahead',
                  style: TextStyle(
                    fontSize: 12,
                    // Solid, not faded — fading toward the colored
                    // background would erode the same contrast margin
                    // being fixed for the line above.
                    color: _foregroundColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
