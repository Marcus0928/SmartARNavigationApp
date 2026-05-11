import 'package:flutter/material.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/viewmodels/saved_locations_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/saved_places_viewmodel.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/quick_place_button.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({
    super.key,
    required this.savedVM,
    required this.savedLocationsVM,
    required this.onHomeTap,
    required this.onHomeLongPress,
    required this.onWorkTap,
    required this.onWorkLongPress,
    required this.onFavouriteTap,
    required this.onFavouriteLongPress,
    required this.onSavedPlacesTap,
  });

  final SavedPlacesViewModel savedVM;
  final SavedLocationsViewModel savedLocationsVM;
  final VoidCallback onHomeTap;
  final VoidCallback onHomeLongPress;
  final VoidCallback onWorkTap;
  final VoidCallback onWorkLongPress;
  final VoidCallback onFavouriteTap;
  final VoidCallback onFavouriteLongPress;
  final VoidCallback onSavedPlacesTap;

  @override
  Widget build(BuildContext context) {
    final count = savedLocationsVM.count;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            QuickPlaceButton(
              icon: Icons.home_outlined,
              label: 'Home',
              place: savedVM.home,
              onTap: onHomeTap,
              onLongPress: onHomeLongPress,
            ),
            const SizedBox(width: 8),
            QuickPlaceButton(
              icon: Icons.work_outline,
              label: 'Work',
              place: savedVM.work,
              onTap: onWorkTap,
              onLongPress: onWorkLongPress,
            ),
            const SizedBox(width: 8),
            QuickPlaceButton(
              icon: Icons.star_border_rounded,
              label: 'Favourite',
              place: savedVM.favourite,
              onTap: onFavouriteTap,
              onLongPress: onFavouriteLongPress,
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onSavedPlacesTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  count > 0
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  size: 20,
                  color: count > 0 ? primaryColor : Colors.grey.shade500,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Saved Places',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  count > 0
                      ? '$count place${count == 1 ? '' : 's'}'
                      : 'None saved',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
