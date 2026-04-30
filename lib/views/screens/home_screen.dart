import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/core/constants/app_strings.dart';
import 'package:smart_ar_navigation/models/place_model.dart';
import 'package:smart_ar_navigation/models/route_model.dart';
import 'package:smart_ar_navigation/viewmodels/map_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/navigation_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/saved_places_viewmodel.dart';
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
  final _sheetController = DraggableScrollableController();
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

  void _onQuickTap(
    SavedPlaceType type,
    String label,
    SavedPlacesViewModel savedVM,
    MapViewModel mapVM,
  ) {
    final place = savedVM.getPlace(type);
    if (place == null) {
      _showPlaceSearchSheet(type, label, savedVM);
    } else {
      mapVM.setSelectedDestination(place);
    }
  }

  void _onQuickLongPress(
    SavedPlaceType type,
    String label,
    SavedPlacesViewModel savedVM,
    MapViewModel mapVM,
  ) {
    final place = savedVM.getPlace(type);
    if (place == null) return;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PlaceOptionsSheet(
        label: label,
        place: place,
        onNavigate: () {
          Navigator.pop(context);
          mapVM.setSelectedDestination(place);
        },
        onEdit: () {
          Navigator.pop(context);
          _showPlaceSearchSheet(type, label, savedVM);
        },
        onRemove: () {
          Navigator.pop(context);
          savedVM.clearPlace(type);
        },
      ),
    );
  }

  void _showPlaceSearchSheet(
    SavedPlaceType type,
    String label,
    SavedPlacesViewModel savedVM,
  ) {
    savedVM.clearSearch();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PlaceSearchSheet(type: type, label: label, vm: savedVM),
    ).whenComplete(savedVM.clearSearch);
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
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapVM = context.watch<MapViewModel>();
    final navVM = context.watch<NavigationViewModel>();
    final savedVM = context.watch<SavedPlacesViewModel>();

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

                // Route preview polyline
                if (mapVM.previewRoute != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: mapVM.previewRoute!.polylinePoints
                            .map((p) => LatLng(p.latitude, p.longitude))
                            .toList(),
                        color: primaryColor,
                        strokeWidth: 5.0,
                        borderColor: Colors.white,
                        borderStrokeWidth: 1.5,
                      ),
                    ],
                  ),

                // Destination pin
                if (mapVM.selectedDestination != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          mapVM.selectedDestination!.coordinates.latitude,
                          mapVM.selectedDestination!.coordinates.longitude,
                        ),
                        width: 40,
                        height: 48,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
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

          // ── Bottom: draggable panel with search bar ─────────────
          Positioned.fill(
            child: DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.22,
              minChildSize: 0.12,
              maxChildSize: 0.95,
              snap: true,
              snapSizes: const [0.22, 0.5, 0.95],
              builder: (sheetContext, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 12,
                        offset: Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Drag handle
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
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SearchBarWidget(),
                                const SizedBox(height: 12),
                                // Quick-access: Home / Work / Favourite
                                Row(
                                  children: [
                                    _QuickPlaceButton(
                                      icon: Icons.home_outlined,
                                      label: 'Home',
                                      place: savedVM.home,
                                      onTap: () => _onQuickTap(SavedPlaceType.home, 'Home', savedVM, mapVM),
                                      onLongPress: () => _onQuickLongPress(SavedPlaceType.home, 'Home', savedVM, mapVM),
                                    ),
                                    const SizedBox(width: 8),
                                    _QuickPlaceButton(
                                      icon: Icons.work_outline,
                                      label: 'Work',
                                      place: savedVM.work,
                                      onTap: () => _onQuickTap(SavedPlaceType.work, 'Work', savedVM, mapVM),
                                      onLongPress: () => _onQuickLongPress(SavedPlaceType.work, 'Work', savedVM, mapVM),
                                    ),
                                    const SizedBox(width: 8),
                                    _QuickPlaceButton(
                                      icon: Icons.star_border_rounded,
                                      label: 'Favourite',
                                      place: savedVM.favourite,
                                      onTap: () => _onQuickTap(SavedPlaceType.favourite, 'Favourite', savedVM, mapVM),
                                      onLongPress: () => _onQuickLongPress(SavedPlaceType.favourite, 'Favourite', savedVM, mapVM),
                                    ),
                                  ],
                                ),
                                if (mapVM.selectedDestination != null) ...[
                                  const SizedBox(height: 12),
                                  _RoutePreviewCard(
                                    destination: mapVM.selectedDestination!,
                                    route: mapVM.previewRoute,
                                    isFetching: mapVM.isFetchingRoute,
                                    onClear: mapVM.clearDestination,
                                    onStart: () async {
                                      await navVM.startNavigation(
                                          mapVM.selectedDestination!);
                                      if (!context.mounted) return;
                                      if (navVM.errorMessage != null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    navVM.errorMessage!)));
                                      } else {
                                        Navigator.of(context)
                                            .pushNamed('/ar-navigation');
                                      }
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Speed indicator — floats above the draggable panel ───
          AnimatedBuilder(
            animation: _sheetController,
            builder: (_, __) {
              final screenH = MediaQuery.of(context).size.height;
              final extent = _sheetController.isAttached
                  ? _sheetController.size
                  : 0.22;
              return Positioned(
                right: 16,
                bottom: screenH * extent + 8,
                child: _SpeedIndicator(speedMs: mapVM.currentSpeed),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Location indicator ──────────────────────────────────────────
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

// ── Side drawer ─────────────────────────────────────────────────
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

// ── Route preview card ─────────────────────────────────────────────────────
class _RoutePreviewCard extends StatelessWidget {
  const _RoutePreviewCard({
    required this.destination,
    required this.route,
    required this.isFetching,
    required this.onClear,
    required this.onStart,
  });

  final PlaceModel destination;
  final RouteModel? route;
  final bool isFetching;
  final VoidCallback onClear;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final distanceText = route != null
        ? _formatDistance(route!.totalDistance)
        : null;
    final etaText = route != null
        ? '${(route!.estimatedDuration / 60).ceil()} min'
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Destination row
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  destination.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
              ),
            ],
          ),

          // Route info row
          const SizedBox(height: 8),
          if (isFetching)
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Finding best route…',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            )
          else if (distanceText != null) ...[
            Row(
              children: [
                _Chip(
                  icon: Icons.access_time_rounded,
                  label: etaText!,
                  color: primaryColor,
                ),
                const SizedBox(width: 8),
                _Chip(
                  icon: Icons.straighten_rounded,
                  label: distanceText,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ] else
            Text(
              'Route unavailable',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.navigation_rounded, size: 20),
              label: const Text(
                startNavigation,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              onPressed: onStart,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDistance(double metres) {
    if (metres >= 1000) return '${(metres / 1000).toStringAsFixed(1)} km';
    return '${metres.toInt()} m';
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── Quick-place button (Home / Work / Favourite) ───────────────────────────
class _QuickPlaceButton extends StatelessWidget {
  const _QuickPlaceButton({
    required this.icon,
    required this.label,
    required this.place,
    required this.onTap,
    required this.onLongPress,
  });

  final IconData icon;
  final String label;
  final PlaceModel? place;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final isSet = place != null;
    return Expanded(
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

// ── Place search sheet (set / edit a saved location) ──────────────────────
class _PlaceSearchSheet extends StatefulWidget {
  const _PlaceSearchSheet({
    required this.type,
    required this.label,
    required this.vm,
  });

  final SavedPlaceType type;
  final String label;
  final SavedPlacesViewModel vm;

  @override
  State<_PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends State<_PlaceSearchSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  'Set ${widget.label} location',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search for a place...',
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onChanged: widget.vm.searchPlace,
                ),
              ),
              const SizedBox(height: 4),
              ...widget.vm.searchResults.map(
                (place) => ListTile(
                  leading: const Icon(Icons.location_on_outlined,
                      color: Colors.grey),
                  title: Text(
                    place.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    place.address,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    widget.vm.selectAndSavePlace(widget.type, place);
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

// ── Place options sheet (navigate / edit / remove) ─────────────────────────
class _PlaceOptionsSheet extends StatelessWidget {
  const _PlaceOptionsSheet({
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
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  place.address,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade600),
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
            leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
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

// ── Speed indicator ────────────────────────────────────────────────────────
class _SpeedIndicator extends StatelessWidget {
  const _SpeedIndicator({this.speedMs});

  final double? speedMs;

  @override
  Widget build(BuildContext context) {
    final kmh = speedMs != null ? (speedMs! * 3.6).round() : 0;

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(10),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$kmh',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.0,
                color: Color(0xFF212121),
              ),
            ),
            const Text(
              'km/h',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
