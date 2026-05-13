import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/core/constants/app_strings.dart';

Future<bool> showRationaleDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.location_on, color: primaryColor),
          SizedBox(width: 8),
          Text('Location Access'),
        ],
      ),
      content: const Text(
        'Smart AR Navigate needs your location to calculate routes and '
        'show real-time AR navigation directions.\n\n'
        'Your location is only used while the app is open and is never '
        'stored or shared.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Deny', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Allow'),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<void> showDeniedDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: warningColor),
          SizedBox(width: 8),
          Text('Permission Denied'),
        ],
      ),
      content: const Text(
        '$locationPermissionMessage\n\n'
        'Navigation features will be limited. You can grant access later '
        'from Settings → Apps → Smart AR Navigate → Permissions.',
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Continue Anyway'),
        ),
      ],
    ),
  );
}

Future<void> showSettingsDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.settings, color: primaryColor),
          SizedBox(width: 8),
          Text('Enable in Settings'),
        ],
      ),
      content: const Text(
        'Location permission has been permanently denied.\n\n'
        'To enable AR navigation, go to:\n'
        'Settings → Apps → Smart AR Navigate → Permissions → Location',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Later', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            Navigator.of(ctx).pop();
            await Geolocator.openAppSettings();
          },
          child: const Text('Open Settings'),
        ),
      ],
    ),
  );
}
