import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:smart_ar_navigation/core/enums/navigation_approach_stage.dart';
import 'package:smart_ar_navigation/models/route_model.dart';
import 'package:smart_ar_navigation/core/enums/navigation_status.dart';
import 'package:smart_ar_navigation/core/enums/turn_direction.dart';
import 'package:smart_ar_navigation/viewmodels/ar_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/map_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/navigation_viewmodel.dart';
import 'package:smart_ar_navigation/views/widgets/dynamic_arrow_widget.dart';
import 'package:smart_ar_navigation/views/widgets/navigation_bottom_bar.dart';

class ARNavigationScreen extends StatefulWidget {
  const ARNavigationScreen({super.key});

  @override
  State<ARNavigationScreen> createState() => ARNavigationScreenState();
}

class ARNavigationScreenState extends State<ARNavigationScreen>
    with WidgetsBindingObserver {
  bool _arrivalHandled = false;
  bool _showAR = true;
  bool isExiting = false;

  TurnDirection? _debugDirection;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (isExiting) return;
    if (state == AppLifecycleState.paused) {
      setState(() => _showAR = false);
    } else if (state == AppLifecycleState.resumed) {
      setState(() => _showAR = false);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !isExiting) setState(() => _showAR = true);
      });
    }
  }

  void _onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    context.read<ARViewModel>().initializeAR(sessionManager, objectManager);
  }

  void _handleArrival(BuildContext context) {
    if (_arrivalHandled) return;
    _arrivalHandled = true;

    isExiting = true;

    final navVM = context.read<NavigationViewModel>();
    final mapVM = context.read<MapViewModel>();
    final navigator = Navigator.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have arrived!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      mapVM.stopLocationTracking();
      await navVM.stopNavigation();
      mapVM.clearDestination();
      mapVM.requestRecenter();

      navigator.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final navVM = context.watch<NavigationViewModel>();

    if (navVM.navigationStatus == NavigationStatus.arrived) {
      _handleArrival(context);
    }

    final arVM = context.watch<ARViewModel>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
      body: Stack(
        children: [
          // ── Layer 1: Full-screen AR camera feed ───────────────────
          if (_showAR)
            ARView(onARViewCreated: _onARViewCreated)
          else
            Container(color: Colors.black),

          // ── Layer 2: Chevron arrow ────────────────────────────────
          if (_debugDirection != null || arVM.nextTurnDirection != null)
            Positioned.fill(
              child: Center(
                child: DynamicArrowWidget(
                  direction:     _debugDirection ?? arVM.nextTurnDirection!,
                  distance:      arVM.distanceToNextTurn ?? double.infinity,
                  approachStage: _debugDirection != null
                      ? NavigationApproachStage.far
                      : arVM.approachStage,
                  exitNumber: _debugDirection == TurnDirection.roundabout
                      ? 2
                      : arVM.roundaboutExit,
                ),
              ),
            ),

          // ── Layer 3: Floating info card + status banners ──────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NavInfoCard(
                  directionOverride: _debugDirection,
                  approachStageOverride: _debugDirection != null
                      ? NavigationApproachStage.far
                      : null,
                ),
                if (navVM.navigationStatus == NavigationStatus.rerouting)
                  const _ReroutingBanner(),
              ],
            ),
          ),

          // ── Layer 4: DEBUG direction buttons (remove before release) ─
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: _DebugDirectionBar(
              selected: _debugDirection,
              onSelect: (d) => setState(
                () => _debugDirection = _debugDirection == d ? null : d,
              ),
            ),
          ),

          // ── Layer 5: Bottom navigation bar ───────────────────────
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: NavigationBottomBar(),
          ),

          // ── Layer 6: Faster route full-screen map preview ─────────
          if (navVM.showFasterRouteMap &&
              navVM.currentRoute != null &&
              navVM.suggestedFasterRoute != null)
            Positioned.fill(
              child: _FasterRouteMapWidget(
                currentRoute: navVM.currentRoute!,
                fasterRoute: navVM.suggestedFasterRoute!,
                userLat: context
                    .read<MapViewModel>()
                    .currentLocation
                    ?.latitude,
                userLng: context
                    .read<MapViewModel>()
                    .currentLocation
                    ?.longitude,
                onAccept: navVM.acceptFasterRoute,
                onDismiss: navVM.dismissFasterRoute,
              ),
            ),
        ],
      ),
      ),
    );
  }
}

// ── Floating top info card ────────────────────────────────────────────────────

class _NavInfoCard extends StatelessWidget {
  const _NavInfoCard({this.directionOverride, this.approachStageOverride});

  final TurnDirection? directionOverride;
  final NavigationApproachStage? approachStageOverride;

  @override
  Widget build(BuildContext context) {
    final arVM = context.watch<ARViewModel>();
    if (arVM.nextTurnDirection == null && directionOverride == null) return const SizedBox.shrink();

    final direction = directionOverride ?? arVM.nextTurnDirection!;
    final distance = arVM.distanceToNextTurn ?? double.infinity;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xCC000000),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      arVM.instructionText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      _formatDistance(distance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    if (arVM.currentStreetName != null)
                      Opacity(
                        opacity: 0.8,
                        child: Text(
                          arVM.currentStreetName!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              DynamicArrowWidget(
                direction: direction,
                distance: distance,
                approachStage: approachStageOverride ?? arVM.approachStage,
                size: 48,
                showLabel: false,
                exitNumber: arVM.roundaboutExit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDistance(double metres) {
    if (metres >= 1000) return '${(metres / 1000).toStringAsFixed(1)} km';
    final rounded = ((metres / 10).round() * 10).clamp(10, 990);
    return '$rounded m';
  }
}

// ── Rerouting banner ──────────────────────────────────────────────────────────

class _ReroutingBanner extends StatelessWidget {
  const _ReroutingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xCC000000),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: const Text(
        'Recalculating route...',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ── Faster route full-screen map preview ─────────────────────────────────────

class _FasterRouteMapWidget extends StatefulWidget {
  const _FasterRouteMapWidget({
    required this.currentRoute,
    required this.fasterRoute,
    this.userLat,
    this.userLng,
    required this.onAccept,
    required this.onDismiss,
  });

  final RouteModel currentRoute;
  final RouteModel fasterRoute;
  final double? userLat;
  final double? userLng;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  @override
  State<_FasterRouteMapWidget> createState() => _FasterRouteMapWidgetState();
}

class _FasterRouteMapWidgetState extends State<_FasterRouteMapWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cancelController;
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _cancelController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onDismiss();
      });
    _cancelController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
  }

  void _fitBounds() {
    final allPoints = [
      ...widget.currentRoute.polylinePoints
          .map((p) => ll.LatLng(p.latitude, p.longitude)),
      ...widget.fasterRoute.polylinePoints
          .map((p) => ll.LatLng(p.latitude, p.longitude)),
    ];
    if (allPoints.isEmpty) return;
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(allPoints),
        padding: const EdgeInsets.all(60),
        maxZoom: 16,
      ),
    );
  }

  @override
  void dispose() {
    _cancelController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPolyline = widget.currentRoute.polylinePoints
        .map((p) => ll.LatLng(p.latitude, p.longitude))
        .toList();
    final fasterPolyline = widget.fasterRoute.polylinePoints
        .map((p) => ll.LatLng(p.latitude, p.longitude))
        .toList();
    final timeSaved = widget.currentRoute.estimatedDuration -
        widget.fasterRoute.estimatedDuration;
    final timeSavedMin = (timeSaved / 60).round();
    final percentSaved =
        (timeSaved / widget.currentRoute.estimatedDuration * 100).round();

    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: ll.LatLng(3.0738, 101.5077),
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.sunway.smart_ar_navigation',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: currentPolyline,
                    color: Colors.blue,
                    strokeWidth: 5.0,
                  ),
                  Polyline(
                    points: fasterPolyline,
                    color: const Color(0xFF00E676),
                    strokeWidth: 5.0,
                  ),
                ],
              ),
              if (widget.userLat != null && widget.userLng != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: ll.LatLng(widget.userLat!, widget.userLng!),
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white,
                              blurRadius: 4,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: const Color(0xDD000000),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Faster route available',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Save $timeSavedMin min ($percentSaved% faster)',
                        style: const TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: _AnimatedCancelButton(
                        controller: _cancelController,
                        onCancel: widget.onDismiss,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Change Route',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
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

class _AnimatedCancelButton extends StatelessWidget {
  const _AnimatedCancelButton({
    required this.controller,
    required this.onCancel,
  });

  final AnimationController controller;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCancel,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 52,
              child: Stack(
                children: [
                  Container(color: const Color(0xFFEEEEEE)),
                  FractionallySizedBox(
                    widthFactor: controller.value,
                    child: Container(color: const Color(0xFFBDBDBD)),
                  ),
                  const Center(
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── DEBUG: temporary direction buttons — remove before release ────────────────

class _DebugDirectionBar extends StatelessWidget {
  const _DebugDirectionBar({required this.selected, required this.onSelect});

  final TurnDirection? selected;
  final ValueChanged<TurnDirection> onSelect;

  static const _buttons = [
    (TurnDirection.right,     'Right'),
    (TurnDirection.left,      'Left'),
    (TurnDirection.keepRight, 'Keep R'),
    (TurnDirection.keepLeft,  'Keep L'),
    (TurnDirection.uTurn,     'U-Turn'),
    (TurnDirection.roundabout,'Rndabt'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: _buttons.map((entry) {
          final (dir, label) = entry;
          final isActive = selected == dir;
          return GestureDetector(
            onTap: () => onSelect(dir),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF00E676)
                    : const Color(0xCC000000),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF00E676)
                      : Colors.white38,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.black : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

