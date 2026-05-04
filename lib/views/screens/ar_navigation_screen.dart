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
          // ── Full-screen AR camera feed ────────────────────────────
          ARView(onARViewCreated: _onARViewCreated),

          // ── Top HUD: turn instruction card only ──────────────────
          const SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Align(
                alignment: Alignment.topLeft,
                child: AROverlayWidget(),
              ),
            ),
          ),

          // ── Bottom navigation bar ─────────────────────────────────
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
