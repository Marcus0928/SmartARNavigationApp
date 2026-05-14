import 'package:flutter/material.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/core/constants/app_strings.dart';
import 'package:smart_ar_navigation/viewmodels/plan_drive_viewmodel.dart';
import 'package:smart_ar_navigation/views/screens/plan_drive/widgets/fetching_indicator.dart';
import 'package:smart_ar_navigation/views/screens/plan_drive/widgets/stat_chip.dart';

class RouteSummaryCard extends StatelessWidget {
  const RouteSummaryCard({
    super.key,
    required this.vm,
    required this.onStart,
  });

  final PlanDriveViewModel vm;
  final VoidCallback onStart;

  String _formatDistance(double metres) {
    if (metres >= 1000) return '${(metres / 1000).toStringAsFixed(1)} km';
    return '${metres.toInt()} m';
  }

  String _formatETA(int seconds) {
    final eta = DateTime.now().add(Duration(seconds: seconds));
    final h = eta.hour;
    final m = eta.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: vm.isFetching
          ? const FetchingIndicator()
          : vm.error != null
              ? _buildError(vm.error!)
              : _buildRouteDetails(),
    );
  }

  Widget _buildError(String message) {
    return Row(
      children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
        const SizedBox(width: 8),
        Text(
          message,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildRouteDetails() {
    final route = vm.selectedRoute!;
    final durationMin = (route.estimatedDuration / 60).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          route.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            StatChip(
              icon: Icons.route_rounded,
              label: _formatDistance(route.totalDistance),
            ),
            const SizedBox(width: 4),
            _Dot(),
            const SizedBox(width: 4),
            StatChip(
              icon: Icons.access_time_rounded,
              label: '$durationMin min',
            ),
            const SizedBox(width: 4),
            _Dot(),
            const SizedBox(width: 4),
            StatChip(
              icon: Icons.flag_rounded,
              label: 'Arrive ${_formatETA(route.estimatedDuration)}',
            ),
            if (route.hasTolls) ...[
              const SizedBox(width: 4),
              _Dot(),
              const SizedBox(width: 4),
              StatChip(
                icon: Icons.toll_rounded,
                label: 'Tolls',
                color: Colors.orange.shade700,
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
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
            onPressed: onStart,
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        shape: BoxShape.circle,
      ),
    );
  }
}
