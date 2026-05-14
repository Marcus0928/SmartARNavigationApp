import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/core/enums/turn_direction.dart';

class DynamicArrowWidget extends StatefulWidget {
  const DynamicArrowWidget({
    super.key,
    required this.direction,
    required this.distance,
    this.size = 180,
    this.showLabel = true,
  });

  final TurnDirection direction;
  final double distance;
  final double size;
  final bool showLabel;

  @override
  State<DynamicArrowWidget> createState() => _DynamicArrowWidgetState();
}

class _DynamicArrowWidgetState extends State<DynamicArrowWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _directionController;
  late AnimationController _colorController;
  late AnimationController _flowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _directionAnimation;
  late Color _colorFrom;
  late Color _colorTo;

  @override
  void initState() {
    super.initState();

    final initialColor = _colorForDistance(widget.distance);
    _colorFrom = initialColor;
    _colorTo   = initialColor;
    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _pulseController = AnimationController(vsync: this);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _updatePulse(widget.distance);

    _directionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _directionAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_directionController);

    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void didUpdateWidget(DynamicArrowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_pulseCategory(widget.distance) != _pulseCategory(oldWidget.distance)) {
      _updatePulse(widget.distance);
    }
    if (widget.direction != oldWidget.direction) {
      _directionController.forward(from: 0.0);
    }
    final newColor = _colorForDistance(widget.distance);
    if (newColor != _colorTo) {
      _colorFrom = Color.lerp(_colorFrom, _colorTo, _colorController.value)
          ?? _colorTo;
      _colorTo = newColor;
      _colorController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _directionController.dispose();
    _colorController.dispose();
    _flowController.dispose();
    super.dispose();
  }

  int _pulseCategory(double d) {
    if (d > 100) return 0;
    if (d >= 50) return 1;
    return 2;
  }

  void _updatePulse(double distance) {
    if (distance > 100) {
      _pulseController.stop();
      // value 0.5 maps to scale 1.0 in the 0.9–1.1 tween — no visible pulse.
      _pulseController.value = 0.5;
    } else {
      _pulseController.duration = Duration(
        milliseconds: distance >= 50 ? 2000 : 500,
      );
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseController,
        _directionController,
        _colorController,
        _flowController,
      ]),
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_colorController.value);
        final color = Color.lerp(_colorFrom, _colorTo, t) ?? _colorTo;
        return Transform.scale(
          scale: _pulseAnimation.value * _directionAnimation.value,
          child: Opacity(
            opacity: 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CustomPaint(
                    painter: _ArrowPainter(
                      widget.direction,
                      color,
                      _flowController.value,
                    ),
                  ),
                ),
                if (widget.showLabel) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xCC000000),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _distanceLabel(widget.distance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _distanceLabel(double distance) {
    if (distance < 50) return 'Turn now!';
    if (distance >= 1000) return 'In ${(distance / 1000).toStringAsFixed(1)}km';
    return 'In ${distance.toInt()}m';
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter(this.direction, this.color, this.flowT);

  final TurnDirection direction;
  final Color color;
  final double flowT;

  // Clockwise rotation in radians for straight-arrow directions.
  // roundabout is excluded — paint() dispatches it to _paintRoundabout.
  double get _angle => switch (direction) {
        TurnDirection.forward    => 0,
        TurnDirection.right      => math.pi / 2,
        TurnDirection.keepRight  => math.pi / 4,   // 45° clockwise
        TurnDirection.uTurn      => math.pi,
        TurnDirection.left       => -math.pi / 2,
        TurnDirection.keepLeft   => -math.pi / 4,  // 45° counter-clockwise
        TurnDirection.roundabout => 0,             // unused path
      };

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 120.0;

    if (direction == TurnDirection.roundabout) {
      _paintRoundabout(canvas, size, scale);
      return;
    }

    // Rotate around the canvas centre so the upward chevrons become the
    // correct direction without changing the chevron geometry.
    if (_angle != 0) {
      final cx = size.width / 2;
      final cy = size.height / 2;
      canvas.translate(cx, cy);
      canvas.rotate(_angle);
      canvas.translate(-cx, -cy);
    }

    _paintChevrons(canvas, size, scale);
  }

  // 3 stacked chevrons (^) with a flowing bottom→top opacity wave.
  //
  // Canvas layout (top→bottom): canvasIdx 0 = top chevron (leading edge),
  //   canvasIdx 2 = bottom (trailing). Flow travels bottom→top so the
  //   wave sweeps flowIdx 0 (bottom) → 1 (mid) → 2 (top) as flowT: 0→1.
  void _paintChevrons(Canvas canvas, Size size, double scale) {
    final cx = size.width / 2;
    final h = size.height;
    // Chevron half-width and arm height, proportional to canvas size
    final halfW = size.width * 0.38;
    final armH  = h * 0.14;

    for (int canvasIdx = 0; canvasIdx < 3; canvasIdx++) {
      final cy      = h * (0.25 + canvasIdx * 0.25); // 0.25 / 0.50 / 0.75
      final flowIdx = 2 - canvasIdx;                 // top=2, mid=1, bottom=0

      // Circular-distance from the travelling wave peak to this chevron.
      // peak sweeps 0→3 over one full cycle (3 chevrons).
      final peak = flowT * 3.0;
      double dist = (peak - flowIdx).abs();
      if (dist > 1.5) dist = 3.0 - dist; // wrap: seamless at cycle boundary
      final opacity = (1.0 - dist / 1.5).clamp(0.25, 1.0);

      final path = Path()
        ..moveTo(cx - halfW, cy + armH / 2)
        ..lineTo(cx,         cy - armH / 2)
        ..lineTo(cx + halfW, cy + armH / 2);

      // Layer 1 — wide glow: same color at 0.3 base opacity, modulated by wave
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.3 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16.0 * scale
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      // Layer 2 — sharp main stroke: full opacity, modulated by wave
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8.0 * scale
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  // Circular-arc arrow.
  //
  // Arc:  12 o'clock → 3 → 6 → 9 o'clock  (270° clockwise, leaving the
  //        upper-left quadrant open as a visual "gap" in the ring).
  // At the end point (9 o'clock, left side) the clockwise tangent is exactly
  // (0, −1), i.e. pointing straight UP — so the arrowhead caps the arc
  // pointing upward and fills the gap, completing the circular-arrow look.
  void _paintRoundabout(Canvas canvas, Size size, double scale) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.27; // proportional arc centre-line radius

    final arcRect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    const startAngle = -math.pi / 2; // 12 o'clock
    const sweepAngle = 3 * math.pi / 2; // 270° clockwise

    // Shadow arc (offset + blurred)
    canvas.drawArc(
      arcRect.shift(Offset(3 * scale, 5 * scale)),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = const Color(0x66000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.0 * scale)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16.0 * scale
        ..strokeCap = StrokeCap.round,
    );

    // White border arc
    canvas.drawArc(
      arcRect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16.0 * scale
        ..strokeCap = StrokeCap.round,
    );

    // Cyan arc
    canvas.drawArc(
      arcRect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10.0 * scale
        ..strokeCap = StrokeCap.round,
    );

    // Arrowhead at arc end: (cx − r, cy), pointing UP
    final ex = cx - r;
    final ey = cy;
    final arrowHead = Path()
      ..moveTo(ex, ey - 13 * scale)           // tip
      ..lineTo(ex + 10 * scale, ey + 7 * scale) // base-right
      ..lineTo(ex - 10 * scale, ey + 7 * scale) // base-left
      ..close();

    canvas.drawPath(
      arrowHead,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0 * scale
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(arrowHead, Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) =>
      oldDelegate.direction != direction ||
      oldDelegate.color != color ||
      oldDelegate.flowT != flowT;
}

Color _colorForDistance(double distance) {
  if (distance > 100) return arArrowColor;
  if (distance >= 50) return const Color(0xFFFFC107); // amber
  return const Color(0xFFFF5252); // red
}
