import 'package:flutter/material.dart';

import 'package:smart_ar_navigation/core/enums/navigation_approach_stage.dart';
import 'package:smart_ar_navigation/core/enums/turn_direction.dart';
import 'package:smart_ar_navigation/views/widgets/dynamic_arrow_widget.dart';

/// Temporary screen — remove after visually verifying all arrow directions.
class ArrowTestScreen extends StatelessWidget {
  const ArrowTestScreen({super.key});

  static const _cases = [
    (TurnDirection.forward,   'forward',    250.0),  // cyan  — > 100m
    (TurnDirection.left,      'left',        75.0),  // amber — 50–100m
    (TurnDirection.right,     'right',       30.0),  // red   — < 50m
    (TurnDirection.uTurn,     'uTurn',      200.0),
    (TurnDirection.keepLeft,  'keepLeft',   200.0),
    (TurnDirection.keepRight, 'keepRight',  200.0),
    (TurnDirection.roundabout,'roundabout', 200.0),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Arrow Direction Test',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 24,
          crossAxisSpacing: 24,
        ),
        itemCount: _cases.length,
        itemBuilder: (context, i) {
          final (direction, label, distance) = _cases[i];
          final stage = distance > 200
              ? NavigationApproachStage.far
              : distance > 50
                  ? NavigationApproachStage.approaching
                  : NavigationApproachStage.imminent;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DynamicArrowWidget(
                direction: direction,
                distance: distance,
                approachStage: stage,
                size: 100,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                '${distance.toInt()} m',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          );
        },
      ),
    );
  }
}
