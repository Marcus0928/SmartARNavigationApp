import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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
                if (navVM.suggestedFasterRoute != null)
                  _FasterRouteBanner(
                    savedSeconds: ((navVM.currentRoute?.estimatedDuration ?? 0) -
                        navVM.suggestedFasterRoute!.estimatedDuration).toDouble(),
                    onSwitch: () => navVM.acceptFasterRoute(),
                    onDismiss: navVM.dismissFasterRoute,
                  ),
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

// ── Faster route banner ───────────────────────────────────────────────────────

class _FasterRouteBanner extends StatelessWidget {
  const _FasterRouteBanner({
    required this.savedSeconds,
    required this.onSwitch,
    required this.onDismiss,
  });

  final double savedSeconds;
  final VoidCallback onSwitch;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final savedMin = (savedSeconds / 60).round();
    return Container(
      width: double.infinity,
      color: const Color(0xDD1A1A2E),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Faster route available — Save $savedMin min',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: onSwitch,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF00E676),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text('Switch', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: onDismiss,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            child: const Text('Dismiss'),
          ),
        ],
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

