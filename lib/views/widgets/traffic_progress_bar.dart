import 'package:flutter/material.dart';

import 'package:smart_ar_navigation/core/enums/traffic_severity.dart';

class TrafficProgressBar extends StatelessWidget {
  final double progress;
  final int minutesToClear;
  final TrafficSeverity severity;

  const TrafficProgressBar({
    super.key,
    required this.progress,
    required this.minutesToClear,
    required this.severity,
  });

  static const double _barWidth = 14;
  static const double _barLeft = 10;
  static const double _arrowWidth = 30;
  static const double _arrowHeight = 26;
  static const double _labelWidth = 80;
  static const double _labelHeight = 40;
  static const double _gap = 8;

  Color get _fillColor {
    switch (severity) {
      case TrafficSeverity.moderate:
        return const Color(0xFFFFA726);
      case TrafficSeverity.heavy:
        return const Color(0xFFE53935);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    final arrowLeft = _barLeft + (_barWidth - _arrowWidth) / 2;
    final labelLeft = arrowLeft + _arrowWidth + _gap;
    final totalWidth = labelLeft + _labelWidth;

    // A single LayoutBuilder is the shared source of truth for `trackHeight`
    // — the bar's fill, the arrow's vertical position, and the label's
    // vertical position are all derived from this one value, so they can't
    // drift out of alignment with each other as progress changes.
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackHeight =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 0.0;
        final fillHeight = trackHeight * clampedProgress;

        // Both centered on the same fill-boundary height, so the arrow and
        // the label move together and stay aligned with the fill's edge.
        final arrowBottom = (fillHeight - _arrowHeight / 2)
            .clamp(0.0, (trackHeight - _arrowHeight).clamp(0.0, trackHeight));
        final labelBottom = (fillHeight - _labelHeight / 2)
            .clamp(0.0, (trackHeight - _labelHeight).clamp(0.0, trackHeight));

        return SizedBox(
          width: totalWidth,
          height: trackHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Track + colored fill — fills bottom-up to current progress;
              // the neutral track above stays the unfilled dark color.
              Positioned(
                left: _barLeft,
                bottom: 0,
                child: Container(
                  width: _barWidth,
                  height: trackHeight,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: clampedProgress,
                      // Without this, width defaults to the DecoratedBox
                      // child's own intrinsic size — and an empty
                      // DecoratedBox has none, collapsing the fill to 0px
                      // wide (invisible regardless of heightFactor).
                      widthFactor: 1.0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _fillColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Arrow marker — horizontally centered on the bar, sitting at
              // the boundary between the filled and unfilled portions.
              Positioned(
                left: arrowLeft,
                bottom: arrowBottom,
                child: CustomPaint(
                  size: const Size(_arrowWidth, _arrowHeight),
                  painter: _TriangleMarkerPainter(color: _fillColor),
                ),
              ),
              // "Jam / X min" label — vertically centered against the arrow.
              Positioned(
                left: labelLeft,
                bottom: labelBottom,
                child: Container(
                  width: _labelWidth,
                  height: _labelHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Jam',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        '$minutesToClear min',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TriangleMarkerPainter extends CustomPainter {
  const _TriangleMarkerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TriangleMarkerPainter oldDelegate) =>
      oldDelegate.color != color;
}
