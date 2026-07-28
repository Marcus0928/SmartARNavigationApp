import 'package:flutter/foundation.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:smart_ar_navigation/core/enums/turn_direction.dart';

/// Manages the ARCore session lifecycle via ar_flutter_plugin.
/// Arrow overlays are rendered as Flutter widget overlays in ARNavigationScreen;
/// placeArrow / updateArrow / clearOverlays notify the widget layer via state
/// held in ARViewModel rather than placing 3D ARCore nodes directly.
///
/// KNOWN THIRD-PARTY DEFECTS AND THE DELIBERATE TRADEOFF AROUND THEM:
///
/// 1. Surface reattachment (why ArView is destroyed and recreated on
///    genuine screen-off resume): live device testing confirmed the
///    ARCore session itself resumes cleanly at the native level after a
///    real pause/resume (Session::Resume/ResumeWithAnalytics both return
///    OK, no exceptions) — but the camera feed's rendering surface never
///    visibly reattaches to the new Android window after screen-off. This
///    is a defect inside ar_flutter_plugin_2/sceneview's surface-
///    reattachment logic, not fixable from Dart/app code, and the plugin
///    exposes no method to force a reattach. The only known-working
///    recovery is destroying and recreating the ArView (confirmed to
///    visually restore the camera, with a brief flash), so
///    ARNavigationScreenState.didChangeAppLifecycleState unmounts and
///    remounts ARView specifically on a genuine paused → resumed
///    transition (previousState == AppLifecycleState.paused). Transient
///    interruptions (e.g. the notification shade, which only ever
///    produces inactive → resumed) must NOT trigger this — that guard is
///    load-bearing, do not remove it.
///
/// 2. Zombie Lifecycle observers (the accepted cost of #1): ar_flutter_
///    plugin_2's native ArView wraps io.github.sceneview:arsceneview,
///    whose ARSceneView registers itself via `Lifecycle.addObserver(this)`
///    on the Activity's SHARED lifecycle at construction, but its
///    destroy() (confirmed via bytecode disassembly of arsceneview 2.2.1
///    — destroy() tears down the camera node/stream/light estimator/plane
///    renderer/ARCore session but never calls `Lifecycle.removeObserver`)
///    never unregisters it. Every ArView created this way leaves a
///    permanent "zombie" observer that keeps receiving onResume()/
///    onPause() for the rest of the app's life — concurrent zombies
///    contending for the camera/GL surface is what eventually causes a
///    green-flash / device freeze after enough accumulate. Recreating
///    only on genuine screen-off (not on every resume, as the original
///    pre-fix behavior did, and not never, which leaves the surface
///    broken per #1) is a deliberate, documented compromise: it is
///    meaningfully less frequent than recreating on every resume, but
///    still accumulates zombies over a long enough session. There is no
///    other known workaround short of forking the plugin's Kotlin.
///    _recreationCount below exists to make that accumulation visible.
class ARService {
  ARSessionManager? _sessionManager;
  ARObjectManager? _objectManager;
  bool _isInitialized = false;

  // Counts how many times a new native ArView has been created in this app
  // session (reroute-triggered re-init, faster-route preview toggle, etc.).
  // Each one leaves a permanent zombie Lifecycle observer (see class doc),
  // so this is a defensive telemetry signal, not a fix — if it climbs past
  // a handful in a single session, that's a sign some other code path is
  // still recreating the ArView more than it needs to.
  int _recreationCount = 0;
  int get recreationCount => _recreationCount;
  static const int _recreationWarnThreshold = 5;

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
