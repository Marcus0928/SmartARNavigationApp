import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:smart_ar_navigation/core/enums/turn_direction.dart';

/// Manages the ARCore session lifecycle via ar_flutter_plugin.
/// Arrow overlays are rendered as Flutter widget overlays in ARNavigationScreen;
/// placeArrow / updateArrow / clearOverlays notify the widget layer via state
/// held in ARViewModel rather than placing 3D ARCore nodes directly.
class ARService {
  ARSessionManager? _sessionManager;
  ARObjectManager? _objectManager;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<bool> initializeAR(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
  ) async {
    // Release the previous native ARCore session before replacing it —
    // otherwise the old session's camera/GL resources are never freed and
    // repeated re-initialization (e.g. leaving and returning to the AR
    // screen) accumulates sessions until ARCore crashes. Awaited so the old
    // session's native teardown is confirmed complete before the new one
    // starts pumping frames.
    if (_isInitialized) {
      await disposeAR();
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
