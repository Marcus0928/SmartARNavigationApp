import 'package:flutter/material.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/core/enums/turn_direction.dart';

class TurnArrowWidget extends StatelessWidget {
  const TurnArrowWidget({super.key, required this.direction, this.size = 56});

  final TurnDirection direction;
  final double size;

  IconData get _icon => switch (direction) {
        TurnDirection.forward => Icons.arrow_upward_rounded,
        TurnDirection.left => Icons.turn_left_rounded,
        TurnDirection.keepLeft => Icons.turn_slight_left_rounded,
        TurnDirection.right => Icons.turn_right_rounded,
        TurnDirection.keepRight => Icons.turn_slight_right_rounded,
        TurnDirection.uTurn => Icons.u_turn_left_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Icon(_icon, size: size, color: arArrowColor);
  }
}
