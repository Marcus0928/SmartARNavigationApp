import 'package:flutter/foundation.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:smart_ar_navigation/core/enums/navigation_approach_stage.dart';
import 'package:smart_ar_navigation/core/enums/turn_direction.dart';
import 'package:smart_ar_navigation/core/utils/instruction_builder.dart';
import 'package:smart_ar_navigation/core/utils/location_utils.dart';
import 'package:smart_ar_navigation/models/route_model.dart';
import 'package:smart_ar_navigation/models/turn_instruction.dart';
import 'package:smart_ar_navigation/services/ar_service.dart';
import 'package:smart_ar_navigation/services/voice_service.dart';

enum VoiceAnnouncement {
  none,
  farLive,
  midLive,
  checkpoint1km,
  checkpoint500m,
  yellow,
  red
}

class ARViewModel extends ChangeNotifier {
  final ARService _arService;
  final VoiceService _voiceService;

  ARViewModel({required ARService arService, VoiceService? voiceService})
      : _arService = arService,
        _voiceService = voiceService ?? VoiceService() {
    // Fire-and-forget: ARViewModel is constructed once at app startup, well
    // before a navigation session can start and any speak() call could fire.
    _voiceService.initialize();
  }

  TurnDirection? _nextTurnDirection;
  double? _distanceToNextTurn;
  String _instructionText = 'Continue';
  String? _currentStreetName;
  int? _roundaboutExit;
  bool _isARInitialized = false;
  List<TurnInstruction> _remainingTurns = [];
  double? _lastDistanceToNextTurn;
  TurnInstruction? _lastHeadTurn;
  bool _lookaheadActive = false;
  double? _closestApproachToHead;
  int _missedTurnStreak = 0;
  DateTime? _lastMissedTurnPopTime;
  int _movingAwayStreak = 0;
  DateTime? _lastMovingAwayPopTime;
  LatLng? _destinationCoordinates;
  VoiceAnnouncement _lastAnnounced = VoiceAnnouncement.none;
  double? _lastAnnouncedAtDistance;
  double? _previousDistanceToNextTurn;
  TurnDirection? _upcomingTurnDirection;
  String? _upcomingTurnStreet;
  bool voiceGuidanceEnabled = true;

  // Bug 34: whether the CURRENT head turn's displayed distance has already
  // reached _distanceFloorMetres at least once. Reset whenever a new turn
  // becomes the head (same place _lookaheadActive/_closestApproachToHead
  // are reset) and in resetOverlay().
  bool _headTurnReachedFloor = false;

  // Final-leg heads-up ("In X, you will reach your destination") and the
  // arrival announcement each fire at most once per route — separate from
  // the 6-tier turn system's _lastAnnounced, since neither concept maps to
  // a turn tier ("red = imminent turn" doesn't apply to "you've arrived").
  bool _finalLegAnnounced = false;
  bool _arrivalAnnounced = false;

  // Bug 32: proximity to a turn's junction coordinate alone doesn't mean the
  // turn was actually completed — a driver stopped waiting there (roundabout
  // gap, red light) sits within the pop radius the whole time. The proximity
  // pop loop in updateAROverlay() also requires current heading to roughly
  // match the outgoing segment's bearing, within this tolerance, before
  // treating the turn as done.
  static const double _headingConfirmationToleranceDegrees = 55.0;

  // Bug 33: GPS-derived heading is temporarily unreliable right after a turn
  // (course-over-ground lags the actual turn and gets noisier at the lower
  // speed typical mid-turn), so the heading gate above can take several
  // seconds to be satisfied even though the turn is genuinely done — the
  // stale turn stays displayed with its distance visibly counting up as the
  // driver drives away from it. Rather than loosen the heading tolerance
  // (which would blunt Bug 32's protection specifically for ~90° turns,
  // where the approach and outgoing bearings are already that far apart),
  // the proximity pop loop also accepts a second, independent condition:
  // the driver is clearly moving (speed above this floor — well above GPS
  // noise/idling drift, but low enough to still count a driver just pulling
  // away from the turn) AND has moved away from the closest approach this
  // turn ever recorded by at least this margin. A stopped/waiting driver
  // (Bug 32's original case) has speed ~0 and never satisfies this, so
  // still relies purely on the heading gate.
  static const double _movingAwaySpeedThresholdMetresPerSecond = 2.0;
  static const double _movingAwayFallbackMarginMetres = 15.0;

  // Bug 37: unlike the missed-turn heuristic below (which already requires
  // sustained confirmation, a cooldown, and a plausibility check — see the
  // Bug 36 constants), the moving-away fallback above used to pop on a
  // SINGLE tick's speed+distance reading alone. A single transient bad GPS
  // fix (speed/position noise right after a reroute, near a tunnel/
  // overpass, or general signal noise) could satisfy it long enough to pop
  // a turn the driver hadn't actually completed, and — since it only ever
  // evaluates _remainingTurns.first — do so again on the very next
  // (still-noisy) tick, cascading through several real, un-passed turns.
  // Mirrors the same three-part gate as the missed-turn heuristic, kept as
  // independent constants (not shared with _missedTurn*) so this fallback
  // stays separately tunable and this fix stays scoped to it alone:
  //  - require the raw condition to hold for several consecutive ticks
  //  - cool down between pops
  //  - reject the pop outright if the resulting new head turn would be
  //    implausibly far from the driver
  // Core 80 m/200 m-equivalent trigger values above (speed threshold,
  // fallback margin) are unchanged — this only gates when the already-true
  // condition is acted on.
  static const int _movingAwayConfirmationTicks = 3;
  static const Duration _movingAwayPopCooldown = Duration(seconds: 3);
  static const double _movingAwayPlausibilityMetres = 10000.0;

  // Bug 34 (display-only): once a turn's distance has been driven down to
  // ~0, straight-line distance to that same (now-passed) point necessarily
  // starts climbing again as the driver continues past it — even though
  // the turn is genuinely done, this reads as broken on screen during the
  // brief window where the pop loop above is still waiting to confirm it
  // (heading gate or the Bug 33 moving-away fallback). Once
  // distanceToNextTurn for the current head turn reaches this floor, it's
  // held at 0 for the rest of that turn's display window instead of
  // tracking the growing straight-line distance. Purely a display clamp —
  // the pop condition logic above is untouched, and this doesn't affect
  // when the turn actually pops.
  static const double _distanceFloorMetres = 5.0;

  // Bug 36 regression fix: the missed-turn heuristic below used to act on a
  // single tick where the driver appeared to have moved away from the head
  // turn. A transient bad GPS fix (settling right after a reroute, near a
  // tunnel/overpass, or plain signal noise) could satisfy that condition
  // for several turns in a row across consecutive updateAROverlay() ticks —
  // each tick only ever looks at _remainingTurns.first, so nothing stopped
  // it cascading through multiple real, un-passed turns. These three
  // constants gate the pop with more confidence instead of changing the
  // underlying 80 m/200 m trigger distances:
  //  - require the moved-away condition to hold for several consecutive
  //    ticks (filters a one-off jump, still catches a genuine departure)
  //  - cool down between pops (stops back-to-back cascades even if the
  //    sustained condition is somehow re-satisfied immediately)
  //  - reject the pop outright if the resulting new head turn would be
  //    implausibly far from the driver (a sign multiple turns are being
  //    skipped over at once, not that one was genuinely missed)
  static const int _missedTurnConfirmationTicks = 3;
  static const Duration _missedTurnPopCooldown = Duration(seconds: 3);
  static const double _missedTurnPlausibilityMetres = 10000.0;

  // Bug 37: a reroute (recalculateRoute/acceptFasterRoute) can be triggered
  // from a bad sideways/forward GPS jump (e.g. onto a parallel service
  // road) rather than a genuine deviation. Google still returns a valid,
  // non-error route from that bad origin — often a legitimately shorter,
  // fewer-turn one, since it's computed from a point that isn't actually
  // where the driver is. Mirrors the shape of _missedTurnPlausibilityMetres:
  // a flat sanity margin on a distance value, not a full kinematic model.
  // A genuine reroute (the driver really did take a shorter path, or Google
  // found a better one) should never shave more than this much off the
  // previously known remaining route distance in one go.
  static const double _rerouteRemainingDistancePlausibilityMarginMetres =
      3000.0;

  // TEMPORARY - remove after voice guidance testing is complete
  bool _debugOverrideActive = false;
  // TEMPORARY - remove after voice guidance testing is complete
  bool get debugOverrideActive => _debugOverrideActive;

  TurnDirection? get nextTurnDirection => _nextTurnDirection;
  double? get distanceToNextTurn => _distanceToNextTurn;
  String get instructionText => _instructionText;
  String? get currentStreetName => _currentStreetName;
  int? get roundaboutExit => _roundaboutExit;
  bool get isARInitialized => _isARInitialized;

  NavigationApproachStage get approachStage {
    final d = _distanceToNextTurn;
    if (d == null || d > 200) return NavigationApproachStage.far;
    if (d > 50) return NavigationApproachStage.approaching;
    return NavigationApproachStage.imminent;
  }

  Future<void> initializeAR(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
  ) async {
    _isARInitialized =
        await _arService.initializeAR(sessionManager, objectManager);
    notifyListeners();
  }

  Future<void> initializeOverlay(RouteModel route, {double? heading}) async {
    final newTurns = List<TurnInstruction>.from(route.turns);

    // Discard a phantom U-turn at step 1: Google may produce one when the
    // origin snaps to the wrong road side because no heading was available.
    // If we do have heading (driver is moving) and a subsequent step exists,
    // the U-turn is almost certainly spurious.
    if (newTurns.length > 1 &&
        newTurns.first.direction == TurnDirection.uTurn &&
        heading != null) {
      newTurns.removeAt(0);
    }

    // Rerouting (recalculateRoute/acceptFasterRoute) always hands us brand-new
    // TurnInstruction objects, even when the upcoming real-world turn hasn't
    // actually changed. If the new head turn matches the previous one by
    // direction and position, carry _lastHeadTurn forward so the next
    // updateAROverlay() tick doesn't see a reference mismatch, reset
    // _lastAnnounced, and re-speak the announcement mid-utterance.
    if (newTurns.isNotEmpty && _lastHeadTurn != null) {
      final newHead = newTurns.first;
      final sameTurn = newHead.direction == _lastHeadTurn!.direction &&
          calculateDistance(newHead.position, _lastHeadTurn!.position) <= 20.0;
      if (sameTurn) {
        _lastHeadTurn = newHead;
      }
    }

    // Bug 37: reroute plausibility check — a reroute triggered by a bad
    // sideways/forward GPS jump can hand back a route that is implausibly
    // shorter than what was already known to remain, with nothing else
    // (no error, no backward-looking candidate) to signal it's wrong. If
    // adopting it would drop the remaining route distance by more than the
    // margin below, reject it and keep the existing route/turns untouched
    // — a later call (from fresh, hopefully-correct GPS) gets another
    // chance to reroute.
    if (_remainingTurns.isNotEmpty) {
      final oldRemainingDistance = _remainingTurns.fold<double>(
        0.0,
        (sum, t) => sum + t.distanceFromPrev,
      );
      final newRemainingDistance = newTurns.fold<double>(
        0.0,
        (sum, t) => sum + t.distanceFromPrev,
      );
      if (oldRemainingDistance - newRemainingDistance >
          _rerouteRemainingDistancePlausibilityMarginMetres) {
        debugPrint(
          'ARViewModel.initializeOverlay: rejected new route — remaining '
          'distance dropped from ${oldRemainingDistance.round()}m to '
          '${newRemainingDistance.round()}m, more than the '
          '${_rerouteRemainingDistancePlausibilityMarginMetres.round()}m '
          'plausibility margin allows; keeping the existing route.',
        );
        return;
      }
    }

    _remainingTurns = newTurns;

    if (_remainingTurns.isNotEmpty) {
      final first = _remainingTurns.first;
      _nextTurnDirection = first.direction;
      _distanceToNextTurn = first.distanceFromPrev;
      _instructionText = InstructionBuilder.buildInstruction(
        first.maneuver,
        first.exitNumber,
      );
      _currentStreetName = first.streetName;
      _roundaboutExit = first.exitNumber;
      _arService.placeArrow(first.direction, first.distanceFromPrev);
    }
    notifyListeners();
  }

  void updateAROverlay(LatLng currentLocation, {double? heading, double? speed}) {
    // TEMPORARY - remove after voice guidance testing is complete
    if (_debugOverrideActive) return;

    if (_remainingTurns.isEmpty) {
      _nextTurnDirection = TurnDirection.forward;
      _distanceToNextTurn = _destinationCoordinates != null
          ? calculateDistance(currentLocation, _destinationCoordinates!)
          : 0;
      _instructionText = 'Continue';
      _currentStreetName = null;
      _roundaboutExit = null;
      _checkFinalLegAnnouncement(_distanceToNextTurn!);
      notifyListeners();
      return;
    }

    // Drop turns one-at-a-time from the head only — bulk removeWhere would skip
    // multiple turns simultaneously when consecutive positions are close together.
    // U-turns get a wider threshold (20 m) because wide arcs may never bring the
    // driver within 10 m of the theoretical turn start point.
    //
    // Proximity alone doesn't confirm the turn was actually completed (Bug
    // 32): a driver stopped waiting right at the junction — a gap in
    // roundabout traffic, a red light before turning — sits within this
    // radius the whole time without having turned. Current heading must also
    // roughly match the outgoing segment's bearing (turn -> next turn, or
    // turn -> destination on the final turn) rather than the approach
    // direction. When heading is null (GPS course-over-ground is stale/
    // unavailable, which is exactly what happens while genuinely stationary)
    // or there's no outgoing point to bear toward, the turn is correctly
    // left unpopped — that's the "still waiting" case, not a bug.
    //
    // Bug 33 fallback: heading can lag for several seconds right after a
    // genuinely-completed turn (see _movingAwaySpeedThresholdMetresPerSecond
    // doc above), so the loop also pops when the driver is clearly moving
    // and has pulled away from this turn's closest recorded approach by
    // _movingAwayFallbackMarginMetres — regardless of current heading.
    // _closestApproachToHead is the same tracker mechanism B (the missed-
    // turn heuristic below) uses; it's only populated once the driver has
    // actually gotten close to this head turn, so this fallback can't fire
    // before proximity was genuinely reached. Speed near zero (stopped/
    // waiting, Bug 32's original case) never satisfies this, leaving that
    // case to rely purely on the heading gate, unchanged.
    while (_remainingTurns.isNotEmpty) {
      final head = _remainingTurns.first;
      final threshold =
          (head.direction == TurnDirection.uTurn ||
           head.direction == TurnDirection.roundabout)
              ? 20.0
              : 10.0;
      final distanceToHead = calculateDistance(currentLocation, head.position);
      final withinRadius = distanceToHead < threshold;

      final outgoingTarget = _remainingTurns.length > 1
          ? _remainingTurns[1].position
          : _destinationCoordinates;
      final turnConfirmedByHeading = heading != null &&
          outgoingTarget != null &&
          angularDifference(
                heading,
                calculateBearing(head.position, outgoingTarget),
              ) <=
              _headingConfirmationToleranceDegrees;

      final turnConfirmedByMovingAwayRaw = speed != null &&
          speed > _movingAwaySpeedThresholdMetresPerSecond &&
          _closestApproachToHead != null &&
          _closestApproachToHead! < threshold &&
          distanceToHead >
              _closestApproachToHead! + _movingAwayFallbackMarginMetres;

      if (withinRadius && turnConfirmedByHeading) {
        _remainingTurns.removeAt(0);
        _lastDistanceToNextTurn = null;
        _closestApproachToHead = null;
        _movingAwayStreak = 0;
      } else if (turnConfirmedByMovingAwayRaw) {
        // Bug 37: gate the raw single-tick reading behind sustained
        // confirmation, a cooldown, and a plausibility check — see the
        // constants above — instead of acting on it immediately.
        _movingAwayStreak++;

        final now = DateTime.now();
        final cooldownElapsed = _lastMovingAwayPopTime == null ||
            now.difference(_lastMovingAwayPopTime!) >= _movingAwayPopCooldown;

        var popped = false;
        if (_movingAwayStreak >= _movingAwayConfirmationTicks &&
            cooldownElapsed) {
          final newHeadPosition = _remainingTurns.length > 1
              ? _remainingTurns[1].position
              : _destinationCoordinates;
          final distanceToNewHead = newHeadPosition != null
              ? calculateDistance(currentLocation, newHeadPosition)
              : null;
          final plausible = distanceToNewHead == null ||
              distanceToNewHead <= _movingAwayPlausibilityMetres;

          if (plausible) {
            _remainingTurns.removeAt(0);
            _lastDistanceToNextTurn = null;
            _closestApproachToHead = null;
            _movingAwayStreak = 0;
            _lastMovingAwayPopTime = now;
            popped = true;
          } else {
            debugPrint(
              'ARViewModel: moving-away pop rejected — new head would be '
              '${distanceToNewHead.round()}m away, likely GPS noise rather '
              'than a genuinely completed turn.',
            );
          }
        }
        if (!popped) break;
      } else {
        _movingAwayStreak = 0;
        break;
      }
    }

    // Missed turn detection: if the user got close to a turn but is now
    // moving away, consider it missed and pop it. See the Bug 36 constants
    // above for why the pop itself is gated behind sustained confirmation,
    // a cooldown, and a plausibility check rather than firing on one tick.
    if (_remainingTurns.isNotEmpty) {
      final head = _remainingTurns.first;
      final distToHead = calculateDistance(currentLocation, head.position);

      final movedAway = _closestApproachToHead != null &&
          distToHead > _closestApproachToHead! + 80.0 &&
          _closestApproachToHead! < 200.0;

      if (movedAway) {
        _missedTurnStreak++;

        final now = DateTime.now();
        final cooldownElapsed = _lastMissedTurnPopTime == null ||
            now.difference(_lastMissedTurnPopTime!) >= _missedTurnPopCooldown;

        if (_missedTurnStreak >= _missedTurnConfirmationTicks &&
            cooldownElapsed) {
          final newHeadPosition = _remainingTurns.length > 1
              ? _remainingTurns[1].position
              : _destinationCoordinates;
          final distanceToNewHead = newHeadPosition != null
              ? calculateDistance(currentLocation, newHeadPosition)
              : null;
          final plausible = distanceToNewHead == null ||
              distanceToNewHead <= _missedTurnPlausibilityMetres;

          if (plausible) {
            _remainingTurns.removeAt(0);
            _closestApproachToHead = null;
            _lastDistanceToNextTurn = null;
            _missedTurnStreak = 0;
            _lastMissedTurnPopTime = now;
          } else {
            debugPrint(
              'ARViewModel: missed-turn pop rejected — new head would be '
              '${distanceToNewHead.round()}m away, likely GPS noise rather '
              'than a genuinely missed turn.',
            );
          }
        }
      } else {
        _missedTurnStreak = 0;
        if (_closestApproachToHead == null ||
            distToHead < _closestApproachToHead!) {
          _closestApproachToHead = distToHead;
        }
      }
    }

    if (_remainingTurns.isEmpty) {
      _nextTurnDirection = TurnDirection.forward;
      _distanceToNextTurn = _destinationCoordinates != null
          ? calculateDistance(currentLocation, _destinationCoordinates!)
          : 0;
      _instructionText = 'Continue';
      _currentStreetName = null;
      _roundaboutExit = null;
      _checkFinalLegAnnouncement(_distanceToNextTurn!);
      notifyListeners();
      return;
    }

    // Pop stale forward step if user has moved past its start position (GPS missed 10m window).
    if (_remainingTurns.isNotEmpty) {
      final head = _remainingTurns.first;
      if (head.direction == TurnDirection.forward) {
        final distToHead = calculateDistance(currentLocation, head.position);
        if (distToHead > 50.0 && _remainingTurns.length > 1) {
          final nextDist = calculateDistance(
            currentLocation,
            _remainingTurns[1].position,
          );
          if (nextDist < distToHead) {
            _remainingTurns.removeAt(0);
          }
        }
      }
    }

    // Reset the distance clamp whenever the head turn changes — covers both the
    // prune loop above and the stale-forward-step removal (which doesn't reset it).
    final currentHead = _remainingTurns.first;
    if (currentHead != _lastHeadTurn) {
      _lastDistanceToNextTurn = null;
      _lookaheadActive = false;
      _closestApproachToHead = null;
      _lastAnnounced = VoiceAnnouncement.none;
      _headTurnReachedFloor = false;
      _missedTurnStreak = 0;
      _movingAwayStreak = 0;
    }
    _lastHeadTurn = currentHead;

    final currentStep = _remainingTurns[0];
    final distanceToCurrentStep =
        calculateDistance(currentLocation, currentStep.position);

    if (currentStep.direction != TurnDirection.forward) {
      // Unified distance gate for ALL non-forward turns (replaces the
      // roundabout-only check). Engage at 1000 m, disengage at 1100 m.
      if (!_lookaheadActive && distanceToCurrentStep > 1000.0) {
        _nextTurnDirection = TurnDirection.forward;
        _distanceToNextTurn = distanceToCurrentStep;
        _roundaboutExit = null;
        _instructionText = 'Continue';
        _currentStreetName = currentStep.streetName;
        _upcomingTurnDirection = currentStep.direction;
        _upcomingTurnStreet = currentStep.streetName;
        _arService.updateArrow(TurnDirection.forward, distanceToCurrentStep);
        _checkVoiceAnnouncement();
        notifyListeners();
        return;
      }

      if (_lookaheadActive && distanceToCurrentStep > 1100.0) {
        _lookaheadActive = false;
        _nextTurnDirection = TurnDirection.forward;
        _distanceToNextTurn = distanceToCurrentStep;
        _roundaboutExit = null;
        _instructionText = 'Continue';
        _currentStreetName = currentStep.streetName;
        _upcomingTurnDirection = currentStep.direction;
        _upcomingTurnStreet = currentStep.streetName;
        _arService.updateArrow(TurnDirection.forward, distanceToCurrentStep);
        _checkVoiceAnnouncement();
        notifyListeners();
        return;
      }

      // Within lookahead range — show the turn directly.
      _lookaheadActive = true;
      double newDistance;
      if (_headTurnReachedFloor) {
        // Bug 34: this turn already reached the floor once — hold at 0
        // rather than tracking the growing straight-line distance while
        // still waiting for the pop condition to confirm the turn is done.
        newDistance = 0.0;
      } else {
        newDistance = distanceToCurrentStep;
        if (_lastDistanceToNextTurn != null &&
            newDistance < 500.0 &&
            newDistance > _lastDistanceToNextTurn! + 20.0 &&
            _closestApproachToHead != null &&
            newDistance <= _closestApproachToHead! + 30.0) {
          newDistance = _lastDistanceToNextTurn!;
        }
        if (newDistance <= _distanceFloorMetres) {
          _headTurnReachedFloor = true;
          newDistance = 0.0;
        }
      }
      _lastDistanceToNextTurn = newDistance;
      _distanceToNextTurn = newDistance;
      _nextTurnDirection = currentStep.direction;
      _instructionText = InstructionBuilder.buildInstruction(
        currentStep.maneuver,
        currentStep.exitNumber,
      );
      _currentStreetName = currentStep.streetName;
      _roundaboutExit = currentStep.exitNumber;
      _upcomingTurnDirection = currentStep.direction;
      _upcomingTurnStreet = currentStep.streetName;
      _arService.updateArrow(currentStep.direction, distanceToCurrentStep);
    } else {
      // Current step is forward — scan ahead for the first non-forward turn within 1 km.
      final upcomingTurn = _remainingTurns.firstWhere(
        (t) => t.direction != TurnDirection.forward,
        orElse: () => currentStep,
      );
      final distanceToUpcoming =
          calculateDistance(currentLocation, upcomingTurn.position);

      double newDistance = distanceToUpcoming;
      if (_lastDistanceToNextTurn != null &&
          newDistance < 500.0 &&
          newDistance > _lastDistanceToNextTurn! + 20.0 &&
          _closestApproachToHead != null &&
          newDistance <= _closestApproachToHead! + 30.0) {
        newDistance = _lastDistanceToNextTurn!;
      }
      _lastDistanceToNextTurn = newDistance;
      _distanceToNextTurn = newDistance;

      final double lookaheadThreshold =
          _lookaheadActive ? 1100.0 : 1000.0;

      if (distanceToUpcoming <= lookaheadThreshold &&
          upcomingTurn.direction != TurnDirection.forward) {
        _lookaheadActive = true;
        _nextTurnDirection = upcomingTurn.direction;
        _instructionText = InstructionBuilder.buildInstruction(
          upcomingTurn.maneuver,
          upcomingTurn.exitNumber,
        );
        _currentStreetName = upcomingTurn.streetName;
        _roundaboutExit = upcomingTurn.exitNumber;
        _upcomingTurnDirection = upcomingTurn.direction;
        _upcomingTurnStreet = upcomingTurn.streetName;
        _arService.updateArrow(upcomingTurn.direction, distanceToUpcoming);
      } else {
        _lookaheadActive = false;
        _nextTurnDirection = currentStep.direction;
        _instructionText = InstructionBuilder.buildInstruction(
          currentStep.maneuver,
          currentStep.exitNumber,
        );
        _currentStreetName = currentStep.streetName;
        _roundaboutExit = currentStep.exitNumber;
        _upcomingTurnDirection = upcomingTurn.direction;
        _upcomingTurnStreet = upcomingTurn.streetName;
        _arService.updateArrow(currentStep.direction, distanceToUpcoming);
        if (upcomingTurn == currentStep && _remainingTurns.isNotEmpty) {
          final targetPoint =
              _destinationCoordinates ?? _remainingTurns.last.position;
          _distanceToNextTurn =
              calculateDistance(currentLocation, targetPoint);
        }
      }
    }

    _checkVoiceAnnouncement();
    notifyListeners();
  }

  void resetOverlay() {
    _nextTurnDirection = null;
    _distanceToNextTurn = null;
    _instructionText = 'Continue';
    _currentStreetName = null;
    _roundaboutExit = null;
    _remainingTurns = [];
    _lastDistanceToNextTurn = null;
    _lastHeadTurn = null;
    _lookaheadActive = false;
    _closestApproachToHead = null;
    _missedTurnStreak = 0;
    _lastMissedTurnPopTime = null;
    _movingAwayStreak = 0;
    _lastMovingAwayPopTime = null;
    _headTurnReachedFloor = false;
    _destinationCoordinates = null;
    _lastAnnounced = VoiceAnnouncement.none;
    _finalLegAnnounced = false;
    _arrivalAnnounced = false;
    _arService.clearOverlays();
    _voiceService.stop();
    notifyListeners();
  }

  void setDestination(LatLng? destination) {
    _destinationCoordinates = destination;
  }

  // Toggles the voice guidance mute button on the AR screen. Stops any
  // in-progress speech immediately when muting, rather than letting the
  // current announcement finish.
  void toggleVoiceGuidance() {
    voiceGuidanceEnabled = !voiceGuidanceEnabled;
    if (!voiceGuidanceEnabled) {
      _voiceService.stop();
    }
    notifyListeners();
  }

  // ── Static testing hooks (debug buttons) — no GPS/route required ──────────

  // Lets the debug direction buttons drive the real direction/exit state
  // (instead of a widget-local override) so testVoiceAnnouncement() below
  // speaks the same direction the arrow is currently showing.
  void testSetDirection(TurnDirection? direction, {int? exitNumber}) {
    // TEMPORARY - remove after voice guidance testing is complete
    _debugOverrideActive = true;
    _nextTurnDirection = direction;
    _roundaboutExit = exitNumber;
    // TEMPORARY - remove after voice guidance testing is complete
    // Debug buttons only drive nextTurnDirection above, but farLive/midLive
    // read from _upcomingTurnDirection/_upcomingTurnStreet (only populated by
    // the real GPS logic in updateAROverlay(), which never runs in test
    // mode) — mirror the test direction/street here so those tiers speak
    // the button that was actually pressed instead of a stale value.
    _upcomingTurnDirection = direction;
    _upcomingTurnStreet = 'Jalan Universiti';
    notifyListeners();
  }

  // Forces distanceToNextTurn to a representative test value, clears the
  // announcement dedup so the press is treated as a fresh turn, then runs
  // the real announcement check — same path GPS updates use.
  void testVoiceAnnouncement(double distance) {
    // TEMPORARY - remove after voice guidance testing is complete
    _debugOverrideActive = true;
    _distanceToNextTurn = distance;
    _lastAnnounced = VoiceAnnouncement.none;
    _checkVoiceAnnouncement();
    notifyListeners();
  }

  // TEMPORARY - remove after voice guidance testing is complete
  // "Exit Test Mode" — resumes real GPS-driven overlay updates immediately.
  void exitTestMode() {
    _debugOverrideActive = false;
    notifyListeners();
  }

  // Closest zone first — defends against GPS jumps that could otherwise
  // skip straight past an intermediate zone without announcing it.
  void _checkVoiceAnnouncement() {
    if (!voiceGuidanceEnabled) return;

    final d = _distanceToNextTurn;
    if (d == null) return;

    if (_lastAnnounced == VoiceAnnouncement.none) {
      // IMMEDIATE-FIRE — this turn just became active
      if (d < 50) {
        _voiceService.speak(_buildVoiceInstruction(
          VoiceAnnouncement.red,
          direction: _nextTurnDirection ?? TurnDirection.forward,
          street: _currentStreetName,
          distanceMetres: d,
          roundaboutExit: _roundaboutExit,
        ));
        _lastAnnounced = VoiceAnnouncement.red;
      } else if (d >= 50 && d <= 200) {
        _voiceService.speak(_buildVoiceInstruction(
          VoiceAnnouncement.yellow,
          direction: _nextTurnDirection ?? TurnDirection.forward,
          street: _currentStreetName,
          distanceMetres: d,
          roundaboutExit: _roundaboutExit,
        ));
        _lastAnnounced = VoiceAnnouncement.yellow;
      } else if (d > 200 && d <= 1000) {
        _voiceService.speak(_buildVoiceInstruction(
          VoiceAnnouncement.midLive,
          direction: _upcomingTurnDirection ?? TurnDirection.forward,
          street: _upcomingTurnStreet,
          distanceMetres: d,
          roundaboutExit: _roundaboutExit,
        ));
        _lastAnnounced = VoiceAnnouncement.midLive;
      } else if (d > 1000) {
        _voiceService.speak(_buildVoiceInstruction(
          VoiceAnnouncement.farLive,
          direction: _upcomingTurnDirection ?? TurnDirection.forward,
          street: _upcomingTurnStreet,
          distanceMetres: d,
          roundaboutExit: _roundaboutExit,
        ));
        _lastAnnounced = VoiceAnnouncement.farLive;
      }
      _lastAnnouncedAtDistance = d;
      _previousDistanceToNextTurn = d;
      return;
    }

    final prev = _previousDistanceToNextTurn;

    if (d < 50 && _lastAnnounced != VoiceAnnouncement.red) {
      _voiceService.speak(_buildVoiceInstruction(
        VoiceAnnouncement.red,
        direction: _nextTurnDirection ?? TurnDirection.forward,
        street: _currentStreetName,
        distanceMetres: d,
        roundaboutExit: _roundaboutExit,
      ));
      _lastAnnounced = VoiceAnnouncement.red;
    } else if (d >= 50 &&
        d <= 200 &&
        _lastAnnounced != VoiceAnnouncement.yellow &&
        _lastAnnounced != VoiceAnnouncement.red) {
      _voiceService.speak(_buildVoiceInstruction(
        VoiceAnnouncement.yellow,
        direction: _nextTurnDirection ?? TurnDirection.forward,
        street: _currentStreetName,
        distanceMetres: d,
        roundaboutExit: _roundaboutExit,
      ));
      _lastAnnounced = VoiceAnnouncement.yellow;
    } else if (prev != null &&
        prev >= 500 &&
        d < 500 &&
        _lastAnnounced != VoiceAnnouncement.checkpoint500m &&
        _lastAnnounced != VoiceAnnouncement.yellow &&
        _lastAnnounced != VoiceAnnouncement.red) {
      if (_lastAnnouncedAtDistance != null &&
          _lastAnnouncedAtDistance! >= 400 &&
          _lastAnnouncedAtDistance! <= 600) {
        // within +-100m of the 500m checkpoint already — skip
        // speaking, just mark this tier as covered
        _lastAnnounced = VoiceAnnouncement.checkpoint500m;
      } else {
        _voiceService.speak(_buildVoiceInstruction(
          VoiceAnnouncement.checkpoint500m,
          direction: _upcomingTurnDirection ?? TurnDirection.forward,
          street: _upcomingTurnStreet,
          distanceMetres: d,
          roundaboutExit: _roundaboutExit,
        ));
        _lastAnnounced = VoiceAnnouncement.checkpoint500m;
        _lastAnnouncedAtDistance = d;
      }
    } else if (prev != null &&
        prev >= 1000 &&
        d < 1000 &&
        _lastAnnounced != VoiceAnnouncement.checkpoint1km &&
        _lastAnnounced != VoiceAnnouncement.checkpoint500m &&
        _lastAnnounced != VoiceAnnouncement.yellow &&
        _lastAnnounced != VoiceAnnouncement.red) {
      if (_lastAnnouncedAtDistance != null &&
          _lastAnnouncedAtDistance! >= 900 &&
          _lastAnnouncedAtDistance! <= 1100) {
        // within +-100m of the 1000m checkpoint already — skip
        // speaking, just mark this tier as covered
        _lastAnnounced = VoiceAnnouncement.checkpoint1km;
      } else {
        _voiceService.speak(_buildVoiceInstruction(
          VoiceAnnouncement.checkpoint1km,
          direction: _upcomingTurnDirection ?? TurnDirection.forward,
          street: _upcomingTurnStreet,
          distanceMetres: d,
          roundaboutExit: _roundaboutExit,
        ));
        _lastAnnounced = VoiceAnnouncement.checkpoint1km;
        _lastAnnouncedAtDistance = d;
      }
    }

    _previousDistanceToNextTurn = d;
  }

  // Fires once per route, the moment the last turn has been passed and
  // there's nothing left but a straight run to the destination pin — a
  // separate, simpler system from the 6-tier turn announcements above,
  // since "you're almost there" isn't a turn tier. Skipped (but still
  // marked fired) when already under 50 m, since a heads-up that close to
  // arrival would just be redundant chatter right after the last turn.
  void _checkFinalLegAnnouncement(double distanceToDestination) {
    if (_finalLegAnnounced) return;
    _finalLegAnnounced = true;
    if (distanceToDestination < 50.0) return;
    if (!voiceGuidanceEnabled) return;

    final distance = distanceToDestination > 1000
        ? _liveDistanceKm(distanceToDestination)
        : _liveDistanceMetres(distanceToDestination);
    _voiceService.speak('In $distance, you will reach your destination');
  }

  // Speaks the arrival line and defers [onSpeechComplete] (the caller's
  // navigate-to-home transition) until the TTS engine reports the utterance
  // actually finished, via VoiceService's completion-handler mechanism —
  // otherwise the screen would navigate away mid-sentence. When voice
  // guidance is muted, there's no utterance to wait for, so the transition
  // runs immediately instead.
  void announceArrival(void Function() onSpeechComplete) {
    if (_arrivalAnnounced) {
      onSpeechComplete();
      return;
    }
    _arrivalAnnounced = true;

    if (!voiceGuidanceEnabled) {
      onSpeechComplete();
      return;
    }
    _voiceService.speak(
      'You have reached your destination',
      onComplete: onSpeechComplete,
    );
  }

  // Direction/action wording shared by every announcement tier.
  String _actionForDirection(TurnDirection? direction, {int? roundaboutExit}) {
    return switch (direction) {
      TurnDirection.forward    => 'Continue straight',
      TurnDirection.left       => 'Turn left',
      TurnDirection.right      => 'Turn right',
      TurnDirection.keepLeft   => 'Keep left',
      TurnDirection.keepRight  => 'Keep right',
      TurnDirection.uTurn      => 'Make a U-turn',
      TurnDirection.roundabout => switch (roundaboutExit) {
          1 => 'At the roundabout, take the first exit',
          2 => 'At the roundabout, take the second exit',
          3 => 'At the roundabout, take the third exit',
          4 => 'At the roundabout, take the fourth exit',
          _ => 'At the roundabout, take exit $roundaboutExit',
        },
      null => 'Continue straight',
    };
  }

  // Metres rounding mirrors DynamicArrowWidget._distanceLabel so voice and
  // the AR overlay never read out different numbers for the same distance.
  String _liveDistanceMetres(double metres) {
    final rounded = ((metres / 10).round() * 10).clamp(10, 990);
    return '$rounded metres';
  }

  String _liveDistanceKm(double metres) {
    final km = metres / 1000;
    final formatted = km >= 10 ? km.round().toString() : km.toStringAsFixed(1);
    return '$formatted kilometres';
  }

  // Single place every spoken string is assembled — tier wording,
  // direction/action mapping, and distance formatting all funnel through
  // here so every call site in _checkVoiceAnnouncement() stays in sync.
  String _buildVoiceInstruction(
    VoiceAnnouncement style, {
    required TurnDirection direction,
    required String? street,
    required double distanceMetres,
    int? roundaboutExit,
  }) {
    final action =
        _actionForDirection(direction, roundaboutExit: roundaboutExit);
    final spokenStreet =
        street != null ? _sanitizeStreetNameForSpeech(street) : null;
    // Omit the "onto <street>" clause entirely when there's no road name,
    // rather than leaving a dangling "onto" or speaking the literal "null".
    final ontoClause = spokenStreet != null ? ' onto $spokenStreet' : '';

    switch (style) {
      case VoiceAnnouncement.farLive:
        final distance = _liveDistanceKm(distanceMetres);
        if (direction == TurnDirection.forward) {
          return 'Continue straight for $distance';
        }
        return 'Continue straight for $distance, then $action$ontoClause';
      case VoiceAnnouncement.midLive:
        return 'In ${_liveDistanceMetres(distanceMetres)}, $action$ontoClause';
      case VoiceAnnouncement.checkpoint1km:
        return 'In 1 kilometre, $action$ontoClause';
      case VoiceAnnouncement.checkpoint500m:
        return 'In 500 metres, $action$ontoClause';
      case VoiceAnnouncement.yellow:
        return 'In ${_liveDistanceMetres(distanceMetres)}, $action';
      case VoiceAnnouncement.red:
        return action;
      case VoiceAnnouncement.none:
        return action;
    }
  }

  // Builds a speech-only copy of the street name — never touches
  // currentStreetName or anything used for on-screen text. Order matters:
  // slash/dash expansion first, then all-caps word spelling, so the inserted
  // "slash"/"dash" words (lowercase) can't be mistaken for section codes.
  String _sanitizeStreetNameForSpeech(String name) {
    var spoken = name.replaceAll('/', ' slash ');
    spoken = spoken.replaceAll('-', ' dash ');
    spoken = spoken.replaceAllMapped(
      RegExp(r'\b[A-Z]{2,4}\b'),
      (match) => match.group(0)!.split('').join(' '),
    );
    return spoken;
  }
}
