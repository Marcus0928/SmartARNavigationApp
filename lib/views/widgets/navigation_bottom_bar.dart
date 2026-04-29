import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/core/constants/app_strings.dart';
import 'package:smart_ar_navigation/viewmodels/map_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/navigation_viewmodel.dart';

class NavigationBottomBar extends StatelessWidget {
  const NavigationBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final navVM = context.watch<NavigationViewModel>();
    final route = navVM.currentRoute;

    final etaMinutes =
        route != null ? (route.estimatedDuration / 60).ceil() : 0;
    final distanceText = route != null
        ? '${(route.totalDistance / 1000).toStringAsFixed(1)} km'
        : '--';

    return Container(
      color: overlayBackground,
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 24),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'ETA: $etaMinutes min   $distanceText',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.stop, size: 18),
            label: const Text(stopNavigation),
            onPressed: () {
              context.read<NavigationViewModel>().stopNavigation();
              context.read<MapViewModel>().stopLocationTracking();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
