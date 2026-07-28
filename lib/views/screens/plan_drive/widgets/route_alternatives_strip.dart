import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/core/utils/distance_formatter.dart';
import 'package:smart_ar_navigation/viewmodels/plan_drive_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/settings_viewmodel.dart';

class RouteAlternativesStrip extends StatelessWidget {
  const RouteAlternativesStrip({
    super.key,
    required this.vm,
    required this.onSelectRoute,
  });

  final PlanDriveViewModel vm;
  final ValueChanged<int> onSelectRoute;

  @override
  Widget build(BuildContext context) {
    final distanceUnit = context.watch<SettingsViewModel>().distanceUnit;
    final fastestIndex = vm.routes
        .asMap()
        .entries
        .reduce(
          (a, b) => a.value.estimatedDuration <= b.value.estimatedDuration
              ? a
              : b,
        )
        .key;

    return Container(
      height: 110,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        itemCount: vm.routes.length,
        itemBuilder: (_, i) {
          final route = vm.routes[i];
          final selected = i == vm.selectedRouteIndex;
          final fastest = i == fastestIndex && vm.routes.length > 1;
          final durationMin = (route.estimatedDuration / 60).ceil();

          return GestureDetector(
            onTap: () => onSelectRoute(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 200,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: selected ? primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? primaryColor : Colors.grey.shade200,
                ),
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0x351A73E8),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Row 1: label + Fastest badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          route.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white70
                                : Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (fastest)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white.withValues(alpha: 0.25)
                                : const Color(0xFFE8F0FE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Fastest',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Row 2: duration
                  Text(
                    '$durationMin min',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : textPrimary,
                    ),
                  ),
                  // Row 3: distance + toll indicator
                  Row(
                    children: [
                      Text(
                        formatDistance(route.totalDistance, distanceUnit),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: selected
                              ? Colors.white70
                              : Colors.grey.shade500,
                        ),
                      ),
                      if (route.hasTolls) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.toll_rounded,
                                size: 10,
                                color: selected
                                    ? Colors.white
                                    : Colors.orange.shade700,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Toll',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? Colors.white
                                      : Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
