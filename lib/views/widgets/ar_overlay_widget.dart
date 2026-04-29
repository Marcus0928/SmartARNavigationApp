import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/viewmodels/ar_viewmodel.dart';
import 'package:smart_ar_navigation/views/widgets/turn_arrow_widget.dart';

class AROverlayWidget extends StatelessWidget {
  const AROverlayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final arVM = context.watch<ARViewModel>();

    if (arVM.nextTurnDirection == null) return const SizedBox.shrink();

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: overlayBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TurnArrowWidget(direction: arVM.nextTurnDirection!),
            const SizedBox(height: 8),
            Text(
              arVM.distanceToNextTurn != null
                  ? _formatDistance(arVM.distanceToNextTurn!)
                  : '',
              style: const TextStyle(
                color: arArrowColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (arVM.currentStreetName != null) ...[
              const SizedBox(height: 4),
              Text(
                arVM.currentStreetName!,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDistance(double metres) {
    if (metres >= 1000) return '${(metres / 1000).toStringAsFixed(1)} km';
    return '${metres.toInt()} m';
  }
}
