import 'package:flutter/material.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/models/place_model.dart';
import 'package:smart_ar_navigation/models/route_model.dart';

class RoutePreviewCard extends StatelessWidget {
  const RoutePreviewCard({
    super.key,
    required this.destination,
    required this.routes,
    required this.selectedIndex,
    required this.isFetching,
    required this.onSelectRoute,
    required this.onClear,
    required this.onStart,
    this.activeRouteIndex,
  });

  final PlaceModel destination;
  final List<RouteModel> routes;
  final int selectedIndex;
  final bool isFetching;
  final ValueChanged<int> onSelectRoute;
  final VoidCallback onClear;
  final VoidCallback onStart;
  /// Non-null when the user arrived here from AR navigation.
  /// Identifies which route index is currently being navigated.
  final int? activeRouteIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Destination header ──────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  destination.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Route options or loading ────────────────────────────────
          if (isFetching)
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Finding routes…',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            )
          else if (routes.isEmpty)
            Text(
              'Route unavailable',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: routes.asMap().entries.map((entry) {
                final i = entry.key;
                final r = entry.value;
                final isSelected = i == selectedIndex;
                final isLast = i == routes.length - 1;

                return GestureDetector(
                  onTap: () => onSelectRoute(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor.withValues(alpha: 0.07)
                          : Colors.transparent,
                      border: Border(
                        left: BorderSide(
                          color: isSelected ? primaryColor : Colors.transparent,
                          width: 3,
                        ),
                        bottom: BorderSide(
                          color: isLast
                              ? Colors.transparent
                              : Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        // Label
                        SizedBox(
                          width: 64,
                          child: Text(
                            r.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? primaryColor
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        // Duration
                        Text(
                          '${(r.estimatedDuration / 60).ceil()} min',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? primaryColor
                                : Colors.grey.shade900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Distance
                        Text(
                          _formatDistance(r.totalDistance),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        // Toll badge
                        if (r.hasTolls) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.toll_rounded,
                              size: 12, color: Colors.orange.shade700),
                          const SizedBox(width: 2),
                          Text(
                            'Toll',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 12),

          // ── Action buttons ───────────────────────────────────────────
          Builder(builder: (context) {
            final String label;
            final IconData icon;
            if (activeRouteIndex == null) {
              label = 'Start';
              icon  = Icons.navigation_rounded;
            } else if (selectedIndex == activeRouteIndex) {
              label = 'Resume';
              icon  = Icons.play_arrow_rounded;
            } else {
              label = 'Go';
              icon  = Icons.navigation_rounded;
            }
            return Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onClear,
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(icon, size: 18),
                    label: Text(
                      label,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    onPressed: routes.isEmpty ? null : onStart,
                  ),
                ),
              ],
            );
          }),
        ],
    );
  }

  String _formatDistance(double metres) {
    if (metres >= 1000) return '${(metres / 1000).toStringAsFixed(1)} km';
    return '${metres.toInt()} m';
  }
}

