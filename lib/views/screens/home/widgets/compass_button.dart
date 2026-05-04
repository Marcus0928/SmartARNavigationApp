import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class CompassButton extends StatelessWidget {
  const CompassButton({
    super.key,
    required this.rotation,
    required this.onPressed,
  });

  final double rotation;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Reset North',
      child: Material(
        elevation: 4,
        shape: const CircleBorder(),
        color: Colors.white,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Transform.rotate(
              angle: -rotation * math.pi / 180.0,
              child: CustomPaint(painter: _CompassPainter()),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.28;

    canvas.drawPath(
      ui.Path()
        ..moveTo(cx, cy - r)
        ..lineTo(cx - r * 0.38, cy)
        ..lineTo(cx + r * 0.38, cy)
        ..close(),
      Paint()..color = const Color(0xFFE53935),
    );

    canvas.drawPath(
      ui.Path()
        ..moveTo(cx, cy + r)
        ..lineTo(cx - r * 0.38, cy)
        ..lineTo(cx + r * 0.38, cy)
        ..close(),
      Paint()..color = const Color(0xFFBDBDBD),
    );

    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.18,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_CompassPainter old) => false;
}
