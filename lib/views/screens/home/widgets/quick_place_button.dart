import 'package:flutter/material.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/models/place_model.dart';

class QuickPlaceButton extends StatelessWidget {
  const QuickPlaceButton({
    super.key,
    required this.icon,
    required this.label,
    required this.place,
    required this.onTap,
    required this.onLongPress,
    required this.width,
  });

  final IconData icon;
  final String label;
  final PlaceModel? place;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final double width;

  @override
  Widget build(BuildContext context) {
    final isSet = place != null;

    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: isSet ? onLongPress : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSet ? primaryColor : Colors.grey.shade500,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isSet ? place!.name : 'Add',
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
    );
  }
}
