import 'package:flutter/material.dart';
import 'package:smart_ar_navigation/core/enums/turn_direction.dart';

class TurnArrowWidget extends StatelessWidget {
  final TurnDirection direction;
  final double size;

  const TurnArrowWidget({
    super.key,
    required this.direction,
    this.size = 80,
  });

  String get _assetPath {
    switch (direction) {
      case TurnDirection.left:
      case TurnDirection.keepLeft:
        return 'assets/icons/arrow_left.png';
      case TurnDirection.right:
      case TurnDirection.keepRight:
        return 'assets/icons/arrow_right.png';
      case TurnDirection.uTurn:
        return 'assets/icons/arrow_uturn.png';
      case TurnDirection.forward:
        return 'assets/icons/arrow_forward.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(_assetPath, width: size, height: size);
  }
}
