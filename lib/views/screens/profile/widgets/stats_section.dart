import 'package:flutter/material.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/views/screens/profile/widgets/profile_card.dart';
import 'package:smart_ar_navigation/views/screens/profile/widgets/profile_section_label.dart';

class StatsSection extends StatelessWidget {
  const StatsSection({
    super.key,
    required this.totalDrives,
    required this.totalDistanceKm,
  });

  final int totalDrives;
  final double totalDistanceKm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileSectionLabel('My Stats'),
        const SizedBox(height: 10),
        ProfileCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.flag_rounded,
                    value: totalDrives.toString(),
                    label: 'Drives',
                  ),
                ),
                const _VerticalDivider(),
                Expanded(
                  child: _StatItem(
                    icon: Icons.route_rounded,
                    value: totalDistanceKm.toStringAsFixed(1),
                    label: 'km driven',
                  ),
                ),
                const _VerticalDivider(),
                const Expanded(
                  child: _StatItem(
                    icon: Icons.star_rounded,
                    value: '–',
                    label: 'Top destination',
                    valueSize: 13,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    this.valueSize = 22,
    this.maxLines = 1,
  });

  final IconData icon;
  final String value;
  final String label;
  final double valueSize;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: primaryColor, size: 18),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.grey.shade800,
            fontSize: valueSize,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 60,
      color: const Color(0xFFE0E0E0),
    );
  }
}
