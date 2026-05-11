import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:smart_ar_navigation/core/utils/location_utils.dart';
import 'package:smart_ar_navigation/models/place_model.dart';
import 'package:smart_ar_navigation/viewmodels/map_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/navigation_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/saved_locations_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/saved_places_viewmodel.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/home_bottom_sheet.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/home_controls.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/home_map_layer.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/speed_indicator.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/waze_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _mapController = MapController();
  final _sheetController = DraggableScrollableController();

  bool _trackingStarted = false;
  bool _centeredOnUser = false;
  double _mapRotation = 0.0;

  LatLng? _smoothedLoc;
  double _smoothedHeading = 0.0;

  AnimationController? _moveController;
  Animation<double>? _latAnim;
  Animation<double>? _lngAnim;
  Animation<double>? _headingAnim;

  MapViewModel? _mapVmRef;
  PlaceModel? _lastDestination;
  bool _routeFitted = false;

  // ── Map animations ────────────────────────────────────────────────────────

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
    final rotTween = Tween<double>(
      begin: _mapController.camera.rotation,
      end: 0.0,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );
    final anim = CurvedAnimation(parent: controller, curve: Curves.easeInOut);

    controller.addListener(() {
      _mapController.moveAndRotate(
        LatLng(latTween.evaluate(anim), lngTween.evaluate(anim)),
        zoomTween.evaluate(anim),
        rotTween.evaluate(anim),
      );
    });
    controller.addStatusListener((s) {
      if (s == AnimationStatus.completed || s == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });
    controller.forward();
  }

  void _animateRotation(double target) {
    final rotTween = Tween<double>(
      begin: _mapController.camera.rotation,
      end: target,
    );
    final controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    final anim = CurvedAnimation(parent: controller, curve: Curves.easeInOut);

    controller.addListener(() => _mapController.rotate(rotTween.evaluate(anim)));
    controller.addStatusListener((s) {
      if (s == AnimationStatus.completed || s == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });
    controller.forward();
  }

  // ── Location smoothing ────────────────────────────────────────────────────

  void _smoothMoveTo(LatLng to, double toHeading) {
    final from = _smoothedLoc ?? to;
    double delta = (toHeading - _smoothedHeading) % 360;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;

    _moveController?.dispose();
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    final curve = CurvedAnimation(parent: _moveController!, curve: Curves.easeOut);

    _latAnim = Tween<double>(begin: from.latitude, end: to.latitude).animate(curve);
    _lngAnim = Tween<double>(begin: from.longitude, end: to.longitude).animate(curve);
    _headingAnim = Tween<double>(
      begin: _smoothedHeading,
      end: _smoothedHeading + delta,
    ).animate(curve);

    _moveController!.addListener(() {
      if (!mounted) return;
      setState(() {
        _smoothedLoc = LatLng(_latAnim!.value, _lngAnim!.value);
        _smoothedHeading = _headingAnim!.value % 360;
      });
    });
    _moveController!.addStatusListener((s) {
      if (s == AnimationStatus.completed || s == AnimationStatus.dismissed) {
        _moveController?.dispose();
        _moveController = null;
      }
    });
    _moveController!.forward();
  }

  void _onLocationChanged() {
    final vm = _mapVmRef;
    if (vm == null) return;
    final loc = vm.currentLocation;
    if (loc == null) return;
    _smoothMoveTo(
      LatLng(loc.latitude, loc.longitude),
      vm.currentHeading ?? _smoothedHeading,
    );
  }

  // ── Route tap hit-test ────────────────────────────────────────────────────

  void _handleMapTap(LatLng tapPoint, MapViewModel mapVM) {
    if (mapVM.previewRoutes.length <= 1) return;
    final tap = gm.LatLng(tapPoint.latitude, tapPoint.longitude);
    double minDist = double.infinity;
    int closestIndex = -1;

    for (int i = 0; i < mapVM.previewRoutes.length; i++) {
      if (i == mapVM.selectedRouteIndex) continue;
      final d = _minDistToPolyline(tap, mapVM.previewRoutes[i].polylinePoints);
      if (d < minDist) {
        minDist = d;
        closestIndex = i;
      }
    }

    if (closestIndex != -1 && minDist < 40.0) mapVM.selectRoute(closestIndex);
  }

  double _minDistToPolyline(gm.LatLng p, List<gm.LatLng> pts) {
    double min = double.infinity;
    for (int i = 0; i < pts.length - 1; i++) {
      final d = _distToSegment(p, pts[i], pts[i + 1]);
      if (d < min) min = d;
    }
    return min;
  }

  double _distToSegment(gm.LatLng p, gm.LatLng a, gm.LatLng b) {
    final dab = calculateDistance(a, b);
    if (dab < 1.0) return calculateDistance(p, a);
    final t = (((p.latitude - a.latitude) * (b.latitude - a.latitude) +
                (p.longitude - a.longitude) * (b.longitude - a.longitude)) /
               ((b.latitude - a.latitude) * (b.latitude - a.latitude) +
                (b.longitude - a.longitude) * (b.longitude - a.longitude)))
        .clamp(0.0, 1.0);
    final proj = gm.LatLng(
      a.latitude + t * (b.latitude - a.latitude),
      a.longitude + t * (b.longitude - a.longitude),
    );
    return calculateDistance(p, proj);
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_trackingStarted) {
      _trackingStarted = true;
      context.read<MapViewModel>().startLocationTracking();
    }
    final vm = context.read<MapViewModel>();
    if (vm != _mapVmRef) {
      _mapVmRef?.removeListener(_onLocationChanged);
      _mapVmRef = vm;
      vm.addListener(_onLocationChanged);
    }
  }

  @override
  void dispose() {
    _mapVmRef?.removeListener(_onLocationChanged);
    _moveController?.dispose();
    _mapController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  // ── Build helpers (called from build — no setState, only postFrameCallbacks) ──

  void _handleInitialCentering(LatLng? userLatLng) {
    if (userLatLng != null && !_centeredOnUser) {
      _centeredOnUser = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animatedMove(userLatLng, 16);
      });
    }
  }

  void _handleDestinationChange(MapViewModel mapVM) {
    if (mapVM.selectedDestination != _lastDestination) {
      _lastDestination = mapVM.selectedDestination;
      _routeFitted = false;
      if (mapVM.selectedDestination != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _sheetController.isAttached) {
            _sheetController.animateTo(
              0.40,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  void _handleRouteFitting(MapViewModel mapVM) {
    if (!_routeFitted && mapVM.previewRoutes.isNotEmpty) {
      _routeFitted = true;
      final sheetHeight = MediaQuery.of(context).size.height * 0.40;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final points = mapVM.previewRoutes[mapVM.selectedRouteIndex]
            .polylinePoints
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();
        if (points.length < 2) return;
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(points),
            padding: EdgeInsets.fromLTRB(40, 80, 40, sheetHeight + 24),
            maxZoom: 16,
          ),
        );
        if (_mapController.camera.zoom < 12) {
          _mapController.move(_mapController.camera.center, 12.0);
        }
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mapVM = context.watch<MapViewModel>();
    final navVM = context.watch<NavigationViewModel>();
    final savedVM = context.watch<SavedPlacesViewModel>();
    final savedLocationsVM = context.watch<SavedLocationsViewModel>();

    final loc = mapVM.currentLocation;
    final userLatLng = loc != null ? LatLng(loc.latitude, loc.longitude) : null;

    _handleInitialCentering(userLatLng);
    _handleDestinationChange(mapVM);
    _handleRouteFitting(mapVM);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const WazeDrawer(),
      body: Stack(
        children: [
          Positioned.fill(
            child: HomeMapLayer(
              mapController: _mapController,
              smoothedLoc: _smoothedLoc,
              smoothedHeading: _smoothedHeading,
              currentAccuracy: mapVM.currentAccuracy,
              mapVM: mapVM,
              onTap: (_, point) => _handleMapTap(point, mapVM),
              onMapEvent: (_) {
                final rotation = _mapController.camera.rotation;
                if (rotation != _mapRotation) {
                  setState(() => _mapRotation = rotation);
                }
              },
            ),
          ),
          HomeControls(
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            onMyLocationTap: () {
              if (userLatLng != null) _animatedMove(userLatLng, 16);
            },
            onCompassTap: () => _animateRotation(0),
            mapRotation: _mapRotation,
          ),
          Positioned.fill(
            child: HomeBottomSheet(
              sheetController: _sheetController,
              mapVM: mapVM,
              savedVM: savedVM,
              savedLocationsVM: savedLocationsVM,
              onSearchFocused: () => _sheetController.animateTo(
                0.95,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
              ),
              onStartNavigation: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                await navVM.startNavigation(
                  mapVM.selectedDestination!,
                  route: mapVM.selectedRoute,
                );
                if (navVM.errorMessage != null) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(navVM.errorMessage!)),
                  );
                } else {
                  navigator.pushNamed('/ar-navigation');
                }
              },
            ),
          ),
          AnimatedBuilder(
            animation: _sheetController,
            builder: (_, _) {
              final screenH = MediaQuery.of(context).size.height;
              final extent =
                  _sheetController.isAttached ? _sheetController.size : 0.22;
              return Positioned(
                right: 16,
                bottom: screenH * extent + 8,
                child: SpeedIndicator(speedMs: mapVM.currentSpeed),
              );
            },
          ),
        ],
      ),
    );
  }
}
