import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/core/enums/navigation_approach_stage.dart';
import 'package:smart_ar_navigation/core/enums/turn_direction.dart';

class DynamicArrowWidget extends StatefulWidget {
  const DynamicArrowWidget({
    super.key,
    required this.direction,
    required this.distance,
    required this.approachStage,
    this.size = 180,
    this.showLabel = true,
    this.exitNumber,
  });

  final TurnDirection direction;
  final double distance;
  final NavigationApproachStage approachStage;
  final double size;
  final bool showLabel;
  final int? exitNumber;

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

    final initialColor = _colorForStage(widget.approachStage);
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
    _updatePulse(widget.approachStage);

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
    if (widget.approachStage != oldWidget.approachStage) {
      _updatePulse(widget.approachStage);
    }
    if (widget.direction != oldWidget.direction) {
      _directionController.forward(from: 0.0);
    }
    final newColor = _colorForStage(widget.approachStage);
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

  Color _colorForStage(NavigationApproachStage stage) => switch (stage) {
        NavigationApproachStage.far         => arArrowColor,
        NavigationApproachStage.approaching => const Color(0xFFFFC107),
        NavigationApproachStage.imminent    => const Color(0xFFFF5252),
      };

  void _updatePulse(NavigationApproachStage stage) {
    _pulseController.stop();
    _pulseController.duration = Duration(
      milliseconds: switch (stage) {
        NavigationApproachStage.far         => 2000,
        NavigationApproachStage.approaching => 1000,
        NavigationApproachStage.imminent    => 400,
      },
    );
    _pulseController.repeat(reverse: true);
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
                      widget.exitNumber,
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
                      _labelText(),
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

  String _labelText() {
    if (widget.direction == TurnDirection.roundabout) {
      return widget.exitNumber != null
          ? 'Take Exit ${widget.exitNumber}'
          : 'Take the Exit';
    }
    return _distanceLabel(widget.distance);
  }

  String _distanceLabel(double distance) {
    if (distance < 50) return 'Turn now!';
    if (distance >= 1000) return 'In ${(distance / 1000).toStringAsFixed(1)}km';
    final rounded = ((distance / 10).round() * 10).clamp(10, 990);
    return 'In ${rounded}m';
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter(this.direction, this.color, this.flowT, [this.exitNumber]);

  final TurnDirection direction;
  final Color color;
  final double flowT;
  final int? exitNumber;

  double get _angle => switch (direction) {
        TurnDirection.forward  => 0,
        TurnDirection.right    => math.pi / 2,
        TurnDirection.uTurn    => math.pi,
        TurnDirection.left     => -math.pi / 2,
        _                      => 0, // keepLeft/keepRight/roundabout handled separately
      };

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 120.0;

    switch (direction) {
      case TurnDirection.roundabout:
        _paintRoundabout(canvas, size, scale);
        return;
      case TurnDirection.keepLeft: {
        final cx = size.width / 2;
        final cy = size.height / 2;
        // Mirror keepRight horizontally — rotation reverses automatically
        canvas.translate(size.width, 0);
        canvas.scale(-1, 1);
        canvas.translate(cx, cy);
        canvas.rotate(-15 * math.pi / 180); // visually +15° after mirror
        canvas.scale(0.8);
        canvas.rotate(math.pi / 2);
        canvas.translate(-cx, -cy);
        _paintChevrons(canvas, size, scale, mainStroke: 12.0, count: 2);
        return;
      }
      case TurnDirection.keepRight: {
        final cx = size.width / 2;
        final cy = size.height / 2;
        canvas.translate(cx, cy);
        canvas.rotate(-15 * math.pi / 180); // tilt upward → gentle merge feel
        canvas.scale(0.8);                  // 80% of full right
        canvas.rotate(math.pi / 2);         // same 90° CW rotation as right
        canvas.translate(-cx, -cy);
        _paintChevrons(canvas, size, scale, mainStroke: 12.0, count: 2);
        return;
      }
      case TurnDirection.forward:
        _paintChevrons(canvas, size, scale, mainStroke: 12.0);
        return;
      case TurnDirection.uTurn:
        _paintUTurn(canvas, size, scale);
        return;
      case TurnDirection.left: {
        // Mirror right horizontally for pixel-perfect symmetry with right
        final cx = size.width / 2;
        final cy = size.height / 2;
        canvas.translate(size.width, 0);
        canvas.scale(-1, 1);
        canvas.translate(cx, cy);
        canvas.rotate(math.pi / 2);
        canvas.translate(-cx, -cy);
        _paintChevrons(canvas, size, scale, mainStroke: 12.0);
        return;
      }
      default:
        break;
    }

    if (_angle != 0) {
      final cx = size.width / 2;
      final cy = size.height / 2;
      canvas.translate(cx, cy);
      canvas.rotate(_angle);
      canvas.translate(-cx, -cy);
    }

    _paintChevrons(canvas, size, scale, mainStroke: 12.0);
  }

  // 3 stacked chevrons (^) with a flowing bottom→top opacity wave.
  //
  // Canvas layout (top→bottom): canvasIdx 0 = top chevron (leading edge),
  //   canvasIdx 2 = bottom (trailing). Flow travels bottom→top so the
  //   wave sweeps flowIdx 0 (bottom) → 1 (mid) → 2 (top) as flowT: 0→1.
  void _paintChevrons(Canvas canvas, Size size, double scale,
      {double mainStroke = 8.0, int count = 3}) {
    final cx    = size.width / 2;
    final h     = size.height;
    final halfW = size.width * 0.38;
    final armH  = h * 0.14;

    for (int canvasIdx = 0; canvasIdx < count; canvasIdx++) {
      // Evenly space: count=3 → 0.25/0.50/0.75, count=2 → 0.33/0.67
      final cy      = h / (count + 1) * (canvasIdx + 1);
      final flowIdx = (count - 1) - canvasIdx;

      final halfN = count / 2.0;
      final peak  = flowT * count.toDouble();
      double dist = (peak - flowIdx).abs();
      if (dist > halfN) dist = count.toDouble() - dist;
      final opacity = (1.0 - dist / halfN).clamp(0.25, 1.0);

      final path = Path()
        ..moveTo(cx - halfW, cy + armH / 2)
        ..lineTo(cx,         cy - armH / 2)
        ..lineTo(cx + halfW, cy + armH / 2);

      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.3 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = mainStroke * 2.0 * scale
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = mainStroke * scale
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  // U-shaped arc: left stem up → semicircle over top → right stem down → arrowhead.
  // Arc uses clockwise sweep so it curves UPWARD (over the top) between the two stems.
  void _paintUTurn(Canvas canvas, Size size, double scale) {
    final cx = size.width / 2;
    final h  = size.height;
    final r  = size.width * 0.18; // arc radius → U width = 36% of widget

    final topY       = h * 0.26;  // arc centre Y (upper quarter)
    final stemBottom = h * 0.78;  // bottom of both stems
    const mainStroke = 12.0;
    const headLen    = 14.0;
    const headW      =  9.0;

    final stemEnd = stemBottom - headLen * scale; // right stem stops here

    // ── U path ────────────────────────────────────────────────────────
    final uPath = Path()
      ..moveTo(cx - r, stemBottom)   // bottom of left stem
      ..lineTo(cx - r, topY)         // up to arc start
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, topY), radius: r),
        math.pi,  // start at left  (9 o'clock)
        math.pi,  // +180° clockwise → curves up over the top to right
        false,
      )
      ..lineTo(cx + r, stemEnd);     // right stem down to arrow base

    // Glow layer
    canvas.drawPath(
      uPath,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = mainStroke * 2.0 * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Main stroke
    canvas.drawPath(
      uPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = mainStroke * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // ── Arrowhead at bottom of right stem, pointing DOWN ──────────────
    final arrowHead = Path()
      ..moveTo(cx + r,                 stemBottom) // tip
      ..lineTo(cx + r - headW * scale, stemEnd)   // base left
      ..lineTo(cx + r + headW * scale, stemEnd)   // base right
      ..close();

    canvas.drawPath(
      arrowHead,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0 * scale),
    );
    canvas.drawPath(
      arrowHead,
      Paint()..color = color..style = PaintingStyle.fill,
    );
  }

  // 3/4 circle CW: starts at lower-left (7:30 o'clock = 135° Flutter),
  // sweeps 270° clockwise, ends at lower-right (4:30 o'clock = 45° Flutter).
  // Gap sits at the bottom (6 o'clock) — the approach side for the driver.
  // Entry indicator is a short line OUTSIDE the circle touching the arc start.
  // Exit arrow is a radially-outward arrowhead at the arc end.
  void _paintRoundabout(Canvas canvas, Size size, double scale) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width * 0.33;

    // Arc geometry
    const startAngle = 3 * math.pi / 4;  // 135° Flutter = lower-left
    const sweepAngle = 3 * math.pi / 2;  // +270° clockwise
    const endAngle   = math.pi / 4;       // 45°  Flutter = lower-right
    const mainStroke = 14.0;

    final arcRect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // ── Arc glow ──────────────────────────────────────────────────────
    canvas.drawArc(arcRect, startAngle, sweepAngle, false,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = mainStroke * 2.0 * scale
        ..strokeCap = StrokeCap.round);

    // ── Main arc ──────────────────────────────────────────────────────
    canvas.drawArc(arcRect, startAngle, sweepAngle, false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = mainStroke * scale
        ..strokeCap = StrokeCap.round);

    // ── Entry indicator: line from outside the circle to the arc start ─
    // Drawn from (r + 15px) outward to exactly (r) at startAngle.
    // Ends at the arc start → connected, not floating.
    final entryOnX  = cx + r                    * math.cos(startAngle);
    final entryOnY  = cy + r                    * math.sin(startAngle);
    final entryOutX = cx + (r + 15.0 * scale)  * math.cos(startAngle);
    final entryOutY = cy + (r + 15.0 * scale)  * math.sin(startAngle);

    canvas.drawLine(
      Offset(entryOutX, entryOutY),
      Offset(entryOnX,  entryOnY),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = mainStroke * scale
        ..strokeCap = StrokeCap.round);

    // ── Exit arrow: short stem + arrowhead pointing radially outward ───
    final exX = cx + r * math.cos(endAngle);   // arc end X
    final exY = cy + r * math.sin(endAngle);   // arc end Y
    // Outward direction (away from circle centre)
    final outDX  =  math.cos(endAngle);
    final outDY  =  math.sin(endAngle);
    // Perpendicular for arrowhead width
    final perpDX = -math.sin(endAngle);
    final perpDY =  math.cos(endAngle);

    const stemLen = 6.0;
    const headLen = 14.0;
    const headW   =  9.0;

    final baseX = exX + outDX * stemLen * scale;
    final baseY = exY + outDY * stemLen * scale;
    final tipX  = baseX + outDX * headLen * scale;
    final tipY  = baseY + outDY * headLen * scale;

    // Stem glow + main
    canvas.drawLine(
      Offset(exX, exY), Offset(baseX, baseY),
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = mainStroke * 2.0 * scale
        ..strokeCap = StrokeCap.round);
    canvas.drawLine(
      Offset(exX, exY), Offset(baseX, baseY),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = mainStroke * scale
        ..strokeCap = StrokeCap.round);

    // Arrowhead glow + fill
    final arrowHead = Path()
      ..moveTo(tipX, tipY)
      ..lineTo(baseX + perpDX * headW * scale, baseY + perpDY * headW * scale)
      ..lineTo(baseX - perpDX * headW * scale, baseY - perpDY * headW * scale)
      ..close();

    canvas.drawPath(arrowHead,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0 * scale));
    canvas.drawPath(arrowHead,
      Paint()..color = color..style = PaintingStyle.fill);

    // ── Exit number centered in circle (only when provided) ───────────
    if (exitNumber != null) {
      final tp = TextPainter(
        text: TextSpan(
          text: '$exitNumber',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36.0 * scale,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) =>
      oldDelegate.direction != direction ||
      oldDelegate.color != color ||
      oldDelegate.flowT != flowT ||
      oldDelegate.exitNumber != exitNumber;
}

