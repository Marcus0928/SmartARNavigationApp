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
    final mapVM = context.watch<MapViewModel>();

    final route = navVM.currentRoute;
    final etaMinutes = route != null ? (route.estimatedDuration / 60).ceil() : 0;
    final distanceKm = route != null
        ? (route.totalDistance / 1000).toStringAsFixed(1)
        : '--';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        boxShadow: [BoxShadow(color: Color(0x44000000), blurRadius: 12, offset: Offset(0, -3))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
          child: Row(
            children: [
              // ETA pill
              _InfoPill(
                icon: Icons.access_time_rounded,
                value: '$etaMinutes min',
              ),
              const SizedBox(width: 12),
              // Distance pill
              _InfoPill(
                icon: Icons.straighten_rounded,
                value: '$distanceKm km',
              ),
              const Spacer(),
              // Speed badge
              if (mapVM.currentSpeed != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _SpeedBadge(speedMs: mapVM.currentSpeed!),
                ),
              // Stop button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.stop_rounded, size: 18),
                label: const Text(
                  stopNavigation,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  context.read<NavigationViewModel>().stopNavigation();
                  context.read<MapViewModel>().stopLocationTracking();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 15),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SpeedBadge extends StatelessWidget {
  const _SpeedBadge({required this.speedMs});

  final double speedMs;

  @override
  Widget build(BuildContext context) {
    final kmh = (speedMs * 3.6).round();
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$kmh',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              height: 1.0,
            ),
          ),
          Text(
            'km/h',
            style: TextStyle(
              fontSize: 8,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
