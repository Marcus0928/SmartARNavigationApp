import 'package:flutter/material.dart';

class SpeedIndicator extends StatelessWidget {
  const SpeedIndicator({super.key, this.speedMs});

  final double? speedMs;

  @override
  Widget build(BuildContext context) {
    final kmh = speedMs != null ? (speedMs! * 3.6).round() : 0;

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(10),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$kmh',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.0,
                color: Color(0xFF212121),
              ),
            ),
            const Text(
              'km/h',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
