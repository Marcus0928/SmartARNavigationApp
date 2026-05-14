import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_ar_navigation/viewmodels/ar_viewmodel.dart';

/// Distance (top-left) and street name (top-right) floating directly over
/// the camera feed. No background — readability comes from dark text shadows.
class AROverlayWidget extends StatelessWidget {
  const AROverlayWidget({super.key});

  static const _shadow = [
    Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(1, 1)),
    Shadow(color: Colors.black,   blurRadius: 14),
  ];

  @override
  Widget build(BuildContext context) {
    final arVM = context.watch<ARViewModel>();
    if (arVM.nextTurnDirection == null) return const SizedBox.shrink();

    final distance = arVM.distanceToNextTurn ?? double.infinity;

    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Distance — top left, dominant
          Text(
            _formatDistance(distance),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.0,
              shadows: _shadow,
            ),
          ),

          const Spacer(),

          // Street name — top right, secondary
          if (arVM.currentStreetName != null)
            Flexible(
              child: Text(
                arVM.currentStreetName!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  shadows: _shadow,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
        ],
      ),
    );
  }

  String _formatDistance(double metres) {
    if (metres >= 1000) return '${(metres / 1000).toStringAsFixed(1)} km';
    return '${metres.toInt()} m';
  }
}
