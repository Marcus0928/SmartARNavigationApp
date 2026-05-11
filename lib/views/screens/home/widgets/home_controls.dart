import 'package:flutter/material.dart';

import 'package:smart_ar_navigation/views/screens/home/widgets/compass_button.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/floating_icon_button.dart';

class HomeControls extends StatelessWidget {
  const HomeControls({
    super.key,
    required this.onMenuTap,
    required this.onMyLocationTap,
    required this.onCompassTap,
    required this.mapRotation,
  });

  final VoidCallback onMenuTap;
  final VoidCallback onMyLocationTap;
  final VoidCallback onCompassTap;
  final double mapRotation;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FloatingIconButton(
              icon: Icons.menu,
              tooltip: 'Menu',
              onPressed: onMenuTap,
            ),
            const Spacer(),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingIconButton(
                  icon: Icons.my_location,
                  tooltip: 'My Location',
                  onPressed: onMyLocationTap,
                ),
                const SizedBox(height: 8),
                CompassButton(
                  rotation: mapRotation,
                  onPressed: onCompassTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
