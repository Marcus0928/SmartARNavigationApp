import 'package:flutter/material.dart';

class AnimatedLogo extends StatelessWidget {
  const AnimatedLogo({
    super.key,
    required this.animation,
    required this.glowRadius,
    required this.opacity,
  });

  final Animation<double> animation;
  final Animation<double> glowRadius;
  final Animation<double> opacity;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F0FF).withValues(alpha: opacity.value * 0.7),
              blurRadius: glowRadius.value,
              spreadRadius: glowRadius.value * 0.2,
            ),
            BoxShadow(
              color: const Color(0xFF0088FF).withValues(alpha: opacity.value * 0.35),
              blurRadius: glowRadius.value * 2.5,
              spreadRadius: glowRadius.value * 0.4,
            ),
          ],
        ),
        child: Opacity(opacity: opacity.value, child: child),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30.8),
        child: Image.asset('assets/icons/logo.png', width: 120, height: 120),
      ),
    );
  }
}
