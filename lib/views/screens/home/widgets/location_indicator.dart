import 'dart:math' as math;

import 'package:flutter/material.dart';

class LocationIndicator extends StatelessWidget {
  const LocationIndicator({super.key, required this.heading});

  final double heading;

  static const _blue = Color(0xFF1A73E8);

  @override
  Widget build(BuildContext context) {
    final angle = heading * math.pi / 180.0;

    return Transform.rotate(
      angle: angle,
      child: const Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.navigation_rounded, color: Colors.white, size: 42),
          Icon(Icons.navigation_rounded, color: _blue, size: 32),
        ],
      ),
    );
  }
}
