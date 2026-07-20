import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_ar_navigation/viewmodels/map_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/navigation_viewmodel.dart';
import 'package:smart_ar_navigation/views/screens/ar_navigation_screen.dart';

class NavigationBottomBar extends StatefulWidget {
  const NavigationBottomBar({super.key});

  @override
  State<NavigationBottomBar> createState() => _NavigationBottomBarState();
}

class _NavigationBottomBarState extends State<NavigationBottomBar> {
  bool _isNavigatingToRoutes = false;

  @override
  Widget build(BuildContext context) {
    final navVM = context.watch<NavigationViewModel>();

    final route = navVM.currentRoute;
    final etaMinutes =
        route != null ? (route.estimatedDuration / 60).ceil() : 0;
    final distanceKm = route != null
        ? (route.totalDistance / 1000).toStringAsFixed(1)
        : '--';

    final arrival = DateTime.now().add(Duration(minutes: etaMinutes));
    final arrivalStr =
        '${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        boxShadow: [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              // ── Left: Stop button (✕, no text) ───────────────────
              GestureDetector(
                onTap: () async {
                  final navVM = context.read<NavigationViewModel>();
                  final mapVM = context.read<MapViewModel>();
                  final navigator = Navigator.of(context);

                  context
                      .findAncestorStateOfType<ARNavigationScreenState>()
                      ?.isExiting = true;

                  mapVM.stopLocationTracking();
                  await navVM.stopNavigation();
                  mapVM.clearDestination();
                  mapVM.requestRecenter();

                  navigator.pop();
                },
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.black87,
                    size: 28,
                  ),
                ),
              ),

              // ── Centre: ETA info ──────────────────────────────────
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$etaMinutes min',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$arrivalStr  ·  $distanceKm km',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Right: Routes button ──────────────────────────────
              _IconLabelButton(
                icon: Icons.alt_route_rounded,
                label: 'Routes',
                isLoading: _isNavigatingToRoutes,
                onTap: () async {
                  if (_isNavigatingToRoutes) return;
                  setState(() => _isNavigatingToRoutes = true);

                  try {
                    final mapVM = context.read<MapViewModel>();
                    context
                        .findAncestorStateOfType<ARNavigationScreenState>()
                        ?.isExiting = true;
                    mapVM.setSelectingRouteFromNav(true);
                    await mapVM.refreshPreviewRoute();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/home',
                        (route) => route.isFirst,
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isNavigatingToRoutes = false);
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconLabelButton extends StatelessWidget {
  const _IconLabelButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
