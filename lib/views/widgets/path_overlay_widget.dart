import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:smart_ar_navigation/core/enums/turn_direction.dart';

// ── Pulse stage ───────────────────────────────────────────────────────────────

enum _PulseStage { calm, slow, gentle, medium, fast }

_PulseStage _pulseStageFor(double distance) {
  if (distance > 800) return _PulseStage.calm;
  if (distance > 500) return _PulseStage.slow;
  if (distance > 200) return _PulseStage.gentle;
  if (distance > 50)  return _PulseStage.medium;
  return _PulseStage.fast;
}

// ── Widget ────────────────────────────────────────────────────────────────────

class PathOverlayWidget extends StatefulWidget {
  const PathOverlayWidget({
    super.key,
    required this.direction,
    required this.distanceToTurn,
    this.exitNumber,
  });

  final TurnDirection direction;
  final double distanceToTurn;
  final int? exitNumber;

  @override
  State<PathOverlayWidget> createState() => _PathOverlayWidgetState();
}

class _PathOverlayWidgetState extends State<PathOverlayWidget>
    with TickerProviderStateMixin {
  // ── Curve / position controllers ───────────────────────────────────────────
  late AnimationController _intensityController;
  late AnimationController _positionController;
  late Tween<double> _intensityTween;
  late Tween<double> _positionTween;
  late Animation<double> _intensityAnim;
  late Animation<double> _positionAnim;

  // ── Pulse controller ───────────────────────────────────────────────────────
  late AnimationController _pulseController;
  _PulseStage _stage = _PulseStage.calm;

  // ── Colour constants ───────────────────────────────────────────────────────
  static const _cyan   = Color(0xFF00E676);
  static const _yellow = Color(0xFFFFC107);
  static const _red    = Color(0xFFFF5252);

  // ── Static helpers ─────────────────────────────────────────────────────────
  static double _intensityFor(double distance) {
    if (distance > 800) return 0.0;
    if (distance > 500) return 0.15;
    if (distance > 200) return 0.4;
    if (distance > 50)  return 0.7;
    return 1.0;
  }

  static double _targetOffset(TurnDirection direction, double intensity) =>
      switch (direction) {
        TurnDirection.forward    =>  0.0,
        TurnDirection.left       => -0.35 * intensity,
        TurnDirection.right      =>  0.35 * intensity,
        TurnDirection.uTurn      => -0.50 * intensity,
        TurnDirection.keepLeft   => -0.20 * intensity,
        TurnDirection.keepRight  =>  0.20 * intensity,
        TurnDirection.roundabout =>  0.0,
      };

  static (double min, double max) _opacityRange(_PulseStage stage) =>
      switch (stage) {
        _PulseStage.calm   => (0.85, 0.85),
        _PulseStage.slow   => (0.75, 0.95),
        _PulseStage.gentle => (0.70, 1.00),
        _PulseStage.medium => (0.60, 1.00),
        _PulseStage.fast   => (0.50, 1.00),
      };

  static Color _colorFor(_PulseStage stage) => switch (stage) {
        _PulseStage.calm   => _cyan,
        _PulseStage.slow   => _cyan,
        _PulseStage.gentle => _cyan,
        _PulseStage.medium => _yellow,
        _PulseStage.fast   => _red,
      };

  static double _glowRadiusFor(_PulseStage stage) =>
      stage == _PulseStage.fast ? 25.0 : 15.0;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    final initIntensity = _intensityFor(widget.distanceToTurn);
    final initOffset    = _targetOffset(widget.direction, initIntensity);

    _intensityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _intensityTween = Tween<double>(begin: initIntensity, end: initIntensity);
    _intensityAnim  = _intensityTween.animate(
      CurvedAnimation(parent: _intensityController, curve: Curves.easeInOut),
    );

    _positionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _positionTween = Tween<double>(begin: initOffset, end: initOffset);
    _positionAnim  = _positionTween.animate(
      CurvedAnimation(parent: _positionController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(vsync: this);
    _applyPulse(_pulseStageFor(widget.distanceToTurn));
  }

  void _applyPulse(_PulseStage newStage) {
    _stage = newStage;
    _pulseController.stop();
    if (newStage == _PulseStage.calm) return;

    _pulseController.duration = Duration(
      milliseconds: switch (newStage) {
        _PulseStage.slow   => 3000,
        _PulseStage.gentle => 2000,
        _PulseStage.medium => 1000,
        _PulseStage.fast   => 400,
        _PulseStage.calm   => 3000,
      },
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(PathOverlayWidget old) {
    super.didUpdateWidget(old);

    final newIntensity = _intensityFor(widget.distanceToTurn);
    final oldIntensity = _intensityFor(old.distanceToTurn);
    final dirChanged   = widget.direction != old.direction;

    if (newIntensity != oldIntensity) {
      _intensityTween
        ..begin = _intensityAnim.value
        ..end   = newIntensity;
      _intensityController
        ..reset()
        ..forward();
    }

    if (dirChanged || newIntensity != oldIntensity) {
      _positionController.duration = Duration(
        milliseconds: dirChanged ? 600 : 400,
      );
      _positionTween
        ..begin = _positionAnim.value
        ..end   = _targetOffset(widget.direction, newIntensity);
      _positionController
        ..reset()
        ..forward();
    }

    final newStage = _pulseStageFor(widget.distanceToTurn);
    if (newStage != _stage) _applyPulse(newStage);
  }

  @override
  void dispose() {
    _intensityController.dispose();
    _positionController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _intensityController,
        _positionController,
        _pulseController,
      ]),
      builder: (ctx, child) {
        final (opMin, opMax) = _opacityRange(_stage);
        final t       = _stage == _PulseStage.calm ? 0.0 : _pulseController.value;
        final opacity = opMin + (opMax - opMin) * t;

        return CustomPaint(
          painter: PathPainter(
            vanishingOffset: _positionAnim.value,
            arcIntensity:    _intensityAnim.value,
            opacity:         opacity,
            pathColor:       _colorFor(_stage),
            glowRadius:      _glowRadiusFor(_stage),
            isRoundabout:    widget.direction == TurnDirection.roundabout,
            exitNumber:      widget.exitNumber,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────

class PathPainter extends CustomPainter {
  const PathPainter({
    required this.vanishingOffset,
    required this.arcIntensity,
    required this.opacity,
    required this.pathColor,
    required this.glowRadius,
    this.isRoundabout = false,
    this.exitNumber,
  });

  // Fraction of (width / 2): positive = right, negative = left.
  final double vanishingOffset;
  // 0.0–1.0 intensity used for roundabout arc depth.
  final double arcIntensity;
  final double opacity;
  final Color  pathColor;
  final double glowRadius;
  final bool   isRoundabout;
  final int?   exitNumber;

  @override
  void paint(Canvas canvas, Size size) {
    if (isRoundabout && arcIntensity > 0.01) {
      _paintRoundabout(canvas, size);
    } else {
      _paintStraight(canvas, size);
    }
  }

  // ── Straight / curved path (non-roundabout) ───────────────────────────────

  void _paintStraight(Canvas canvas, Size size) {
    final cx         = size.width / 2;
    final h          = size.height;
    final vanishingX = cx + size.width * vanishingOffset;

    canvas.drawPath(
      _buildPath(cx, vanishingX, h, bottomHalf: 50, topHalf: 5),
      Paint()
        ..color = pathColor.withValues(alpha: opacity * 0.28)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius),
    );

    canvas.drawPath(
      _buildPath(cx, vanishingX, h, bottomHalf: 40, topHalf: 3),
      Paint()
        ..color = pathColor.withValues(alpha: opacity)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      _buildPath(cx, vanishingX, h, bottomHalf: 8, topHalf: 1),
      Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.67)
        ..style = PaintingStyle.fill,
    );
  }

  // Tapered quad with quadratic bezier sides for perspective.
  Path _buildPath(
    double bottomCx,
    double topCx,
    double h, {
    required double bottomHalf,
    required double topHalf,
  }) {
    const topFrac    = 0.38;
    const bottomFrac = 0.95;
    const ctrlFrac   = (topFrac + bottomFrac) / 2;

    final top    = h * topFrac;
    final bottom = h * bottomFrac;
    final ctrlY  = h * ctrlFrac;

    final t = (bottomFrac - ctrlFrac) / (bottomFrac - topFrac);

    final leftAtCtrl   = (bottomCx - bottomHalf) * (1 - t) + (topCx - topHalf) * t;
    final rightAtCtrl  = (bottomCx + bottomHalf) * (1 - t) + (topCx + topHalf) * t;
    final centerAtCtrl =  bottomCx               * (1 - t) +  topCx             * t;

    final ctrlLeft  = leftAtCtrl  + (centerAtCtrl - leftAtCtrl)  * 0.3;
    final ctrlRight = rightAtCtrl - (rightAtCtrl - centerAtCtrl) * 0.3;

    return Path()
      ..moveTo(bottomCx - bottomHalf, bottom)
      ..quadraticBezierTo(ctrlLeft,  ctrlY, topCx - topHalf, top)
      ..lineTo(topCx + topHalf, top)
      ..quadraticBezierTo(ctrlRight, ctrlY, bottomCx + bottomHalf, bottom)
      ..close();
  }

  // ── Roundabout arc path ───────────────────────────────────────────────────

  // Base arc sweep per exit number (radians):
  //   + = clockwise (right-side exit)   – = counterclockwise (left-side exit)
  //
  // exit 1 → first exit, quick right:           +90°
  // exit 2 → straight-ish, very gentle bow:     +22.5°
  // exit 3 → left exit:                         −90°
  // exit 4 → near U-turn, half loop:            +180°
  // null   → default gentle right:              +45°
  static double _baseSweep(int? exit) => switch (exit) {
        null => math.pi / 4,
        1    => math.pi / 2,
        2    => math.pi / 8,
        3    => -(math.pi / 2),
        4    => math.pi,
        _    => math.pi / 4,
      };

  void _paintRoundabout(Canvas canvas, Size size) {
    final centerPath = _buildRoundaboutCenterline(size);

    // Glow
    canvas.drawPath(
      centerPath,
      Paint()
        ..color = pathColor.withValues(alpha: opacity * 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 60
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius),
    );

    // Main
    canvas.drawPath(
      centerPath,
      Paint()
        ..color = pathColor.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 45
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Highlight
    canvas.drawPath(
      centerPath,
      Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.67)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  // Builds the centerline of the roundabout path:
  //   1. Straight entry from bottom to merge point (h × 0.65)
  //   2. Circular arc curving toward the exit direction
  //   3. Short straight tail in the exit direction
  Path _buildRoundaboutCenterline(Size size) {
    final cx     = size.width / 2;
    final h      = size.height;
    final mergeY = h * 0.65;
    final entryY = h * 0.95;

    final effectiveSweep = _baseSweep(exitNumber) * arcIntensity;

    if (effectiveSweep.abs() < 0.01) {
      // Intensity not yet significant — show straight entry stub.
      return Path()
        ..moveTo(cx, entryY)
        ..lineTo(cx, mergeY - 30);
    }

    final isRight    = effectiveSweep > 0;
    final arcRadius  = cx * 0.45;
    final arcCenterX = isRight ? cx + arcRadius : cx - arcRadius;
    final startAngle = isRight ? math.pi : 0.0;

    final path = Path()
      ..moveTo(cx, entryY)
      ..lineTo(cx, mergeY);

    path.arcTo(
      Rect.fromCircle(center: Offset(arcCenterX, mergeY), radius: arcRadius),
      startAngle,
      effectiveSweep,
      false,
    );

    // Short tail in exit direction so the path doesn't end bluntly on the arc.
    final endAngle = startAngle + effectiveSweep;
    final exitX    = arcCenterX + arcRadius * math.cos(endAngle);
    final exitY    = mergeY    + arcRadius * math.sin(endAngle);

    // Tangent at arc exit:
    //   clockwise   (isRight)  → (−sin θ,  cos θ)
    //   counterclockwise       → ( sin θ, −cos θ)
    final tx = isRight ? -math.sin(endAngle) :  math.sin(endAngle);
    final ty = isRight ?  math.cos(endAngle) : -math.cos(endAngle);

    final tailLen = 40.0 * arcIntensity;
    path.lineTo(exitX + tx * tailLen, exitY + ty * tailLen);

    return path;
  }

  @override
  bool shouldRepaint(PathPainter old) =>
      old.vanishingOffset != vanishingOffset ||
      old.arcIntensity    != arcIntensity    ||
      old.opacity         != opacity         ||
      old.pathColor       != pathColor       ||
      old.glowRadius      != glowRadius      ||
      old.isRoundabout    != isRoundabout    ||
      old.exitNumber      != exitNumber;
}
