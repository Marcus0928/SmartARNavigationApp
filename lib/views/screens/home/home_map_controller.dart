import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:smart_ar_navigation/models/place_model.dart';
import 'package:smart_ar_navigation/viewmodels/map_viewmodel.dart';

class HomeMapController extends ChangeNotifier {
  HomeMapController({
    required MapController mapController,
    required TickerProvider vsync,
  })  : _mapController = mapController,
        _vsync = vsync;

  final MapController _mapController;
  final TickerProvider _vsync;

  LatLng? smoothedLoc;
  double smoothedHeading = 0.0;
  double mapRotation = 0.0;

  bool _centeredOnUser = false;
  PlaceModel? _lastDestination;
  bool _routeFitted = false;

  AnimationController? _moveController;
  Animation<double>? _latAnim;
  Animation<double>? _lngAnim;
  Animation<double>? _headingAnim;

  // ── Map animations ─────────────────────────────────────────────────────────

  void animatedMove(LatLng dest, double zoom) {
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
      vsync: _vsync,
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

  void animateRotation(double target) {
    final rotTween = Tween<double>(
      begin: _mapController.camera.rotation,
      end: target,
    );
    final controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: _vsync,
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

  // ── Location smoothing ─────────────────────────────────────────────────────

  void smoothMoveTo(LatLng to, double toHeading) {
    final from = smoothedLoc ?? to;
    double delta = (toHeading - smoothedHeading) % 360;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;

    _moveController?.dispose();
    _moveController = AnimationController(
      vsync: _vsync,
      duration: const Duration(milliseconds: 800),
    );
    final curve = CurvedAnimation(parent: _moveController!, curve: Curves.easeOut);

    _latAnim     = Tween<double>(begin: from.latitude,  end: to.latitude).animate(curve);
    _lngAnim     = Tween<double>(begin: from.longitude, end: to.longitude).animate(curve);
    _headingAnim = Tween<double>(
      begin: smoothedHeading,
      end: smoothedHeading + delta,
    ).animate(curve);

    _moveController!.addListener(() {
      smoothedLoc     = LatLng(_latAnim!.value, _lngAnim!.value);
      smoothedHeading = _headingAnim!.value % 360;
      notifyListeners();
    });
    _moveController!.addStatusListener((s) {
      if (s == AnimationStatus.completed || s == AnimationStatus.dismissed) {
        _moveController?.dispose();
        _moveController = null;
      }
    });
    _moveController!.forward();
  }

  void onLocationChanged(MapViewModel vm) {
    final loc = vm.currentLocation;
    if (loc == null) return;
    smoothMoveTo(
      LatLng(loc.latitude, loc.longitude),
      vm.currentHeading ?? smoothedHeading,
    );
  }

  void onMapEvent(MapEvent _) {
    final rotation = _mapController.camera.rotation;
    if (rotation != mapRotation) {
      mapRotation = rotation;
      notifyListeners();
    }
  }

  // ── Build helpers ──────────────────────────────────────────────────────────

  void handleInitialCentering(LatLng? userLatLng) {
    if (userLatLng != null && !_centeredOnUser) {
      _centeredOnUser = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        animatedMove(userLatLng, 16);
      });
    }
  }

  void handleDestinationChange(
    MapViewModel mapVM,
    DraggableScrollableController sheet,
  ) {
    if (mapVM.selectedDestination != _lastDestination) {
      _lastDestination = mapVM.selectedDestination;
      _routeFitted = false;
      if (mapVM.selectedDestination != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (sheet.isAttached) {
            sheet.animateTo(
              0.40,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  void handleRouteFitting(
    MapViewModel mapVM,
    BuildContext context,
    DraggableScrollableController sheet,
  ) {
    if (!_routeFitted && mapVM.previewRoutes.isNotEmpty) {
      _routeFitted = true;
      final sheetHeight = MediaQuery.of(context).size.height * 0.40;
      WidgetsBinding.instance.addPostFrameCallback((_) {
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

  @override
  void dispose() {
    _moveController?.dispose();
    super.dispose();
  }
}
