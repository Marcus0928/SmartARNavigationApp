import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/core/constants/app_strings.dart';
import 'package:smart_ar_navigation/viewmodels/map_viewmodel.dart';
import 'package:smart_ar_navigation/views/screens/splash/widgets/animated_logo.dart';
import 'package:smart_ar_navigation/views/screens/splash/widgets/permission_dialogs.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  String _statusText = 'Initializing...';
  late final AnimationController _glowController;
  late final Animation<double> _glowRadius;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    final curve = CurvedAnimation(parent: _glowController, curve: Curves.easeInOut);
    _glowRadius = Tween<double>(begin: 6.0, end: 28.0).animate(curve);
    _opacity    = Tween<double>(begin: 0.6, end: 1.0).animate(curve);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() => _statusText = 'Checking permissions...');
    try {
      await _handleLocationPermission();
    } catch (_) {}
    if (!mounted) return;

    // Await the first location fix (last-known cache, < 100 ms) so that
    // HomeScreen's initialCenter is already set when the map first builds.
    // The idempotency guard in MapViewModel makes the HomeScreen call a no-op.
    await context.read<MapViewModel>().startLocationTracking();

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  Future<void> _handleLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (!mounted) return;

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      await showSettingsDialog(context);
      return;
    }

    final proceed = await showRationaleDialog(context);
    if (!mounted || !proceed) return;

    permission = await Geolocator.requestPermission();
    if (!mounted) return;

    if (permission == LocationPermission.deniedForever) {
      await showSettingsDialog(context);
    } else if (permission == LocationPermission.denied) {
      await showDeniedDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedLogo(
              animation: _glowController,
              glowRadius: _glowRadius,
              opacity: _opacity,
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
            const SizedBox(height: 40),
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
