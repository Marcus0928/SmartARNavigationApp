import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/core/constants/app_strings.dart';
import 'package:smart_ar_navigation/viewmodels/map_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/navigation_viewmodel.dart';
import 'package:smart_ar_navigation/views/widgets/search_bar_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  static const _defaultCenter = LatLng(3.0738, 101.5077);

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _mapController = MapController();
  bool _trackingStarted = false;
  bool _centeredOnUser = false;
  double _mapRotation = 0.0;

  void _animatedMove(LatLng dest, double zoom) {
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: dest.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: dest.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: zoom,
    );
    final rotationTween = Tween<double>(
      begin: _mapController.camera.rotation,
      end: 0.0,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );
    final animation =
        CurvedAnimation(parent: controller, curve: Curves.easeInOut);

    controller.addListener(() {
      _mapController.moveAndRotate(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
        rotationTween.evaluate(animation),
      );
    });
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });
    controller.forward();
  }

  void _animateRotation(double targetRotation) {
    final rotationTween = Tween<double>(
      begin: _mapController.camera.rotation,
      end: targetRotation,
    );
    final controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    final animation =
        CurvedAnimation(parent: controller, curve: Curves.easeInOut);

    controller.addListener(() {
      _mapController.rotate(rotationTween.evaluate(animation));
    });
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });
    controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_trackingStarted) {
      _trackingStarted = true;
      context.read<MapViewModel>().startLocationTracking();
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapVM = context.watch<MapViewModel>();
    final navVM = context.watch<NavigationViewModel>();

    final loc = mapVM.currentLocation;
    final userLatLng =
        loc != null ? LatLng(loc.latitude, loc.longitude) : null;

    // Animate to user location the first time a GPS fix arrives
    if (userLatLng != null && !_centeredOnUser) {
      _centeredOnUser = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animatedMove(userLatLng, 16);
      });
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: const _WazeDrawer(),
      body: Stack(
        children: [
          // ── Full-screen tile map (CartoDB Voyager — Waze-style colours) ─
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _defaultCenter,
                initialZoom: 16,
                onMapEvent: (event) {
                  final r = _mapController.camera.rotation;
                  if (r != _mapRotation) setState(() => _mapRotation = r);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.sunway.smart_ar_navigation',
                ),

                // Accuracy ring
                if (userLatLng != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: userLatLng,
                        radius: (mapVM.currentAccuracy ?? 30)
                            .clamp(10, 300)
                            .toDouble(),
                        useRadiusInMeter: true,
                        color: const Color(0x201A73E8),
                        borderColor: const Color(0x601A73E8),
                        borderStrokeWidth: 1.5,
                      ),
                    ],
                  ),

                // Waze-style location indicator
                if (userLatLng != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: userLatLng,
                        width: 44,
                        height: 44,
                        child: _LocationIndicator(
                            heading: mapVM.currentHeading),
                      ),
                    ],
                  ),

                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                    TextSourceAttribution('CARTO'),
                  ],
                ),
              ],
            ),
          ),

          // ── Top-left: hamburger menu ────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _FloatingIconButton(
                icon: Icons.menu,
                tooltip: 'Menu',
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            ),
          ),

          // ── Top-right: location + compass ──────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _FloatingIconButton(
                      icon: Icons.my_location,
                      tooltip: 'My Location',
                      onPressed: () {
                        if (userLatLng != null) {
                          _animatedMove(userLatLng, 16);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    _CompassButton(
                      rotation: _mapRotation,
                      onPressed: () => _animateRotation(0),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom: search bar + start navigation button ────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SearchBarWidget(),
                    if (mapVM.selectedDestination != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.navigation),
                          label: const Text(
                            startNavigation,
                            style: TextStyle(fontSize: 16),
                          ),
                          onPressed: () async {
                            await navVM.startNavigation(
                                mapVM.selectedDestination!);
                            if (!context.mounted) return;
                            if (navVM.errorMessage != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(navVM.errorMessage!)),
                              );
                            } else {
                              Navigator.of(context)
                                  .pushNamed('/ar-navigation');
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Waze-style location indicator ──────────────────────────────────────────
class _LocationIndicator extends StatelessWidget {
  const _LocationIndicator({this.heading});
  final double? heading;

  static const _blue = Color(0xFF1A73E8);

  @override
  Widget build(BuildContext context) {
    // heading: 0° = North, increases clockwise (same as Transform.rotate radians)
    final angle = (heading != null && heading! >= 0)
        ? heading! * math.pi / 180.0
        : 0.0;

    return Transform.rotate(
      angle: angle,
      child: const Stack(
        alignment: Alignment.center,
        children: [
          // White "border" layer
          Icon(Icons.navigation_rounded, color: Colors.white, size: 42),
          // Blue fill layer
          Icon(Icons.navigation_rounded, color: _blue, size: 32),
        ],
      ),
    );
  }
}

// ── Waze-style side drawer ─────────────────────────────────────────────────
class _WazeDrawer extends StatelessWidget {
  const _WazeDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Profile section ──────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: primaryColor,
                    child: const Text(
                      'M',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Marcus',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Smart AR Navigator',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // ── Menu items ───────────────────────────────────────────
          _DrawerMenuItem(
            icon: Icons.directions_outlined,
            label: 'Plan a drive',
            onTap: () => Navigator.of(context).pop(),
          ),
          _DrawerMenuItem(
            icon: Icons.inbox_outlined,
            label: 'Inbox',
            onTap: () => Navigator.of(context).pop(),
          ),
          _DrawerMenuItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/settings');
            },
          ),
          _DrawerMenuItem(
            icon: Icons.help_outline,
            label: 'Help & Feedback',
            onTap: () => Navigator.of(context).pop(),
          ),

          const Spacer(),
          const Divider(height: 1, thickness: 1),

          // ── Shutdown ─────────────────────────────────────────────
          _DrawerMenuItem(
            icon: Icons.power_settings_new,
            label: 'Shut Down',
            iconColor: Colors.red.shade400,
            labelColor: Colors.red.shade400,
            onTap: () {
              Navigator.of(context).pop();
              showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Shut Down'),
                  content: const Text('Are you sure you want to exit the app?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => SystemNavigator.pop(),
                      child: Text(
                        'Exit',
                        style: TextStyle(color: Colors.red.shade400),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.grey.shade700, size: 22),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          color: labelColor ?? Colors.grey.shade800,
          fontWeight: FontWeight.w500,
        ),
      ),
      horizontalTitleGap: 4,
      onTap: onTap,
    );
  }
}

// ── Compass button ─────────────────────────────────────────────────────────
class _CompassButton extends StatelessWidget {
  const _CompassButton({required this.rotation, required this.onPressed});

  final double rotation;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Reset North',
      child: Material(
        elevation: 4,
        shape: const CircleBorder(),
        color: Colors.white,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Transform.rotate(
              angle: -rotation * math.pi / 180.0,
              child: CustomPaint(painter: _CompassPainter()),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.28;

    // North needle — red
    canvas.drawPath(
      ui.Path()
        ..moveTo(cx, cy - r)
        ..lineTo(cx - r * 0.38, cy)
        ..lineTo(cx + r * 0.38, cy)
        ..close(),
      Paint()..color = const Color(0xFFE53935),
    );

    // South needle — grey
    canvas.drawPath(
      ui.Path()
        ..moveTo(cx, cy + r)
        ..lineTo(cx - r * 0.38, cy)
        ..lineTo(cx + r * 0.38, cy)
        ..close(),
      Paint()..color = const Color(0xFFBDBDBD),
    );

    // Centre dot
    canvas.drawCircle(
        Offset(cx, cy), r * 0.18, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_CompassPainter old) => false;
}

// ── Shared floating circular icon button ───────────────────────────────────
class _FloatingIconButton extends StatelessWidget {
  const _FloatingIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shape: const CircleBorder(),
      color: Colors.white,
      child: IconButton(
        icon: Icon(icon, color: Colors.grey.shade700),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
