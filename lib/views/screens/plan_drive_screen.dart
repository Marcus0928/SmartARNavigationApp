import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/models/place_model.dart';
import 'package:smart_ar_navigation/viewmodels/navigation_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/plan_drive_viewmodel.dart';
import 'package:smart_ar_navigation/views/screens/plan_drive/widgets/plan_drive_input_card.dart';
import 'package:smart_ar_navigation/views/screens/plan_drive/widgets/plan_drive_map.dart';
import 'package:smart_ar_navigation/views/screens/plan_drive/widgets/plan_drive_options_row.dart';
import 'package:smart_ar_navigation/views/screens/plan_drive/widgets/route_alternatives_strip.dart';
import 'package:smart_ar_navigation/views/screens/plan_drive/widgets/route_summary_card.dart';
import 'package:smart_ar_navigation/views/screens/plan_drive/widgets/search_overlay.dart';

class PlanDriveScreen extends StatefulWidget {
  const PlanDriveScreen({super.key});

  @override
  State<PlanDriveScreen> createState() => _PlanDriveScreenState();
}

enum _ActiveField { none, from, to }

class _PlanDriveScreenState extends State<PlanDriveScreen> {
  final _mapController = MapController();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _fromFocus = FocusNode();
  final _toFocus = FocusNode();

  _ActiveField _activeField = _ActiveField.none;
  PlaceModel? _lastDestination;
  bool _routeFitted = false;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fromController.text = 'Your location';
    _fromFocus.addListener(_onFromFocusChange);
    _toFocus.addListener(_onToFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanDriveViewModel>().init();
    });
  }

  @override
  void dispose() {
    _fromFocus.removeListener(_onFromFocusChange);
    _toFocus.removeListener(_onToFocusChange);
    _mapController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    super.dispose();
  }

  // ── Focus handlers ────────────────────────────────────────────────────────

  void _onFromFocusChange() {
    if (_fromFocus.hasFocus) {
      setState(() => _activeField = _ActiveField.from);
      if (_fromController.text == 'Your location') _fromController.clear();
    } else {
      if (_activeField == _ActiveField.from) {
        setState(() => _activeField = _ActiveField.none);
      }
      final vm = context.read<PlanDriveViewModel>();
      vm.clearFromResults();
      _fromController.text = vm.fromLabel;
    }
  }

  void _onToFocusChange() {
    if (_toFocus.hasFocus) {
      setState(() => _activeField = _ActiveField.to);
    } else {
      if (_activeField == _ActiveField.to) {
        setState(() => _activeField = _ActiveField.none);
      }
      context.read<PlanDriveViewModel>().clearToResults();
    }
  }

  // ── Selection handlers ────────────────────────────────────────────────────

  void _onSelectFromResult(PlaceModel place, PlanDriveViewModel vm) {
    _fromController.text = place.name;
    _fromFocus.unfocus();
    vm.selectFrom(place);
  }

  void _onSelectToResult(PlaceModel place, PlanDriveViewModel vm) {
    _toController.text = place.name;
    _toFocus.unfocus();
    vm.selectTo(place);
  }

  void _swap(PlanDriveViewModel vm) {
    final fromText = _fromController.text;
    _fromController.text = _toController.text;
    _toController.text = fromText;
    _routeFitted = false;
    vm.swapLocations();
  }

  // ── Map camera ────────────────────────────────────────────────────────────

  void _fitRoute(PlanDriveViewModel vm) {
    if (vm.routes.isEmpty) return;
    final points = vm.routes[vm.selectedRouteIndex]
        .polylinePoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();
    if (points.length < 2) return;

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.fromLTRB(40, 40, 40, 300),
        maxZoom: 16,
      ),
    );
    if (_mapController.camera.zoom < 12) {
      _mapController.move(_mapController.camera.center, 12.0);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlanDriveViewModel>();
    final navVM = context.watch<NavigationViewModel>();

    if (vm.destination != _lastDestination) {
      _lastDestination = vm.destination;
      _routeFitted = false;
    }

    if (!_routeFitted && vm.routes.isNotEmpty) {
      _routeFitted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitRoute(vm);
      });
    }

    final activeResults =
        _activeField == _ActiveField.from ? vm.fromResults : vm.toResults;
    final showResults = activeResults.isNotEmpty;
    final showRouteCard =
        !showResults && (vm.routes.isNotEmpty || vm.isFetching || vm.error != null);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Plan a Drive',
          style: TextStyle(
            color: textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      body: Column(
        children: [
          PlanDriveInputCard(
            fromController: _fromController,
            toController: _toController,
            fromFocus: _fromFocus,
            toFocus: _toFocus,
            vm: vm,
            onSwap: () => _swap(vm),
            onClearTo: vm.clearTo,
          ),
          PlanDriveOptionsRow(vm: vm),
          Expanded(
            child: Stack(
              children: [
                PlanDriveMap(mapController: _mapController, vm: vm),
                if (showResults)
                  SearchOverlay(
                    results: activeResults,
                    onSelect: _activeField == _ActiveField.from
                        ? (p) => _onSelectFromResult(p, vm)
                        : (p) => _onSelectToResult(p, vm),
                  ),
              ],
            ),
          ),
          if (showRouteCard && vm.routes.isNotEmpty)
            RouteAlternativesStrip(
              vm: vm,
              onSelectRoute: (i) {
                vm.selectRoute(i);
                _routeFitted = false;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _fitRoute(vm);
                });
              },
            ),
          if (showRouteCard)
            RouteSummaryCard(
              vm: vm,
              onStart: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                await navVM.startNavigation(
                  vm.destination!,
                  route: vm.selectedRoute,
                );
                if (!context.mounted) return;
                if (navVM.errorMessage != null) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(navVM.errorMessage!)),
                  );
                } else {
                  navigator.pushNamed('/ar-navigation');
                }
              },
            ),
        ],
      ),
    );
  }
}
