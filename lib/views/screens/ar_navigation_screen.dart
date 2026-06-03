import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:smart_ar_navigation/core/constants/app_strings.dart';
import 'package:smart_ar_navigation/core/enums/navigation_approach_stage.dart';
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
  State<ARNavigationScreen> createState() => _ARNavigationScreenState();
}

class _ARNavigationScreenState extends State<ARNavigationScreen>
    with WidgetsBindingObserver {
  bool _arrivalHandled = false;

  // TODO: remove — debug only
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
    if (state == AppLifecycleState.resumed) {
      final loc = context.read<MapViewModel>().currentLocation;
      if (loc != null) {
        context.read<ARViewModel>().updateAROverlay(loc);
      }
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(arrivedMessage),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final navVM = context.watch<NavigationViewModel>();

    if (navVM.navigationStatus == NavigationStatus.arrived) {
      _handleArrival(context);
    }

    final arVM = context.watch<ARViewModel>();

    return Scaffold(
      body: Stack(
        children: [
          // ── Layer 1: Full-screen AR camera feed ───────────────────
          ARView(onARViewCreated: _onARViewCreated),

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

          // ── Layer 3: Floating info card ───────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _NavInfoCard(directionOverride: _debugDirection),
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
        ],
      ),
    );
  }
}

// ── Floating top info card ────────────────────────────────────────────────────

class _NavInfoCard extends StatelessWidget {
  const _NavInfoCard({this.directionOverride});

  final TurnDirection? directionOverride;

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
                approachStage: arVM.approachStage,
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

