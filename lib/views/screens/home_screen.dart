import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/core/utils/location_utils.dart';
import 'package:smart_ar_navigation/models/place_model.dart';
import 'package:smart_ar_navigation/viewmodels/map_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/navigation_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/saved_locations_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/saved_places_viewmodel.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/saved_locations_sheet.dart';
import 'package:smart_ar_navigation/views/widgets/search_bar_widget.dart';

import 'package:smart_ar_navigation/views/screens/home/widgets/compass_button.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/floating_icon_button.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/location_indicator.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/place_options_sheet.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/place_search_sheet.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/quick_place_button.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/route_preview_card.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/speed_indicator.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/waze_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  static const _defaultCenter = LatLng(3.0738, 101.5077);

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

    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );

    controller.addListener(() {
      _mapController.moveAndRotate(
        LatLng(
          latTween.evaluate(animation),
          lngTween.evaluate(animation),
        ),
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

    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );

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

  void _smoothMoveTo(LatLng to, double toHeading) {
    final from = _smoothedLoc ?? to;

    double delta = (toHeading - _smoothedHeading) % 360;

    if (delta > 180) {
      delta -= 360;
    }

    if (delta < -180) {
      delta += 360;
    }

    _moveController?.dispose();

    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    final curve = CurvedAnimation(
      parent: _moveController!,
      curve: Curves.easeOut,
    );

    _latAnim = Tween<double>(
      begin: from.latitude,
      end: to.latitude,
    ).animate(curve);

    _lngAnim = Tween<double>(
      begin: from.longitude,
      end: to.longitude,
    ).animate(curve);

    _headingAnim = Tween<double>(
      begin: _smoothedHeading,
      end: _smoothedHeading + delta,
    ).animate(curve);

    _moveController!.addListener(() {
      if (!mounted) return;

      setState(() {
        _smoothedLoc = LatLng(
          _latAnim!.value,
          _lngAnim!.value,
        );

        _smoothedHeading = _headingAnim!.value % 360;
      });
    });

    _moveController!.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) => PlaceOptionsSheet(
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

  void _showSavedLocationsSheet(
    SavedLocationsViewModel vm,
    MapViewModel mapVM,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SavedLocationsSheet(vm: vm, mapVM: mapVM),
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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) => PlaceSearchSheet(
        type: type,
        label: label,
        vm: savedVM,
      ),
    ).whenComplete(savedVM.clearSearch);
  }

  String _formatSearchDistance(double metres) {
    if (metres >= 1000) {
      return '${(metres / 1000).toStringAsFixed(1)} km';
    }

    return '${metres.round()} m';
  }

  // ── Route tap selection ───────────────────────────────────────────────────

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

    if (closestIndex != -1 && minDist < 40.0) {
      mapVM.selectRoute(closestIndex);
    }
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

  @override
  Widget build(BuildContext context) {
    final mapVM = context.watch<MapViewModel>();
    final navVM = context.watch<NavigationViewModel>();
    final savedVM = context.watch<SavedPlacesViewModel>();
    final savedLocationsVM = context.watch<SavedLocationsViewModel>();

    final loc = mapVM.currentLocation;
    final userLatLng = loc != null
        ? LatLng(
            loc.latitude,
            loc.longitude,
          )
        : null;

    if (userLatLng != null && !_centeredOnUser) {
      _centeredOnUser = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animatedMove(userLatLng, 16);
      });
    }

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
        // Clamp minimum zoom so the camera never zooms out beyond city level
        if (_mapController.camera.zoom < 12) {
          _mapController.move(_mapController.camera.center, 12.0);
        }
      });
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: const WazeDrawer(),
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _defaultCenter,
                initialZoom: 16,
                onTap: (_, point) => _handleMapTap(point, mapVM),
                onMapEvent: (event) {
                  final rotation = _mapController.camera.rotation;

                  if (rotation != _mapRotation) {
                    setState(() => _mapRotation = rotation);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.sunway.smart_ar_navigation',
                ),

                if (_smoothedLoc != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _smoothedLoc!,
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

                if (_smoothedLoc != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _smoothedLoc!,
                        width: 44,
                        height: 44,
                        child: LocationIndicator(
                          heading: _smoothedHeading,
                        ),
                      ),
                    ],
                  ),

                if (mapVM.previewRoutes.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      // Transparent hit-buffer on unselected routes (wider tap target)
                      ...mapVM.previewRoutes.asMap().entries
                          .where((e) => e.key != mapVM.selectedRouteIndex)
                          .map(
                            (e) => Polyline(
                              points: e.value.polylinePoints
                                  .map((p) => LatLng(p.latitude, p.longitude))
                                  .toList(),
                              color: Colors.transparent,
                              strokeWidth: 20.0,
                            ),
                          ),
                      // Unselected routes — visible grey
                      ...mapVM.previewRoutes.asMap().entries
                          .where((e) => e.key != mapVM.selectedRouteIndex)
                          .map(
                            (e) => Polyline(
                              points: e.value.polylinePoints
                                  .map((p) => LatLng(p.latitude, p.longitude))
                                  .toList(),
                              color: const Color(0xFFB0BEC5),
                              strokeWidth: 4.5,
                            ),
                          ),
                      // Selected route — highlighted on top
                      Polyline(
                        points: mapVM.previewRoutes[mapVM.selectedRouteIndex]
                            .polylinePoints
                            .map((p) => LatLng(p.latitude, p.longitude))
                            .toList(),
                        color: primaryColor,
                        strokeWidth: 6.0,
                        borderColor: Colors.white,
                        borderStrokeWidth: 2.0,
                      ),
                    ],
                  ),

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

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: FloatingIconButton(
                icon: Icons.menu,
                tooltip: 'Menu',
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            ),
          ),

          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingIconButton(
                      icon: Icons.my_location,
                      tooltip: 'My Location',
                      onPressed: () {
                        if (userLatLng != null) {
                          _animatedMove(userLatLng, 16);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    CompassButton(
                      rotation: _mapRotation,
                      onPressed: () => _animateRotation(0),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.22,
              minChildSize: 0.12,
              maxChildSize: 0.95,
              snap: true,
              snapSizes: const [0.22, 0.40, 0.95],
              builder: (sheetContext, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
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
                                SearchBarWidget(
                                  onFocused: () {
                                    _sheetController.animateTo(
                                      0.95,
                                      duration: const Duration(
                                        milliseconds: 350,
                                      ),
                                      curve: Curves.easeOut,
                                    );
                                  },
                                ),

                                if (mapVM.searchResults.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  ...mapVM.searchResults.map(
                                    (place) => Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          onTap: () {
                                            mapVM.selectDestination(place);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                              horizontal: 4,
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 38,
                                                  height: 38,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade100,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.location_on_outlined,
                                                    size: 20,
                                                    color: Color(0xFF1A73E8),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        place.name,
                                                        style:
                                                            const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        place.address,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors
                                                              .grey.shade500,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (mapVM.currentLocation !=
                                                    null) ...[
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    _formatSearchDistance(
                                                      calculateDistance(
                                                        mapVM.currentLocation!,
                                                        place.coordinates,
                                                      ),
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          Colors.grey.shade500,
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(width: 4),
                                                GestureDetector(
                                                  onTap: () => savedLocationsVM
                                                      .toggle(place),
                                                  child: Icon(
                                                    savedLocationsVM.isSaved(
                                                            place.placeId)
                                                        ? Icons.bookmark_rounded
                                                        : Icons
                                                            .bookmark_border_rounded,
                                                    size: 22,
                                                    color: savedLocationsVM
                                                            .isSaved(
                                                                place.placeId)
                                                        ? primaryColor
                                                        : Colors.grey.shade400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Divider(
                                          height: 1,
                                          color: Colors.grey.shade100,
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else if (mapVM.selectedDestination != null) ...[
                                  const SizedBox(height: 12),
                                  RoutePreviewCard(
                                    destination: mapVM.selectedDestination!,
                                    routes: mapVM.previewRoutes,
                                    selectedIndex: mapVM.selectedRouteIndex,
                                    isFetching: mapVM.isFetchingRoute,
                                    onSelectRoute: mapVM.selectRoute,
                                    onClear: mapVM.clearDestination,
                                    onStart: () async {
                                      await navVM.startNavigation(
                                        mapVM.selectedDestination!,
                                        route: mapVM.selectedRoute,
                                      );

                                      if (!context.mounted) return;

                                      if (navVM.errorMessage != null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              navVM.errorMessage!,
                                            ),
                                          ),
                                        );
                                      } else {
                                        Navigator.of(context).pushNamed(
                                          '/ar-navigation',
                                        );
                                      }
                                    },
                                  ),
                                ] else ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      QuickPlaceButton(
                                        icon: Icons.home_outlined,
                                        label: 'Home',
                                        place: savedVM.home,
                                        onTap: () {
                                          _onQuickTap(
                                            SavedPlaceType.home,
                                            'Home',
                                            savedVM,
                                            mapVM,
                                          );
                                        },
                                        onLongPress: () {
                                          _onQuickLongPress(
                                            SavedPlaceType.home,
                                            'Home',
                                            savedVM,
                                            mapVM,
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      QuickPlaceButton(
                                        icon: Icons.work_outline,
                                        label: 'Work',
                                        place: savedVM.work,
                                        onTap: () {
                                          _onQuickTap(
                                            SavedPlaceType.work,
                                            'Work',
                                            savedVM,
                                            mapVM,
                                          );
                                        },
                                        onLongPress: () {
                                          _onQuickLongPress(
                                            SavedPlaceType.work,
                                            'Work',
                                            savedVM,
                                            mapVM,
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      QuickPlaceButton(
                                        icon: Icons.star_border_rounded,
                                        label: 'Favourite',
                                        place: savedVM.favourite,
                                        onTap: () {
                                          _onQuickTap(
                                            SavedPlaceType.favourite,
                                            'Favourite',
                                            savedVM,
                                            mapVM,
                                          );
                                        },
                                        onLongPress: () {
                                          _onQuickLongPress(
                                            SavedPlaceType.favourite,
                                            'Favourite',
                                            savedVM,
                                            mapVM,
                                          );
                                        },
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () => _showSavedLocationsSheet(
                                        savedLocationsVM, mapVM),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            savedLocationsVM.count > 0
                                                ? Icons.bookmark_rounded
                                                : Icons
                                                    .bookmark_border_rounded,
                                            size: 20,
                                            color: savedLocationsVM.count > 0
                                                ? primaryColor
                                                : Colors.grey.shade500,
                                          ),
                                          const SizedBox(width: 10),
                                          const Text(
                                            'Saved Places',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            savedLocationsVM.count > 0
                                                ? '${savedLocationsVM.count} place${savedLocationsVM.count == 1 ? '' : 's'}'
                                                : 'None saved',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            size: 18,
                                            color: Colors.grey.shade400,
                                          ),
                                        ],
                                      ),
                                    ),
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

          AnimatedBuilder(
            animation: _sheetController,
            builder: (_, _) {
              final screenHeight = MediaQuery.of(context).size.height;

              final extent = _sheetController.isAttached
                  ? _sheetController.size
                  : 0.22;

              return Positioned(
                right: 16,
                bottom: screenHeight * extent + 8,
                child: SpeedIndicator(
                  speedMs: mapVM.currentSpeed,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}