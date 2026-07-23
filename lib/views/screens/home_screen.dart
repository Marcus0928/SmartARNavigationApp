import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:smart_ar_navigation/core/enums/navigation_status.dart';
import 'package:smart_ar_navigation/core/utils/map_utils.dart';
import 'package:smart_ar_navigation/viewmodels/map_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/navigation_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/recent_places_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/saved_locations_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/saved_places_viewmodel.dart';
import 'package:smart_ar_navigation/views/screens/home/home_map_controller.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/compass_button.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/floating_icon_button.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/home_bottom_sheet.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/home_map_layer.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/speed_indicator.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/waze_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _scaffoldKey    = GlobalKey<ScaffoldState>();
  final _mapController  = MapController();
  final _sheetController = DraggableScrollableController();
  late final HomeMapController _ctrl;

  MapViewModel? _mapVmRef;
  bool _trackingStarted = false;

  @override
  void initState() {
    super.initState();
    _ctrl = HomeMapController(mapController: _mapController, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sheetController.isAttached) _sheetController.jumpTo(0.22);
    });
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
    _ctrl.dispose();
    _mapController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _onLocationChanged() => _ctrl.onLocationChanged(_mapVmRef!);

  @override
  Widget build(BuildContext context) {
    final mapVM          = context.watch<MapViewModel>();
    final navVM          = context.watch<NavigationViewModel>();
    final savedVM        = context.watch<SavedPlacesViewModel>();
    final savedLocationsVM = context.watch<SavedLocationsViewModel>();
    final recentVM       = context.watch<RecentPlacesViewModel>();

    final loc        = mapVM.currentLocation;
    final userLatLng = loc != null ? LatLng(loc.latitude, loc.longitude) : null;
    final topPadding = MediaQuery.of(context).padding.top;

    final navPolyline = navVM.navigationStatus == NavigationStatus.navigating &&
            navVM.remainingPolyline.isNotEmpty &&
            !mapVM.isSelectingRouteFromNav
        ? navVM.remainingPolyline
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList()
        : null;

    _ctrl.handleInitialCentering(userLatLng);
    _ctrl.handleRecenter(mapVM, userLatLng, _sheetController);
    _ctrl.handleDestinationChange(mapVM, _sheetController);
    _ctrl.handleRouteFitting(mapVM, context, _sheetController);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
      key: _scaffoldKey,
      drawer: const WazeDrawer(),
      body: Stack(
        children: [
          // Full-screen map
          Positioned.fill(
            child: ListenableBuilder(
              listenable: _ctrl,
              builder: (_, _) => HomeMapLayer(
                mapController: _mapController,
                smoothedLoc: _ctrl.smoothedLoc,
                smoothedHeading: _ctrl.smoothedHeading,
                currentAccuracy: mapVM.currentAccuracy,
                mapVM: mapVM,
                navigationPolyline: navPolyline,
                onTap: (_, point) => handleRouteTap(point, mapVM),
                onMapEvent: _ctrl.onMapEvent,
              ),
            ),
          ),
          // Hamburger menu — top left
          Positioned(
            top: topPadding + 12,
            left: 12,
            child: FloatingIconButton(
              icon: Icons.menu,
              tooltip: 'Menu',
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
          // GPS + Compass — top right
          Positioned(
            top: topPadding + 12,
            right: 12,
            child: ListenableBuilder(
              listenable: _ctrl,
              builder: (_, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingIconButton(
                    icon: Icons.my_location,
                    tooltip: 'My Location',
                    onPressed: () {
                      if (userLatLng != null) _ctrl.animatedMove(userLatLng, 16);
                    },
                  ),
                  const SizedBox(height: 8),
                  CompassButton(
                    rotation: _ctrl.mapRotation,
                    onPressed: () => _ctrl.animateRotation(0),
                  ),
                ],
              ),
            ),
          ),
          // Draggable bottom sheet floating over map
          Positioned.fill(
            child: HomeBottomSheet(
              sheetController: _sheetController,
              mapVM: mapVM,
              savedVM: savedVM,
              savedLocationsVM: savedLocationsVM,
              recentVM: recentVM,
              onSearchFocused: () => _sheetController.animateTo(
                0.95,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
              ),
              onCancelRoute: () {
                // If the user came from AR navigation (Routes button), return
                // them there instead of dropping them on the home screen.
                if (navVM.navigationStatus == NavigationStatus.navigating) {
                  Navigator.of(context).pushNamed('/ar-navigation');
                  return;
                }
                final loc = mapVM.currentLocation;
                if (loc != null) {
                  _ctrl.animatedMove(LatLng(loc.latitude, loc.longitude), 16);
                }
              },
              activeRouteIndex: navVM.navigationStatus == NavigationStatus.navigating
                  ? navVM.activeRouteIndex
                  : null,
              onStartNavigation: () async {
                final navigator  = Navigator.of(context);
                final messenger  = ScaffoldMessenger.of(context);

                // "Resume": the selected route is already the one actively
                // navigating — just return to the existing AR session instead
                // of restarting it (restarting was also what caused the
                // Resume label to flicker to Start, via the transient
                // idle/loading states startNavigation() passes through).
                final isResume =
                    navVM.navigationStatus == NavigationStatus.navigating &&
                        mapVM.selectedRouteIndex == navVM.activeRouteIndex;

                mapVM.setSelectingRouteFromNav(false);

                if (isResume) {
                  navigator.pushNamed('/ar-navigation');
                  return;
                }

                await navVM.startNavigation(
                  mapVM.selectedDestination!,
                  route: mapVM.selectedRoute,
                  routeIndex: mapVM.selectedRouteIndex,
                );
                if (navVM.errorMessage != null) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(navVM.errorMessage!)),
                  );
                } else if (navVM.navigationStatus == NavigationStatus.navigating &&
                    mounted) {
                  await mapVM.restartLocationTracking();
                  navigator.pushNamed('/ar-navigation');
                }
              },
            ),
          ),
          AnimatedBuilder(
            animation: _sheetController,
            builder: (_, _) {
              final screenH = MediaQuery.of(context).size.height;
              final extent  = _sheetController.isAttached ? _sheetController.size : 0.22;
              return Positioned(
                right: 16,
                bottom: screenH * extent + 8,
                child: SpeedIndicator(speedMs: mapVM.currentSpeed),
              );
            },
          ),
        ],
      ),
      ),
    );
  }
}
