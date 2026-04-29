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

    final locationGranted = await _handleLocationPermission();
    if (!mounted || !locationGranted) return;

    setState(() => _statusText = 'Ready');
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  // ── Location permission flow ──────────────────────────────────────────────

  Future<bool> _handleLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      return true;
    }

    if (permission == LocationPermission.deniedForever) {
      await _showSettingsDialog();
      return false;
    }

    // permission == denied — show rationale then request
    final proceed = await _showRationaleDialog();
    if (!mounted || !proceed) return false;

    permission = await Geolocator.requestPermission();

    if (!mounted) return false;

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      return true;
    }

    if (permission == LocationPermission.deniedForever) {
      await _showSettingsDialog();
    } else {
      await _showDeniedDialog();
    }
    return false;
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  /// Explains why location is needed — shown before the system prompt.
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
          'Smart AR Navigate needs access to your location to calculate '
          'routes and show real-time navigation directions.\n\n'
          'Your location is only used while the app is open and is '
          'never stored or shared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Deny', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Shown when the user taps Deny on the system prompt (but not permanently).
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
          locationPermissionMessage +
              '\n\nPlease restart the app and allow location access to use '
              'AR navigation.',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Shown when permission is permanently denied — directs user to Settings.
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
          'To use AR navigation, please go to:\n'
          'Settings → Apps → Smart AR Navigate → Permissions → Location',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor,
                foregroundColor: Colors.white),
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
            Image.asset(
              'assets/images/app_logo.png',
              width: 120,
              height: 120,
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
