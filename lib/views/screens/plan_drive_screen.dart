import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/core/constants/app_strings.dart';
import 'package:smart_ar_navigation/models/place_model.dart';
import 'package:smart_ar_navigation/viewmodels/navigation_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/plan_drive_viewmodel.dart';

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

  void _onFromFocusChange() {
    if (_fromFocus.hasFocus) {
      setState(() => _activeField = _ActiveField.from);
      if (_fromController.text == 'Your location') {
        _fromController.clear();
      }
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
        // 88 alternatives strip + ~190 summary card + buffer
        padding: const EdgeInsets.fromLTRB(40, 40, 40, 300),
        maxZoom: 16,
      ),
    );
    if (_mapController.camera.zoom < 12) {
      _mapController.move(_mapController.camera.center, 12.0);
    }
  }

  String _formatETA(int seconds) {
    final eta = DateTime.now().add(Duration(seconds: seconds));
    final h = eta.hour;
    final m = eta.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $period';
  }

  String _formatDistance(double metres) {
    if (metres >= 1000) return '${(metres / 1000).toStringAsFixed(1)} km';
    return '${metres.toInt()} m';
  }

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

    final activeResults = _activeField == _ActiveField.from
        ? vm.fromResults
        : vm.toResults;
    final showResults = activeResults.isNotEmpty;
    final showRouteCard = !showResults &&
        (vm.routes.isNotEmpty || vm.isFetching || vm.error != null);

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
          _buildInputCard(vm),
          _buildOptionsRow(vm),
          Expanded(
            child: Stack(
              children: [
                _buildMap(vm),
                if (showResults)
                  _buildSearchOverlay(activeResults, vm),
              ],
            ),
          ),
          if (showRouteCard && vm.routes.isNotEmpty)
            _buildRouteAlternatives(vm),
          if (showRouteCard) _buildRouteCard(vm, navVM),
        ],
      ),
    );
  }

  // ── Input card ─────────────────────────────────────────────────────────────

  Widget _buildInputCard(PlanDriveViewModel vm) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // From row
          Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Icon(Icons.circle, size: 10, color: primaryColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _fromController,
                  focusNode: _fromFocus,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'From',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: vm.searchFrom,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.swap_vert,
                  color: vm.destination != null
                      ? Colors.grey.shade600
                      : Colors.grey.shade300,
                ),
                onPressed: vm.destination != null ? () => _swap(vm) : null,
                tooltip: 'Swap origin and destination',
              ),
            ],
          ),
          Divider(height: 1, color: Colors.grey.shade200, indent: 36),
          // To row
          Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 14),
                child: Icon(Icons.location_on, size: 16, color: Colors.red),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _toController,
                  focusNode: _toFocus,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Where to?',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: vm.searchTo,
                ),
              ),
              if (_toController.text.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.clear,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                  onPressed: () {
                    _toController.clear();
                    vm.clearTo();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Options row ────────────────────────────────────────────────────────────

  Widget _buildOptionsRow(PlanDriveViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          _OptionChip(
            label: 'Avoid Tolls',
            active: vm.avoidTolls,
            onTap: vm.toggleAvoidTolls,
          ),
          const SizedBox(width: 8),
          _OptionChip(
            label: 'Avoid Highways',
            active: vm.avoidHighways,
            onTap: vm.toggleAvoidHighways,
          ),
        ],
      ),
    );
  }

  // ── Map ────────────────────────────────────────────────────────────────────

  Widget _buildMap(PlanDriveViewModel vm) {
    const defaultCenter = LatLng(3.0738, 101.5077);

    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: defaultCenter,
        initialZoom: 13,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.sunway.smart_ar_navigation',
        ),

        if (vm.routes.isNotEmpty)
          PolylineLayer(
            polylines: [
              // Unselected routes — grey
              ...vm.routes
                  .asMap()
                  .entries
                  .where((e) => e.key != vm.selectedRouteIndex)
                  .map(
                    (e) => Polyline(
                      points: e.value.polylinePoints
                          .map((p) => LatLng(p.latitude, p.longitude))
                          .toList(),
                      color: const Color(0xFFB0BEC5),
                      strokeWidth: 4.5,
                    ),
                  ),
              // Selected route — blue with white border
              Polyline(
                points: vm.routes[vm.selectedRouteIndex]
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

        // Destination pin
        if (vm.destination != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(
                  vm.destination!.coordinates.latitude,
                  vm.destination!.coordinates.longitude,
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

        // Origin dot
        if (vm.fromLatLng != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(
                  vm.fromLatLng!.latitude,
                  vm.fromLatLng!.longitude,
                ),
                width: 22,
                height: 22,
                child: Container(
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
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
    );
  }

  // ── Search overlay ─────────────────────────────────────────────────────────

  Widget _buildSearchOverlay(
    List<PlaceModel> results,
    PlanDriveViewModel vm,
  ) {
    return Positioned.fill(
      child: Material(
        color: Colors.white,
        child: ListView.separated(
          itemCount: results.length,
          separatorBuilder: (_, _) =>
              Divider(height: 1, color: Colors.grey.shade100),
          itemBuilder: (_, i) {
            final place = results[i];
            return ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: primaryColor,
                ),
              ),
              title: Text(
                place.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                place.address,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _activeField == _ActiveField.from
                  ? _onSelectFromResult(place, vm)
                  : _onSelectToResult(place, vm),
            );
          },
        ),
      ),
    );
  }

  // ── Route alternatives strip ───────────────────────────────────────────────

  Widget _buildRouteAlternatives(PlanDriveViewModel vm) {
    final fastestIndex = vm.routes
        .asMap()
        .entries
        .reduce(
          (a, b) => a.value.estimatedDuration <= b.value.estimatedDuration
              ? a
              : b,
        )
        .key;

    return Container(
      height: 90,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        itemCount: vm.routes.length,
        itemBuilder: (_, i) {
          final r = vm.routes[i];
          final selected = i == vm.selectedRouteIndex;
          final fastest = i == fastestIndex && vm.routes.length > 1;
          final durationMin = (r.estimatedDuration / 60).ceil();

          return GestureDetector(
            onTap: () {
              vm.selectRoute(i);
              _routeFitted = false;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _fitRoute(vm);
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 155,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: selected ? primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? primaryColor : Colors.grey.shade200,
                ),
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0x351A73E8),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Name row + fastest badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white70
                                : Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (fastest)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white.withValues(alpha: 0.25)
                                : const Color(0xFFE8F0FE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Fastest',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Duration (prominent)
                  Text(
                    '$durationMin min',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : textPrimary,
                    ),
                  ),
                  // Distance
                  Text(
                    _formatDistance(r.totalDistance),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: selected ? Colors.white70 : Colors.grey.shade500,
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

  // ── Route summary card ─────────────────────────────────────────────────────

  Widget _buildRouteCard(
    PlanDriveViewModel vm,
    NavigationViewModel navVM,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: vm.isFetching
          ? const _FetchingIndicator()
          : vm.error != null
              ? _buildError(vm.error!)
              : _buildRouteDetails(vm, navVM),
    );
  }

  Widget _buildError(String message) {
    return Row(
      children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
        const SizedBox(width: 8),
        Text(
          message,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildRouteDetails(
    PlanDriveViewModel vm,
    NavigationViewModel navVM,
  ) {
    final route = vm.selectedRoute!;
    final durationMin = (route.estimatedDuration / 60).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Route label
        Text(
          route.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 10),

        // Stats row
        Row(
          children: [
            _StatChip(
              icon: Icons.route_rounded,
              label: _formatDistance(route.totalDistance),
            ),
            const SizedBox(width: 4),
            Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            _StatChip(
              icon: Icons.access_time_rounded,
              label: '$durationMin min',
            ),
            const SizedBox(width: 4),
            Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            _StatChip(
              icon: Icons.flag_rounded,
              label: 'Arrive ${_formatETA(route.estimatedDuration)}',
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Start AR Navigation button
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
            onPressed: () async {
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
        ),
      ],
    );
  }
}

// ── Private widgets ──────────────────────────────────────────────────────────

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? primaryColor.withValues(alpha: 0.10)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 14,
              color: active ? primaryColor : Colors.grey.shade500,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? primaryColor : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _FetchingIndicator extends StatelessWidget {
  const _FetchingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 10),
        Text(
          'Finding routes…',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ],
    );
  }
}
