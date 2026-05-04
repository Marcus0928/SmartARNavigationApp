import 'package:flutter/material.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/core/constants/app_strings.dart';
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
  });

  final PlaceModel destination;
  final List<RouteModel> routes;
  final int selectedIndex;
  final bool isFetching;
  final ValueChanged<int> onSelectRoute;
  final VoidCallback onClear;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
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
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
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
          else ...[
            // Route selector tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: routes.asMap().entries.map((entry) {
                  final i = entry.key;
                  final r = entry.value;
                  final isSelected = i == selectedIndex;
                  return Padding(
                    padding: EdgeInsets.only(right: i < routes.length - 1 ? 8 : 0),
                    child: GestureDetector(
                      onTap: () => onSelectRoute(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? primaryColor
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              r.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${(r.estimatedDuration / 60).ceil()} min',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade800,
                              ),
                            ),
                            Text(
                              _formatDistance(r.totalDistance),
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected
                                    ? Colors.white70
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          ],

          const SizedBox(height: 12),

          // ── Start button ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.navigation_rounded, size: 20),
              label: const Text(
                startNavigation,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              onPressed: routes.isEmpty ? null : onStart,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDistance(double metres) {
    if (metres >= 1000) return '${(metres / 1000).toStringAsFixed(1)} km';
    return '${metres.toInt()} m';
  }
}
