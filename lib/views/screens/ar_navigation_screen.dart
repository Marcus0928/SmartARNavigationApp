import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_ar_navigation/core/constants/app_strings.dart';
import 'package:smart_ar_navigation/core/enums/navigation_status.dart';
import 'package:smart_ar_navigation/viewmodels/ar_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/navigation_viewmodel.dart';
import 'package:smart_ar_navigation/views/widgets/ar_overlay_widget.dart';
import 'package:smart_ar_navigation/views/widgets/dynamic_arrow_widget.dart';
import 'package:smart_ar_navigation/views/widgets/navigation_bottom_bar.dart';

class ARNavigationScreen extends StatefulWidget {
  const ARNavigationScreen({super.key});

  @override
  State<ARNavigationScreen> createState() => _ARNavigationScreenState();
}

class _ARNavigationScreenState extends State<ARNavigationScreen> {
  bool _arrivalHandled = false;

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

    return Scaffold(
      body: Stack(
        children: [
          // ── Layer 1: Full-screen AR camera feed ───────────────────
          ARView(onARViewCreated: _onARViewCreated),

          // ── Layer 2: Chevron arrows centred at 45% screen height ──
          const Positioned.fill(child: _CenteredArrowOverlay()),

          // ── Layer 3: Slim top info bar — distance + street name ───
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: AROverlayWidget(),
            ),
          ),

          // ── Layer 4: Bottom navigation bar ───────────────────────
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

// ── Centred chevron overlay ───────────────────────────────────────────────────

class _CenteredArrowOverlay extends StatelessWidget {
  const _CenteredArrowOverlay();

  @override
  Widget build(BuildContext context) {
    final arVM = context.watch<ARViewModel>();
    if (arVM.nextTurnDirection == null) return const SizedBox.shrink();

    // Alignment(0, 0.2) places the widget centre at 60% of screen height:
    //   centre_y = screenH/2 + (0.2 * screenH/2) = screenH * 0.60
    return Align(
      alignment: const Alignment(0.0, 0.2),
      child: DynamicArrowWidget(
        direction: arVM.nextTurnDirection!,
        distance: arVM.distanceToNextTurn ?? double.infinity,
        size: 180,
        showLabel: false,
      ),
    );
  }
}
