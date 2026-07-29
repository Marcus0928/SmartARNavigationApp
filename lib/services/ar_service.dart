import 'package:flutter/foundation.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:smart_ar_navigation/core/enums/turn_direction.dart';

/// Manages the ARCore session lifecycle via ar_flutter_plugin.
/// Arrow overlays are rendered as Flutter widget overlays in ARNavigationScreen,
/// with state held in ARViewModel rather than placing 3D ARCore nodes directly.
///
/// Known plugin defects:
/// 1. The camera surface never reattaches after screen-off, so ArView must
///    be destroyed and recreated on a genuine paused → resumed transition —
///    not on a transient inactive → resumed interruption like the
///    notification shade. That guard is load-bearing; do not remove it.
/// 2. Every recreated ArView leaks a permanent zombie Lifecycle observer
///    (the plugin's destroy() never unregisters it), so recreation is kept
///    to only the genuine screen-off case. _recreationCount below tracks
///    how many have accumulated.
class ARService {
  ARSessionManager? _sessionManager;
  ARObjectManager? _objectManager;
  bool _isInitialized = false;

  // Telemetry only, not a fix — see class doc. High counts in one session
  // mean some code path is recreating the ArView more than it needs to.
  int _recreationCount = 0;
  int get recreationCount => _recreationCount;
  static const int _recreationWarnThreshold = 5;

  bool get isInitialized => _isInitialized;

  Future<bool> initializeAR(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
  ) async {
    // Release the previous session first, else old camera/GL resources
    // pile up until ARCore crashes.
    if (_isInitialized) {
      await disposeAR();
      _recreationCount++;
      if (_recreationCount >= _recreationWarnThreshold) {
        debugPrint(
          'ARService: ArView recreated $_recreationCount times this '
          'session — each recreation leaks a permanent zombie Lifecycle '
          'observer (known ar_flutter_plugin_2/sceneview defect, see class '
          'doc). Consider restarting the app soon.',
        );
      }
    }

    _sessionManager = sessionManager;
    _objectManager = objectManager;

    await _sessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: false,
      customPlaneTexturePath: null,
      showWorldOrigin: false,
      showAnimatedGuide: false,
      handleTaps: false,
    );
    await _objectManager!.onInitialize();

    _isInitialized = true;
    return true;
  }

  // ignore: avoid_unused_parameters
  void placeArrow(TurnDirection direction, double distance) {
    // Arrow state is owned by ARViewModel; the ARNavigationScreen widget
    // rebuilds its overlay when ARViewModel notifies listeners.
  }

  // ignore: avoid_unused_parameters
  void updateArrow(TurnDirection direction, double distance) {
    // Same as placeArrow — no 3D node to mutate; ViewModel drives re-render.
  }

  void clearOverlays() {
    // No ARCore nodes to remove; resetting ViewModel state clears the UI.
  }

  Future<void> disposeAR() async {
    await _sessionManager?.dispose();
    _sessionManager = null;
    _objectManager = null;
    _isInitialized = false;
  }
}
