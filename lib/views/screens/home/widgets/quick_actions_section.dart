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
    // Match the width each button had with Expanded in the original 3-button row:
    // screen minus 32dp container padding minus 2×8dp gaps, divided by 3.
    final buttonWidth =
        (MediaQuery.of(context).size.width - 32 - 16) / 3;

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            QuickPlaceButton(
              icon: Icons.home_outlined,
              label: 'Home',
              place: savedVM.home,
              onTap: onHomeTap,
              onLongPress: onHomeLongPress,
              width: buttonWidth,
            ),
            const SizedBox(width: 8),
            QuickPlaceButton(
              icon: Icons.work_outline,
              label: 'Work',
              place: savedVM.work,
              onTap: onWorkTap,
              onLongPress: onWorkLongPress,
              width: buttonWidth,
            ),
            const SizedBox(width: 8),
            QuickPlaceButton(
              icon: Icons.star_border_rounded,
              label: 'Favourite',
              place: savedVM.favourite,
              onTap: onFavouriteTap,
              onLongPress: onFavouriteLongPress,
              width: buttonWidth,
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onSavedPlacesTap,
              child: Container(
                width: buttonWidth,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Saved',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            count > 0
                                ? '$count place${count == 1 ? '' : 's'}'
                                : 'None',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
