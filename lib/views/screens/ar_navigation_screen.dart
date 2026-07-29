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

import 'package:smart_ar_navigation/models/route_model.dart';
import 'package:smart_ar_navigation/core/enums/navigation_status.dart';
import 'package:smart_ar_navigation/core/utils/distance_formatter.dart';
import 'package:smart_ar_navigation/core/utils/location_utils.dart';
import 'package:smart_ar_navigation/services/ambient_light_service.dart';
import 'package:smart_ar_navigation/services/ar_service.dart';
import 'package:smart_ar_navigation/viewmodels/ar_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/map_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/navigation_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/settings_viewmodel.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/floating_icon_button.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/speed_indicator.dart';
import 'package:smart_ar_navigation/views/widgets/dynamic_arrow_widget.dart';
import 'package:smart_ar_navigation/views/widgets/navigation_bottom_bar.dart';
import 'package:smart_ar_navigation/views/widgets/traffic_delay_badge.dart';

class ARNavigationScreen extends StatefulWidget {
  const ARNavigationScreen({super.key, this.isRecovering = false});

  // True only when this screen instance was mounted by
  // _recoverArViewAfterScreenOff() to replace a screen-off'd instance —
  // gates the "Reconnecting camera..." loading overlay so it never shows
  // on a normal AR navigation launch (Start button already covers that
  // wait via NavigationViewModel.isStartingNavigation).
  final bool isRecovering;

  @override
  State<ARNavigationScreen> createState() => ARNavigationScreenState();
}

class ARNavigationScreenState extends State<ARNavigationScreen>
    with WidgetsBindingObserver {
  bool _arrivalHandled = false;
  bool isExiting = false;

  // Flips true once _onARViewCreated's initializeAR() call completes for
  // THIS screen instance. Only consulted when widget.isRecovering — see
  // that field's doc.
  bool _arReady = false;

  // Set true only in the paused branch below (a genuine screen-off/
  // backgrounding), and reset false only after a resumed-triggered
  // recovery runs. Flutter's lifecycle fires paused -> hidden -> inactive
  // -> resumed on a real screen-off/on cycle (5-state model since Flutter
  // 3.13), so comparing resumed against only the immediately-preceding
  // state (previously _previousLifecycleState) never worked: hidden and
  // inactive always overwrote it before resumed could see paused. This
  // flag survives those intermediate states instead.
  bool _wasGenuinelyPaused = false;

  final _ambientLight = AmbientLightService();
  bool? _lastAutoBrightness;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    context.read<ARService>().disposeAR();
    _ambientLight.dispose();
    WakelockPlus.disable();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Starts/stops the ambient light sensor when the Auto Brightness setting
  // changes, without restarting it on every rebuild.
  void _syncAmbientLight(bool autoBrightness) {
    if (_lastAutoBrightness == autoBrightness) return;
    _lastAutoBrightness = autoBrightness;
    if (autoBrightness) {
      _ambientLight.start();
    } else {
      _ambientLight.stop();
    }
  }

  // Maps the Settings screen's Arrow Size choice to the main chevron's
  // pixel size — the mini top-instruction-card arrow stays fixed at its
  // own hardcoded 48 regardless of this setting.
  double _arrowSizeFor(String arrowSize) => switch (arrowSize) {
        'Small' => 130.0,
        'Large' => 230.0,
        _ => 180.0, // 'Medium' and any unrecognised value
      };

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (isExiting) return;

    if (state == AppLifecycleState.paused) {
      context.read<MapViewModel>().setAppForegroundState(false);
      _wasGenuinelyPaused = true;
    } else if (state == AppLifecycleState.resumed) {
      context.read<MapViewModel>().setAppForegroundState(true);
      // Only recover the camera after a genuine background pause, not a
      // transient `inactive` interruption (e.g. notification shade).
      if (_wasGenuinelyPaused) {
        _wasGenuinelyPaused = false;
        _recoverArViewAfterScreenOff();
      }
    }
  }

  // Replaces the screen via Navigator to recover the camera after
  // screen-off — an in-place recreate doesn't work here. This is a pure
  // screen/ArView swap; the active navigation session is untouched.
  void _recoverArViewAfterScreenOff() {
    isExiting = true;
    // A plain (non-zero-duration) route transition here would slide/fade in
    // right as the fresh ArView's camera is still cold-starting — two
    // separate motions reading as one janky moment. PageRouteBuilder with
    // zero transition durations swaps the screen instantly instead; the
    // _ArRecoveryLoadingOverlay below (widget.isRecovering) then covers the
    // actual camera/ARCore init latency with an intentional loading state.
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) =>
            const ARNavigationScreen(isRecovering: true),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    // whenComplete so the loading overlay clears on failure too, not
    // just success.
    context
        .read<ARViewModel>()
        .initializeAR(sessionManager, objectManager)
        .whenComplete(() {
      if (mounted) setState(() => _arReady = true);
    });
  }

  void _handleArrival(BuildContext context) {
    if (_arrivalHandled) return;
    _arrivalHandled = true;

    isExiting = true;

    final navVM = context.read<NavigationViewModel>();
    final mapVM = context.read<MapViewModel>();
    final arVM = context.read<ARViewModel>();
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

      // Wait for the arrival announcement to finish speaking before leaving,
      // so navigation away doesn't cut it off mid-word.
      // popUntil(first) instead of pop() so this reaches Home correctly
      // regardless of entry path (e.g. via Plan a Drive).
      arVM.announceArrival(() => navigator.popUntil((route) => route.isFirst));
    });
  }

  @override
  Widget build(BuildContext context) {
    final navVM = context.watch<NavigationViewModel>();

    if (navVM.navigationStatus == NavigationStatus.arrived) {
      _handleArrival(context);
    }

    final arVM = context.watch<ARViewModel>();
    final settingsVM = context.watch<SettingsViewModel>();
    _syncAmbientLight(settingsVM.autoBrightness);
    final mapVM = context.watch<MapViewModel>();

    // The faster-route map preview replaces the camera feed, so the AR
    // platform view is hidden while it's shown — otherwise the native
    // platform view can intercept touches meant for the preview's buttons.
    final hideArForFasterRoute =
        navVM.showFasterRouteMap && navVM.suggestedFasterRoute != null;

    // Traffic pill: two content states sharing one badge/visual style —
    // "approaching" (suppressed entirely once farther than 2 km from the
    // jam) and "inside the jam" (shown for as long as GPS sits between the
    // segment's start/end, per NavigationViewModel.hasEnteredTrafficSegment).
    final trafficInfo = navVM.trafficSegmentInfo;
    Widget? trafficBadge;
    if (trafficInfo != null) {
      if (navVM.hasEnteredTrafficSegment) {
        trafficBadge = TrafficDelayBadge(
          segmentInfo: trafficInfo,
          hasEnteredSegment: true,
          jamLengthKm: calculateDistance(
                trafficInfo.segmentStartPosition,
                trafficInfo.segmentEndPosition,
              ) /
              1000,
        );
      } else if (mapVM.currentLocation != null) {
        final distanceAheadKm = calculateDistance(
              mapVM.currentLocation!,
              trafficInfo.segmentStartPosition,
            ) /
            1000;
        if (distanceAheadKm <= 2.0) {
          trafficBadge = TrafficDelayBadge(
            segmentInfo: trafficInfo,
            hasEnteredSegment: false,
            distanceAheadKm: distanceAheadKm,
          );
        }
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final mapVM = context.read<MapViewModel>();
        final navVM = context.read<NavigationViewModel>();
        mapVM.stopLocationTracking();
        await navVM.stopNavigation();
        mapVM.clearDestination();
        if (navigator.canPop()) {
          navigator.pop();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: Scaffold(
      body: Stack(
        children: [
          // ── Layer 1: Full-screen AR camera feed ───────────────────
          // Recovery from a genuine screen-off pause/resume is handled by
          // _recoverArViewAfterScreenOff() replacing this whole screen via
          // the Navigator (see didChangeAppLifecycleState) rather than by
          // toggling this widget in place — see that method's comment for
          // why. hideArForFasterRoute is a separate, unrelated full swap
          // to stop the platform view intercepting touches meant for the
          // faster-route preview's buttons.
          if (!hideArForFasterRoute)
            ARView(onARViewCreated: _onARViewCreated)
          else
            Container(color: Colors.black),

          // ── Layer 1.5: Camera recovery loading state ───────────────
          // Only shown while recovering from a genuine screen-off
          // (widget.isRecovering — see that field's doc), until
          // _onARViewCreated's initializeAR() call actually completes.
          // Masks the fresh ArView's camera/ARCore cold-start latency
          // with an intentional loading state instead of a blank frame.
          if (widget.isRecovering && !_arReady && !hideArForFasterRoute)
            const _ArRecoveryLoadingOverlay(),

          // ── Layer 2: Chevron arrow ────────────────────────────────
          if (arVM.nextTurnDirection != null)
            Positioned.fill(
              child: Center(
                child: ValueListenableBuilder<LightLevel>(
                  valueListenable: _ambientLight.levelNotifier,
                  builder: (context, level, child) {
                    final double opacity;
                    final Color? arrowColor;

                    if (!settingsVM.autoBrightness) {
                      // Manual mode — use the settings slider value.
                      opacity = settingsVM.overlayOpacity;
                      arrowColor = null; // default arrow color
                    } else {
                      switch (level) {
                        case LightLevel.bright:
                          opacity = 1.0;
                          arrowColor = const Color(0xFF00FF87);
                        case LightLevel.normal:
                          opacity = 0.85;
                          arrowColor = const Color(0xFF00E676);
                        case LightLevel.dark:
                          opacity = 0.95;
                          arrowColor = const Color(0xFF00C853);
                      }
                    }

                    return DynamicArrowWidget(
                      direction:     arVM.nextTurnDirection!,
                      distance:      arVM.distanceToNextTurn ?? double.infinity,
                      approachStage: arVM.approachStage,
                      exitNumber: arVM.roundaboutExit,
                      opacityOverride: opacity,
                      colorOverride: arrowColor,
                      distanceUnit: settingsVM.distanceUnit,
                      size: _arrowSizeFor(settingsVM.arrowSize),
                    );
                  },
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
                const _NavInfoCard(),
                if (navVM.navigationStatus == NavigationStatus.rerouting)
                  const _ReroutingBanner(),
              ],
            ),
          ),

          // ── Layer 5: Bottom navigation bar + speed indicator ─────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 16, bottom: 8),
                  child: FloatingIconButton(
                    icon: settingsVM.voiceMuted
                        ? Icons.volume_off
                        : Icons.volume_up,
                    tooltip: settingsVM.voiceMuted
                        ? 'Unmute voice guidance'
                        : 'Mute voice guidance',
                    onPressed: () => context
                        .read<SettingsViewModel>()
                        .setVoiceMuted(!settingsVM.voiceMuted),
                  ),
                ),
                // SpeedIndicator's own Padding/position is unchanged below —
                // wrapping it in this Stack only gives the traffic badge a
                // reliable vertical anchor (same row, centered) without
                // hardcoding a bottom offset that would drift on devices
                // with a different NavigationBottomBar safe-area inset.
                SizedBox(
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (settingsVM.showSpeed)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(right: 16, bottom: 12),
                            child: SpeedIndicator(speedMs: mapVM.currentSpeed),
                          ),
                        ),
                      ?trafficBadge,
                    ],
                  ),
                ),
                const NavigationBottomBar(),
              ],
            ),
          ),

          // ── Layer 6: Faster route full-screen map preview ─────────
          if (navVM.showFasterRouteMap &&
              navVM.currentRoute != null &&
              navVM.suggestedFasterRoute != null)
            Positioned.fill(
              child: _FasterRouteMapWidget(
                currentRoute: navVM.currentRoute!,
                remainingPolyline: navVM.remainingPolyline
                    .map((p) => ll.LatLng(p.latitude, p.longitude))
                    .toList(),
                suggestedRoute: navVM.suggestedFasterRoute!,
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
      ),
    );
  }
}

// ── Floating top info card ────────────────────────────────────────────────────

class _NavInfoCard extends StatelessWidget {
  const _NavInfoCard();

  @override
  Widget build(BuildContext context) {
    final arVM = context.watch<ARViewModel>();
    final settingsVM = context.watch<SettingsViewModel>();
    if (arVM.nextTurnDirection == null) return const SizedBox.shrink();

    final direction = arVM.nextTurnDirection!;
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
                      formatDistance(distance, settingsVM.distanceUnit),
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
                approachStage: arVM.approachStage,
                size: 48,
                showLabel: false,
                exitNumber: arVM.roundaboutExit,
                distanceUnit: settingsVM.distanceUnit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Camera recovery loading overlay ─────────────────────────────────────────
// Same visual pattern as SplashScreen's loading state (white
// CircularProgressIndicator + white70 caption) for consistency.

class _ArRecoveryLoadingOverlay extends StatelessWidget {
  const _ArRecoveryLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Reconnecting camera...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
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
    required this.remainingPolyline,
    required this.suggestedRoute,
    this.userLat,
    this.userLng,
    required this.onAccept,
    required this.onDismiss,
  });

  final RouteModel currentRoute;
  final List<ll.LatLng> remainingPolyline;
  final RouteModel suggestedRoute;
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
    if (!mounted) return;
    final allPoints = [
      ...widget.remainingPolyline,
      ...widget.suggestedRoute.polylinePoints
          .map((p) => ll.LatLng(p.latitude, p.longitude)),
    ];
    if (allPoints.isEmpty) return;
    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(allPoints),
          padding: const EdgeInsets.all(60),
          maxZoom: 16,
        ),
      );
    } catch (e) {
      debugPrint('fitBounds error: $e');
    }
  }

  @override
  void dispose() {
    _cancelController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPolyline = widget.remainingPolyline;
    final fasterPolyline = widget.suggestedRoute.polylinePoints
        .map((p) => ll.LatLng(p.latitude, p.longitude))
        .toList();
    final timeSaved = widget.currentRoute.estimatedDuration -
        widget.suggestedRoute.estimatedDuration;
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


