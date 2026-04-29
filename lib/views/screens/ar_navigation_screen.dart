import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/core/constants/app_strings.dart';
import 'package:smart_ar_navigation/core/enums/navigation_status.dart';
import 'package:smart_ar_navigation/viewmodels/ar_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/map_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/navigation_viewmodel.dart';
import 'package:smart_ar_navigation/views/widgets/ar_overlay_widget.dart';
import 'package:smart_ar_navigation/views/widgets/navigation_bottom_bar.dart';

class ARNavigationScreen extends StatefulWidget {
  const ARNavigationScreen({super.key});

  @override
  State<ARNavigationScreen> createState() => _ARNavigationScreenState();
}

class _ARNavigationScreenState extends State<ARNavigationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapViewModel>().startLocationTracking();
    });
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(arrivedMessage)),
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
          // Full-screen AR camera feed
          ARView(onARViewCreated: _onARViewCreated),

          // Top bar — destination + rerouting indicator
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                color: overlayBackground,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        navVM.currentDestination?.name ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (navVM.navigationStatus == NavigationStatus.rerouting)
                      const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: warningColor,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              reroutingMessage,
                              style: TextStyle(
                                color: warningColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // AR overlay — arrow + distance + street name
          const Positioned.fill(child: AROverlayWidget()),

          // Bottom bar — ETA + stop button
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
