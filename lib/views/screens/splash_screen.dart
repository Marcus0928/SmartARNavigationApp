import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/core/constants/app_strings.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _statusText = 'Initializing...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  // ── Main init flow ────────────────────────────────────────────────────────

  Future<void> _initialize() async {
    setState(() => _statusText = 'Checking permissions...');

    // Handle permission dialogs — always proceed to home regardless of outcome.
    try {
      await _handleLocationPermission();
    } catch (_) {
      // Permission check failed (e.g. location services off) — proceed anyway.
    }

    if (!mounted) return;

    setState(() => _statusText = 'Ready');
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  // ── Location permission flow ──────────────────────────────────────────────

  Future<void> _handleLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      return; // Already granted — nothing to do.
    }

    if (permission == LocationPermission.deniedForever) {
      await _showSettingsDialog();
      return;
    }

    // Denied but requestable — show rationale then trigger system prompt.
    final proceed = await _showRationaleDialog();
    if (!mounted || !proceed) return;

    permission = await Geolocator.requestPermission();
    if (!mounted) return;

    if (permission == LocationPermission.deniedForever) {
      await _showSettingsDialog();
    } else if (permission == LocationPermission.denied) {
      await _showDeniedDialog();
    }
    // whileInUse / always → granted, nothing more to show.
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  Future<bool> _showRationaleDialog() async {
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

  Future<void> _showDeniedDialog() async {
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

  Future<void> _showSettingsDialog() async {
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

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.navigation,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              appName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              _statusText,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
