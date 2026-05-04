import 'package:flutter/material.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/models/place_model.dart';

class PlaceOptionsSheet extends StatelessWidget {
  const PlaceOptionsSheet({
    super.key,
    required this.label,
    required this.place,
    required this.onNavigate,
    required this.onEdit,
    required this.onRemove,
  });

  final String label;
  final PlaceModel place;
  final VoidCallback onNavigate;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  place.address,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.navigation_outlined, color: primaryColor),
            title: const Text('Navigate'),
            onTap: onNavigate,
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit location'),
            onTap: onEdit,
          ),
          ListTile(
            leading:
                Icon(Icons.delete_outline, color: Colors.red.shade400),
            title: Text(
              'Remove $label',
              style: TextStyle(color: Colors.red.shade400),
            ),
            onTap: onRemove,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
