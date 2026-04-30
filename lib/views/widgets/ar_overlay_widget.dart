import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/viewmodels/ar_viewmodel.dart';
import 'package:smart_ar_navigation/views/widgets/turn_arrow_widget.dart';

/// Turn instruction card. Renders nothing when there is no upcoming turn.
/// Positioning is handled by the parent screen.
class AROverlayWidget extends StatelessWidget {
  const AROverlayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final arVM = context.watch<ARViewModel>();

    if (arVM.nextTurnDirection == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Turn arrow
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: TurnArrowWidget(
                direction: arVM.nextTurnDirection!,
                size: 38,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                arVM.distanceToNextTurn != null
                    ? _formatDistance(arVM.distanceToNextTurn!)
                    : '',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  height: 1.0,
                ),
              ),
              if (arVM.currentStreetName != null) ...[
                const SizedBox(height: 4),
                Text(
                  arVM.currentStreetName!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
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
