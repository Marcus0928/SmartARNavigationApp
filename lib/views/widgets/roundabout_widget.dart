import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:smart_ar_navigation/core/enums/navigation_approach_stage.dart';

class RoundaboutWidget extends StatefulWidget {
  const RoundaboutWidget({
    super.key,
    required this.distance,
    required this.approachStage,
    this.exitNumber,
    this.streetName,
  });

  final double distance;
  final NavigationApproachStage approachStage;
  final int? exitNumber;
  final String? streetName;

  @override
  State<RoundaboutWidget> createState() => _RoundaboutWidgetState();
}

class _RoundaboutWidgetState extends State<RoundaboutWidget>
    with TickerProviderStateMixin {
  // Animation 1 — rotating ring
  late AnimationController _rotateController;

  // Animation 2 — distance-based pulse
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Animation 3 — entrance scale
  late AnimationController _entranceController;
  late Animation<double> _entranceAnimation;

  @override
  void initState() {
    super.initState();

    _rotateController = AnimationController(vsync: this);
    _updateRotation(widget.approachStage);

    _pulseController = AnimationController(vsync: this);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _updatePulse(widget.approachStage);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _entranceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.elasticOut),
    );
    _entranceController.forward();
  }

  void _updateRotation(NavigationApproachStage stage) {
    _rotateController.stop();
    _rotateController.duration = switch (stage) {
      NavigationApproachStage.far         => const Duration(seconds: 3),
      NavigationApproachStage.approaching => const Duration(seconds: 2),
      NavigationApproachStage.imminent    => const Duration(seconds: 1),
    };
    _rotateController.repeat();
  }

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
  void didUpdateWidget(RoundaboutWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.approachStage != oldWidget.approachStage) {
      _updateRotation(widget.approachStage);
      _updatePulse(widget.approachStage);
    }
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pulseController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _rotateController,
        _pulseController,
        _entranceController,
      ]),
      builder: (_, __) {
        final glowColor = widget.approachStage == NavigationApproachStage.imminent
            ? const Color(0xFFFFC107)
            : const Color(0xFF00E676);

        // Map pulse scale 0.95–1.05 → glow opacity 0.10–0.25
        final glowOpacity =
            0.10 + (_pulseAnimation.value - 0.95) / 0.10 * 0.15;

        return Transform.scale(
          scale: _entranceAnimation.value,
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: SizedBox(
              width: 180,
              height: 180,
              child: CustomPaint(
                painter: _RoundaboutPainter(
                  exitNumber: widget.exitNumber,
                  glowOpacity: glowOpacity.clamp(0.0, 1.0),
                  glowColor: glowColor,
                  rotationAngle: _rotateController.value * 2 * math.pi,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RoundaboutPainter extends CustomPainter {
  const _RoundaboutPainter({
    required this.exitNumber,
    required this.glowOpacity,
    required this.glowColor,
    required this.rotationAngle,
  });

  final int? exitNumber;
  final double glowOpacity;
  final Color glowColor;
  final double rotationAngle; // 0 → 2π over 3 s

  static const _cyan = Color(0xFF00E676);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Layer 1 — Glow (filled, radius 80, colour + opacity change near turn)
    canvas.drawCircle(
      center,
      80,
      Paint()
        ..color = glowColor.withValues(alpha: glowOpacity)
        ..style = PaintingStyle.fill,
    );

    // Layer 2 — Dark background (filled, radius 65)
    canvas.drawCircle(
      center,
      65,
      Paint()
        ..color = const Color(0xCC000000)
        ..style = PaintingStyle.fill,
    );

    // Layer 3 — Rotating dashed ring (radius 60, stroke 6px)
    // The dashes orbit the circle at rotationAngle; content inside stays fixed.
    _paintRotatingRing(canvas, center);

    // Layer 5 — Exit arrow (fixed, painted before number so number sits on top)
    _paintExitArrow(canvas, center);

    // Layer 4 — Exit number (fixed, only when provided)
    if (exitNumber != null) {
      final tp = TextPainter(
        text: TextSpan(
          text: '$exitNumber',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    }
  }

  // 12 dashes evenly spaced; each occupies 65% of its slot, gap 35%.
  // The whole pattern rotates clockwise via rotationAngle.
  void _paintRotatingRing(Canvas canvas, Offset center) {
    const dashCount = 12;
    const slotAngle = 2 * math.pi / dashCount;
    const fillFraction = 0.65;

    final rect = Rect.fromCircle(center: center, radius: 60);
    final paint = Paint()
      ..color = _cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < dashCount; i++) {
      final start = rotationAngle + i * slotAngle;
      canvas.drawArc(rect, start, slotAngle * fillFraction, false, paint);
    }
  }

  // Exit 1 → right (0), 2 → up (−π/2), 3 → left (±π), 4 → down (π/2).
  // Null exitNumber defaults to forward-right (−π/4).
  double get _exitAngle {
    if (exitNumber != null) {
      return math.pi / 2 - exitNumber! * (math.pi / 2);
    }
    return -math.pi / 4;
  }

  void _paintExitArrow(Canvas canvas, Offset center) {
    final angle = _exitAngle;
    // Arrow starts at the ring edge (r = 60) and extends 40px outward.
    final edgePoint = center + Offset(math.cos(angle) * 60, math.sin(angle) * 60);
    final tipPoint  = center + Offset(math.cos(angle) * 100, math.sin(angle) * 100);

    final paint = Paint()
      ..color = _cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(edgePoint, tipPoint, paint);

    // Arrowhead — two lines spreading 36° from the tip back toward the shaft
    const spread = math.pi / 5;
    const headLen = 14.0;
    canvas.drawLine(
      tipPoint,
      Offset(tipPoint.dx - headLen * math.cos(angle - spread),
             tipPoint.dy - headLen * math.sin(angle - spread)),
      paint,
    );
    canvas.drawLine(
      tipPoint,
      Offset(tipPoint.dx - headLen * math.cos(angle + spread),
             tipPoint.dy - headLen * math.sin(angle + spread)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_RoundaboutPainter old) =>
      old.exitNumber != exitNumber ||
      old.glowOpacity != glowOpacity ||
      old.glowColor != glowColor ||
      old.rotationAngle != rotationAngle;
}
