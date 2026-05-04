import 'dart:math';
import 'package:flutter/material.dart';
import 'package:smart_ar_navigation/core/constants/app_colors.dart';

class RoundaboutWidget extends StatelessWidget {
  const RoundaboutWidget({
    super.key,
    required this.exitNumber,
    this.size = 56,
  });

  final int exitNumber;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _RoundaboutPainter(exitNumber: exitNumber.clamp(1, 4)),
    );
  }
}

class _RoundaboutPainter extends CustomPainter {
  const _RoundaboutPainter({required this.exitNumber});
  final int exitNumber;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ringRadius = size.width * 0.28;
    final arrowLen = size.width * 0.20;
    final strokeW = size.width * 0.075;

    final paint = Paint()
      ..color = arArrowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    // Roundabout ring
    canvas.drawCircle(center, ringRadius, paint);

    // Entry arrow: from outside bottom pointing up into ring
    final entryOuter = Offset(center.dx, center.dy + ringRadius + arrowLen);
    final entryInner = Offset(center.dx, center.dy + ringRadius);
    canvas.drawLine(entryOuter, entryInner, paint);
    _drawArrowHead(canvas, entryInner, -pi / 2, strokeW, paint);

    // Exit arrow: each exit is 90° counterclockwise from the entry (bottom)
    // Exit 1 = right (3 o'clock), 2 = top (12 o'clock), 3 = left (9 o'clock), 4 = bottom (U-turn)
    final exitAngle = pi / 2 - exitNumber * (pi / 2);
    final exitInner = Offset(
      center.dx + cos(exitAngle) * ringRadius,
      center.dy + sin(exitAngle) * ringRadius,
    );
    final exitOuter = Offset(
      center.dx + cos(exitAngle) * (ringRadius + arrowLen),
      center.dy + sin(exitAngle) * (ringRadius + arrowLen),
    );
    canvas.drawLine(exitInner, exitOuter, paint);
    _drawArrowHead(canvas, exitOuter, exitAngle, strokeW, paint);

    // Exit number in centre of ring
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$exitNumber',
        style: TextStyle(
          color: arArrowColor,
          fontSize: size.width * 0.30,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  void _drawArrowHead(
    Canvas canvas,
    Offset tip,
    double angle,
    double size,
    Paint paint,
  ) {
    const spread = pi / 5;
    final p1 = Offset(
      tip.dx - size * cos(angle - spread),
      tip.dy - size * sin(angle - spread),
    );
    final p2 = Offset(
      tip.dx - size * cos(angle + spread),
      tip.dy - size * sin(angle + spread),
    );
    canvas.drawLine(tip, p1, paint);
    canvas.drawLine(tip, p2, paint);
  }

  @override
  bool shouldRepaint(_RoundaboutPainter old) => old.exitNumber != exitNumber;
}
